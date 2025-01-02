import FirebaseFirestore
import FirebaseCore
import FirebaseAuth
import Combine
import GoogleSignIn
import AuthenticationServices
import CryptoKit
import Foundation
import FirebaseFunctions

// Önce protokolü tanımlayalım
protocol DatabaseService {
    // Auth
    func signIn(email: String, password: String) async throws -> User
    func signUp(email: String, password: String, name: String) async throws -> User
    func signOut() throws
    
    // Transactions
    func getTransactions() async throws -> [Transaction]
    func addTransaction(_ transaction: Transaction) async throws
    func deleteTransaction(_ transaction: Transaction) async throws
    func addTransactionListener(completion: @escaping ([Transaction]) -> Void) -> ListenerRegistration
    
    // Budget
    func setBudget(amount: Double, categoryLimits: [CategoryBudget]) async throws
    func getCurrentBudget() async throws -> Budget?
    func deleteBudget(_ budget: Budget) async throws
    func updateBudget(_ budget: Budget, amount: Double, categoryLimits: [CategoryBudget]) async throws
    func addBudgetListener(completion: @escaping (Budget?) -> Void) -> ListenerRegistration
}

// Mevcut servisi protokole uygun hale getirelim
class FirebaseService: DatabaseService {
    static let shared = FirebaseService()
    private let db = Firestore.firestore()
    private let networkMonitor = NetworkMonitor.shared
    
    private init() {}
    
    // MARK: - Error Handling
    private func checkConnection() throws {
        guard networkMonitor.isConnected else {
            throw NetworkError.noConnection
        }
    }
    
    private func withRetry<T>(maxAttempts: Int = 3, operation: () async throws -> T) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...maxAttempts {
            do {
                try checkConnection()  // Her denemede bağlantıyı kontrol et
                return try await operation()
            } catch {
                lastError = error
                if attempt < maxAttempts {
                    try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt)) * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? NetworkError.unknown
    }
    
    // MARK: - Auth İşlemleri
    func signIn(email: String, password: String) async throws -> User {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        return result.user
    }
    
    func signUp(email: String, password: String, name: String) async throws -> User {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        
        // Kullanıcı profilini güncelle
        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = name
        try await changeRequest.commitChanges()
        
        // Firestore'a kullanıcı dokümanı ekle
        try await db.collection("users").document(result.user.uid).setData([
            "name": name,
            "email": email,
            "createdAt": FieldValue.serverTimestamp()
        ])
        
        return result.user
    }
    
    func signOut() throws {
        do {
            try Auth.auth().signOut()
        } catch {
            throw NetworkError.serverError("Çıkış yapılırken bir hata oluştu: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Transaction İşlemleri
    func getTransactions() async throws -> [Transaction] {
        try checkConnection()
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NetworkError.authenticationError
        }
        
        let snapshot = try await db.collection("transactions")
            .whereField("userId", isEqualTo: userId)
            .order(by: "date", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try document.data(as: Transaction.self)
        }
    }
    
    func addTransaction(_ transaction: Transaction) async throws {
        print("Adding transaction:")
        print("Amount: \(transaction.amount)")
        print("Category: \(transaction.category.rawValue)")
        print("Type: \(transaction.type.rawValue)")
        
        try checkConnection()
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NetworkError.authenticationError
        }
        
        var transaction = transaction
        if transaction.id == nil {
            transaction.id = UUID().uuidString
        }
        
        let data = transaction.asDictionary()
        print("Transaction data:")
        print(data)
        
        do {
            try await db.collection("transactions")
                .document(transaction.id!)
                .setData(data)
            print("✅ Transaction added successfully")
            
            print("Updating budget...")
            try await updateBudgetSpending(for: transaction)
        } catch {
            print("❌ Failed to add transaction or update budget: \(error.localizedDescription)")
            throw error
        }
    }
    
    func deleteTransaction(_ transaction: Transaction) async throws {
        guard let id = transaction.id else {
            throw NetworkError.invalidData
        }
        
        try await db.collection("transactions").document(id).delete()
        
        // Listener'ı tetiklemek için kısa bir bekleme
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 saniye
    }
    
    // MARK: - Dinleyiciler
    func addTransactionListener(completion: @escaping ([Transaction]) -> Void) -> ListenerRegistration {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion([])
            return db.collection("transactions").addSnapshotListener { _, _ in }
        }
        
        return db.collection("transactions")
            .whereField("userId", isEqualTo: userId)
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching documents: \(error?.localizedDescription ?? "Unknown error")")
                    completion([])
                    return
                }
                
                do {
                    let transactions = try documents.compactMap { document -> Transaction? in
                        let data = document.data()
                        
                        // Tarihleri düzgün parse et
                        let timestamp = data["date"] as? Timestamp
                        let date = timestamp?.dateValue() ?? Date()
                        
                        let createdTimestamp = data["createdAt"] as? Timestamp
                        let createdAt = createdTimestamp?.dateValue()
                        
                        // Transaction oluştur
                        return Transaction(
                            id: document.documentID,
                            userId: data["userId"] as? String ?? "",
                            amount: data["amount"] as? Double ?? 0,
                            category: Category(rawValue: data["category"] as? String ?? "") ?? .diger,
                            type: TransactionType(rawValue: data["type"] as? String ?? "") ?? .expense,
                            date: date,
                            note: data["note"] as? String,
                            createdAt: createdAt
                        )
                    }
                    
                    completion(transactions)
                } catch {
                    print("Error decoding transactions: \(error)")
                    completion([])
                }
            }
    }
    
    // MARK: - Budget Operations
    func setBudget(amount: Double, categoryLimits: [CategoryBudget]) async throws {
        try checkConnection()
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NetworkError.authenticationError
        }
        
        let currentMonth = Date().startOfMonth()
        let documentId = "\(userId)_\(currentMonth.timeIntervalSince1970)"
        
        let data: [String: Any] = [
            "id": documentId,
            "userId": userId,
            "amount": amount,
            "month": currentMonth,
            "categoryLimits": categoryLimits.map { [
                "id": $0.id,
                "category": $0.category.rawValue,
                "limit": $0.limit,
                "spent": $0.spent
            ] },
            "createdAt": FieldValue.serverTimestamp(),
            "notificationsEnabled": true,
            "warningThreshold": 0.7,
            "dangerThreshold": 0.9
        ]
        
        try await db.collection("budgets").document(documentId).setData(data)
    }
    
    func addBudgetListener(completion: @escaping (Budget?) -> Void) -> ListenerRegistration {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(nil)
            return db.collection("budgets").addSnapshotListener { _, _ in }
        }
        
        let currentMonth = Date().startOfMonth()
        let documentId = "\(userId)_\(currentMonth.timeIntervalSince1970)"
        
        return db.collection("budgets")
            .document(documentId)
            .addSnapshotListener { snapshot, error in
                guard let document = snapshot else {
                    print("Error fetching budget: \(error?.localizedDescription ?? "Unknown error")")
                    completion(nil)
                    return
                }
                
                do {
                    if document.exists {
                        let budget = try document.data(as: Budget.self)
                        completion(budget)
                    } else {
                        completion(nil)
                    }
                } catch {
                    print("Error decoding budget: \(error)")
                    completion(nil)
                }
            }
    }
    
    func getCurrentBudget() async throws -> Budget? {
        try checkConnection()
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NetworkError.authenticationError
        }
        
        let currentMonth = Date().startOfMonth()
        let snapshot = try await db.collection("budgets")
            .whereField("userId", isEqualTo: userId)
            .whereField("month", isEqualTo: currentMonth)
            .getDocuments()
        
        return try snapshot.documents.first?.data(as: Budget.self)
    }
    
    func deleteBudget(_ budget: Budget) async throws {
        try checkConnection()
        try await db.collection("budgets").document(budget.documentId).delete()
    }
    
    func updateBudget(_ budget: Budget, amount: Double, categoryLimits: [CategoryBudget]) async throws {
        try checkConnection()
        
        let data: [String: Any] = [
            "amount": amount,
            "categoryLimits": categoryLimits.map { [
                "id": $0.id,
                "category": $0.category.rawValue,
                "limit": $0.limit,
                "spent": 0
            ] }
        ]
        
        try await db.collection("budgets").document(budget.documentId).updateData(data)
    }
    
    // MARK: - Recurring Transactions
    func addRecurringTransaction(_ transaction: RecurringTransaction) async throws {
        try await withRetry(maxAttempts: 3) {
            try checkConnection()
            let ref = db.collection("recurring_transactions").document()
            try await ref.setData(transaction.asDictionary())
        }
    }
    
    func deleteRecurringTransaction(_ transaction: RecurringTransaction) async throws {
        guard let id = transaction.id else {
            throw NetworkError.invalidData
        }
        try await db.collection("recurring_transactions").document(id).delete()
    }
    
    func getRecurringTransactions() async throws -> [RecurringTransaction] {
        try checkConnection()
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NetworkError.authenticationError
        }
        
        let snapshot = try await db.collection("recurring_transactions")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try document.data(as: RecurringTransaction.self)
        }
    }
    
    func addRecurringTransactionListener(completion: @escaping ([RecurringTransaction]) -> Void) -> ListenerRegistration {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion([])
            return db.collection("recurring_transactions").addSnapshotListener { _, _ in }
        }
        
        return db.collection("recurring_transactions")
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching documents: \(error?.localizedDescription ?? "Unknown error")")
                    completion([])
                    return
                }
                
                do {
                    let transactions = try documents.compactMap { document -> RecurringTransaction? in
                        var transaction = try document.data(as: RecurringTransaction.self)
                        transaction.id = document.documentID
                        return transaction
                    }
                    completion(transactions)
                } catch {
                    print("Error decoding recurring transactions: \(error)")
                    completion([])
                }
            }
    }
    
    func processRecurringTransactions() async throws {
        let transactions = try await getRecurringTransactions()
        let now = Date()
        
        for transaction in transactions {
            guard let lastProcessed = transaction.lastProcessed else {
                // İlk kez işlenecek
                try await processTransaction(transaction)
                continue
            }
            
            let nextDate = Calendar.current.date(
                byAdding: transaction.frequency.calendarComponent,
                value: 1,
                to: lastProcessed
            ) ?? now
            
            if nextDate <= now {
                try await processTransaction(transaction)
            }
        }
    }
    
    private func processTransaction(_ recurring: RecurringTransaction) async throws {
        // Normal işlem oluştur
        let transaction = Transaction(
            userId: recurring.userId,
            amount: recurring.amount,
            category: recurring.category,
            type: recurring.type,
            date: Date(),
            note: recurring.note,
            createdAt: Date()
        )
        
        // İşlemi kaydet
        try await addTransaction(transaction)
        
        // Son işlem tarihini güncelle
        try await db.collection("recurring_transactions")
            .document(recurring.documentId)
            .updateData([
                "lastProcessed": FieldValue.serverTimestamp()
            ])
    }
    
    // MARK: - Financial Goals
    func addFinancialGoal(_ goal: FinancialGoal) async throws {
        try await withRetry(maxAttempts: 3) {
            try checkConnection()
            let ref = db.collection("financial_goals").document()
            try await ref.setData(goal.asDictionary())
        }
    }
    
    func updateFinancialGoal(_ goal: FinancialGoal) async throws {
        try checkConnection()
        guard let id = goal.id else { throw NetworkError.invalidData }
        try await db.collection("financial_goals").document(id).updateData(goal.asDictionary())
    }
    
    func deleteFinancialGoal(_ goal: FinancialGoal) async throws {
        try checkConnection()
        try await db.collection("financial_goals").document(goal.documentId).delete()
    }
    
    func getFinancialGoals() async throws -> [FinancialGoal] {
        try checkConnection()
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NetworkError.authenticationError
        }
        
        let snapshot = try await db.collection("financial_goals")
            .whereField("userId", isEqualTo: userId)
            .order(by: "deadline")
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try document.data(as: FinancialGoal.self)
        }
    }
    
    func addFinancialGoalListener(completion: @escaping ([FinancialGoal]) -> Void) -> ListenerRegistration {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion([])
            return db.collection("financial_goals").addSnapshotListener { _, _ in }
        }
        
        return db.collection("financial_goals")
            .whereField("userId", isEqualTo: userId)
            .order(by: "deadline")
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching goals: \(error?.localizedDescription ?? "Unknown error")")
                    completion([])
                    return
                }
                
                do {
                    let goals = try documents.compactMap { document -> FinancialGoal? in
                        var goal = try document.data(as: FinancialGoal.self)
                        goal.id = document.documentID
                        return goal
                    }
                    completion(goals)
                } catch {
                    print("Error decoding goals: \(error)")
                    completion([])
                }
            }
    }
    
    func updateGoalProgress(_ goal: FinancialGoal, amount: Double) async throws {
        try checkConnection()
        
        let data: [String: Any] = [
            "currentAmount": amount
        ]
        
        try await db.collection("financial_goals")
            .document(goal.documentId)
            .updateData(data)
    }
    
    // MARK: - Monthly Reset Operations
    func checkAndResetMonthlyBudget() async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NetworkError.authenticationError
        }
        
        let currentMonth = Date().startOfMonth()
        let documentId = "\(userId)_\(currentMonth.timeIntervalSince1970)"
        
        // Mevcut ayın bütçesini kontrol et
        if let currentBudget = try await getCurrentBudget() {
            // Eğer bu ay için bütçe varsa, işlem yapma
            return
        }
        
        // Önceki ayın bütçesini al
        let previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        let previousDocumentId = "\(userId)_\(previousMonth.timeIntervalSince1970)"
        
        let previousBudget = try await db.collection("budgets")
            .document(previousDocumentId)
            .getDocument(as: Budget.self)
        
        // Yeni ay için bütçe oluştur
        let newBudget = Budget(
            id: documentId,
            userId: userId,
            amount: previousBudget.amount,
			categoryLimits: previousBudget.categoryLimits.map { category in
				CategoryBudget(
					id: UUID().uuidString,
					category: category.category,
					limit: category.limit,
					spent: 0  // Harcamaları sıfırla
				)
			},
			month: currentMonth,
            createdAt: Date(),
            warningThreshold: previousBudget.warningThreshold,
            dangerThreshold: previousBudget.dangerThreshold,
            notificationsEnabled: previousBudget.notificationsEnabled,
            spentAmount: 0  // Toplam harcamayı sıfırla
        )
        
        // Yeni bütçeyi kaydet
        try await db.collection("budgets")
            .document(documentId)
            .setData(newBudget.asDictionary())
    }
    
    // Geçmiş bütçeleri getir
    func getPastBudgets(limit: Int = 12) async throws -> [Budget] {
        try checkConnection()
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NetworkError.authenticationError
        }
        
        let currentMonth = Date().startOfMonth()
        
        let snapshot = try await db.collection("budgets")
            .whereField("userId", isEqualTo: userId)
            .whereField("month", isLessThan: currentMonth)
            .order(by: "month", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try document.data(as: Budget.self)
        }
    }
    
    // Geçmiş bütçeleri dinle
    func addPastBudgetsListener(completion: @escaping ([Budget]) -> Void) -> ListenerRegistration {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion([])
            return db.collection("budgets").addSnapshotListener { _, _ in }
        }
        
        let currentMonth = Date().startOfMonth()
        
        return db.collection("budgets")
            .whereField("userId", isEqualTo: userId)
            .whereField("month", isLessThan: currentMonth)
            .order(by: "month", descending: true)
            .limit(to: 12)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching past budgets: \(error?.localizedDescription ?? "Unknown error")")
                    completion([])
                    return
                }
                
                do {
                    let budgets = try documents.compactMap { document in
                        try document.data(as: Budget.self)
                    }
                    completion(budgets)
                } catch {
                    print("Error decoding past budgets: \(error)")
                    completion([])
                }
            }
    }
    
    // Bütçe harcamalarını güncelle
    func updateBudgetSpending(for transaction: Transaction) async throws {
        try checkConnection()
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NetworkError.authenticationError
        }
        
        let currentMonth = transaction.date.startOfMonth()
        let documentId = "\(userId)_\(currentMonth.timeIntervalSince1970)"
        
        print("🔄 Updating budget for transaction: \(transaction.amount) - \(transaction.category.rawValue)")
        
        // Mevcut bütçeyi al
        let budgetDoc = try await db.collection("budgets")
            .document(documentId)
            .getDocument()
        
        guard var budget = try? budgetDoc.data(as: Budget.self) else {
            print("❌ No budget found for document ID: \(documentId)")
            return
        }
        
        print("📊 Current budget state before update:")
        print("Total spent: \(budget.spentAmount)")
        print("Category limits: \(budget.categoryLimits.map { "\($0.category.rawValue): \($0.spent)/\($0.limit)" })")
        
        // Sadece gider işlemleri için güncelleme yap
        if transaction.type == .expense {
            // Kategori limitini güncelle
            if let index = budget.categoryLimits.firstIndex(where: { $0.category == transaction.category }) {
                budget.categoryLimits[index].spent += transaction.amount
                budget.spentAmount += transaction.amount
                
                print("✅ Updated category \(transaction.category.rawValue):")
                print("New spent amount: \(budget.categoryLimits[index].spent)")
                print("New total spent: \(budget.spentAmount)")
                
                // Firestore'u güncelle
                let updateData: [String: Any] = [
                    "spentAmount": budget.spentAmount,
                    "categoryLimits": budget.categoryLimits.map { [
                        "id": $0.id,
                        "category": $0.category.rawValue,
                        "limit": $0.limit,
                        "spent": $0.spent
                    ] }
                ]
                
                try await db.collection("budgets")
                    .document(documentId)
                    .updateData(updateData)
                
                print("✅ Budget successfully updated in Firestore")
            } else {
                print("❌ Category not found in budget: \(transaction.category.rawValue)")
            }
        } else {
            print("ℹ️ Skipping update for non-expense transaction")
        }
    }
    
    // MARK: - Google Sign In
    func signInWithGoogle() async throws -> User {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw NetworkError.serverError("Firebase yapılandırması eksik")
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            throw NetworkError.serverError("Uygulama penceresi bulunamadı")
        }
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            guard let idToken = result.user.idToken?.tokenString else {
                throw NetworkError.serverError("Google token alınamadı")
            }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            
            let authResult = try await Auth.auth().signIn(with: credential)
            return authResult.user
            
        } catch {
            throw NetworkError.serverError("Google girişi başarısız: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Apple Sign In
    private var currentNonce: String?
    
    func handleSignInWithApple(_ result: Swift.Result<ASAuthorization, Error>) async throws -> User {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let nonce = currentNonce,
                  let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                throw NetworkError.serverError("Apple kimlik bilgileri alınamadı")
            }
            
            let credential = OAuthProvider.credential(
                withProviderID: "apple.com",
                idToken: idTokenString,
                rawNonce: nonce
            )
            
            let authResult = try await Auth.auth().signIn(with: credential)
            
            // Kullanıcı ilk kez giriş yapıyorsa adını kaydet
            if let fullName = appleIDCredential.fullName {
                let displayName = PersonNameComponentsFormatter().string(from: fullName)
                // Firestore'a kullanıcı bilgilerini kaydet
                try await db.collection("users").document(authResult.user.uid).setData([
                    "name": displayName,
                    "email": authResult.user.email ?? "",
                    "createdAt": FieldValue.serverTimestamp()
                ])
            }
            
            return authResult.user
            
        case .failure(let error):
            throw NetworkError.serverError("Apple girişi başarısız: \(error.localizedDescription)")
        }
    }
    
    // Apple Sign In için yardımcı metodlar
    func startSignInWithAppleFlow() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return nonce
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    public func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    func updateBudget(_ budget: Budget) async throws {
        try checkConnection()
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NetworkError.authenticationError
        }
        
        
       
        
        let data = budget.asDictionary()
        
        do {
            try await db.collection("budgets")
                .document(budget.documentId)
                .updateData(data)
        } catch {
            throw error
        }
    }
    
    
    // Aile bütçesi dinleyicisi
    func addFamilyBudgetListener(completion: @escaping (FamilyBudget?) -> Void) -> ListenerRegistration {
        guard let userEmail = Auth.auth().currentUser?.email else {
            print("No user email found")
            completion(nil)
            return db.collection("familyBudgets").addSnapshotListener { _, _ in }
        }
        
        print("Setting up listener for email: \(userEmail)")
        
        // Hem admin hem de üye olarak eklenmiş bütçeleri dinle
        return db.collection("familyBudgets")
            .whereField("memberEmails", arrayContains: userEmail) // Yeni alan kullan
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching family budget: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                print("Raw snapshot data:")
                snapshot?.documents.forEach { doc in
                    print(doc.data())
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found")
                    completion(nil)
                    return
                }
                
                if let document = documents.first {
                    do {
                        var budget = try document.data(as: FamilyBudget.self)
                        budget.id = document.documentID
                        print("Successfully decoded budget: \(budget.name)")
                        completion(budget)
                    } catch {
                        print("Error decoding family budget: \(error)")
                        completion(nil)
                    }
                } else {
                    print("No matching budget found")
                    completion(nil)
                }
            }
    }
    
    // Aile bütçesi oluştur
    func createFamilyBudget(_ budget: FamilyBudget) async throws {
        try checkConnection()
        
        var updatedBudget = budget
        if let currentUserEmail = Auth.auth().currentUser?.email {
            print("Creating budget with current user: \(currentUserEmail)")
            print("Invited members: \(budget.members.map { $0.email })")
            
            // Admin olarak mevcut kullanıcıyı ekle
            let currentUser = FamilyBudget.FamilyMember(
                id: Auth.auth().currentUser?.uid ?? UUID().uuidString,
                name: Auth.auth().currentUser?.displayName ?? "",
                email: currentUserEmail,
                role: .admin,
                spentAmount: 0
            )
            
            // Davet edilen üyeleri member rolüyle ekle
            let invitedMembers = budget.members.map { member in
                print("Processing invited member: \(member.email)")
                return FamilyBudget.FamilyMember(
                    id: UUID().uuidString,
                    name: "",
                    email: member.email,
                    role: .member,
                    spentAmount: 0
                )
            }
            
            // Tüm üyeleri birleştir
            updatedBudget.members = [currentUser] + invitedMembers
            print("Total members after update: \(updatedBudget.members.count)")
            
            // Tüm email'leri array'e ekle
            let allEmails = updatedBudget.members.map { $0.email }
            print("All member emails: \(allEmails)")
            
            var data = updatedBudget.asDictionary()
            data["memberEmails"] = allEmails
            
            do {
                // Bütçeyi oluştur
                try await db.collection("familyBudgets")
                    .document(updatedBudget.documentId)
                    .setData(data)
                
                print("Budget created, sending invitations...")
                
                // Davetleri gönder
                for member in updatedBudget.members where member.role == .member {
                    print("Sending invitation to: \(member.email)")
                    try await sendBudgetInvitation(
                        to: member.email,
                        budgetId: updatedBudget.documentId,
                        budgetName: updatedBudget.name
                    )
                }
                
                print("Family budget created successfully")
                print("Budget ID: \(updatedBudget.documentId)")
                print("Members: \(updatedBudget.members.map { $0.email })")
                print("Member count: \(updatedBudget.members.count)")
                
            } catch {
                print("Error creating family budget: \(error.localizedDescription)")
                throw error
            }
        }
    }
    
    // Aile bütçesine üye davet et
    func sendBudgetInvitation(to email: String, budgetId: String, budgetName: String) async throws {
        print("Sending invitation to: \(email) for budget: \(budgetName)")
        
        let data: [String: Any] = [
            "email": email,
            "budgetId": budgetId,
            "budgetName": budgetName,
            "invitedBy": Auth.auth().currentUser?.email ?? "",
            "createdAt": FieldValue.serverTimestamp(),
            "status": "pending"  // Yeni alan
        ]
        
        do {
            let ref = try await db.collection("budgetInvitations").addDocument(data: data)
            print("Invitation created with ID: \(ref.documentID)")
            
            // Burada email gönderme servisi entegre edilebilir
            // Örnek: await EmailService.sendInvitation(to: email, budgetName: budgetName)
            
        } catch {
            print("Error sending invitation: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Aile bütçesine işlem ekle
	
	func addFamilyTransaction(_ familyTransaction: Transaction, toBudget budget: FamilyBudget) async throws {
		let budgetRef = db.collection("familyBudgets").document(budget.documentId)
		
		try await db.runTransaction { transaction, errorPointer in
			do {
				let budgetDoc = try transaction.getDocument(budgetRef)
				guard var updatedBudget = try? budgetDoc.data(as: FamilyBudget.self) else {
					throw NetworkError.invalidData
				}
				
				// Toplam harcamayı güncelle
				if familyTransaction.type == .expense {
					updatedBudget.spentAmount += familyTransaction.amount
					
					// Üyenin harcamasını güncelle
					if let index = updatedBudget.members.firstIndex(where: { $0.email == Auth.auth().currentUser?.email }) {
						updatedBudget.members[index].spentAmount += familyTransaction.amount
					}
					
					// Kategori limitini güncelle
					if let index = updatedBudget.categoryLimits.firstIndex(where: { $0.category == familyTransaction.category }) {
						updatedBudget.categoryLimits[index].spent += familyTransaction.amount
					}
				}
				
				let data = updatedBudget.asDictionary()
				transaction.setData(data, forDocument: budgetRef)
				return nil
				
			} catch {
				errorPointer?.pointee = error as NSError
				return nil
			}
		}
	}
    
    // Aile bütçesini güncelle
    func updateFamilyBudget(_ budget: FamilyBudget) async throws {
        guard let budgetId = budget.id else {
            throw NetworkError.invalidData
        }
        
        var data = budget.asDictionary()
        data["memberEmails"] = budget.members.map { $0.email }
        
        try await db.collection("familyBudgets")
            .document(budgetId)
            .setData(data)
    }
    
    // Aile bütçesini sil
    func deleteFamilyBudget(_ budget: FamilyBudget) async throws {
        guard let budgetId = budget.id else {
            throw NetworkError.invalidData
        }
        
        print("Starting to delete budget: \(budgetId)")
        
        do {
            // Önce işlemleri sil
            let transactionsSnapshot = try await db.collection("familyBudgets")
                .document(budgetId)
                .collection("transactions")
                .getDocuments()
            
            for doc in transactionsSnapshot.documents {
                try await doc.reference.delete()
            }
            
            print("Deleted \(transactionsSnapshot.documents.count) transactions")
            
            // Sonra davetleri sil
            let invitationsSnapshot = try await db.collection("budgetInvitations")
                .whereField("budgetId", isEqualTo: budgetId)
                .getDocuments()
            
            for doc in invitationsSnapshot.documents {
                try await doc.reference.delete()
            }
            
            print("Deleted \(invitationsSnapshot.documents.count) invitations")
            
            // En son bütçeyi sil
            try await db.collection("familyBudgets")
                .document(budgetId)
                .delete()
            
            print("Budget deleted successfully")
            
        } catch {
            print("Error deleting budget: \(error.localizedDescription)")
            throw error
        }
    }
}

// Tek bir listener yönetimi için helper class ekleyelim
class ListenerManager {
    private var listeners: [String: ListenerRegistration] = [:]
    
    func add(_ listener: ListenerRegistration, for key: String) {
        remove(for: key)  // Önceki listener'ı temizle
        listeners[key] = listener
    }
    
    func remove(for key: String) {
        listeners[key]?.remove()
        listeners[key] = nil
    }
    
    func removeAll() {
        listeners.values.forEach { $0.remove() }
        listeners.removeAll()
    }
}

extension FirebaseService {
    // Aile bütçesine işlem ekle
    func addFamilyTransaction(_ transaction: FamilyTransaction, toBudget budget: FamilyBudget) async throws {
        guard let budgetId = budget.id else {
            throw NetworkError.invalidData
        }
        
        // İşlemi kaydet
        let transactionRef = db.collection("familyBudgets")
            .document(budgetId)
            .collection("transactions")
            .document(transaction.documentId)
        
        try await transactionRef.setData(transaction.asDictionary())
        
        print("Family transaction added successfully")
        print("Transaction amount: \(transaction.amount)")
        print("Transaction category: \(transaction.category.rawValue)")
    }
}

