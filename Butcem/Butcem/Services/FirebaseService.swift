import FirebaseFirestore
import FirebaseCore
import FirebaseAuth
import Combine
import AuthenticationServices
import CryptoKit
import Foundation
import FirebaseFunctions

// Önce protokolü tanımlayalım
protocol DatabaseService {
	
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
	let db: Firestore
	private let networkMonitor = NetworkMonitor.shared
	
	private init() {
		db = Firestore.firestore()
	}
	
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
	
	
	
	// MARK: - Transaction İşlemleri
	func getTransactions() async throws -> [Transaction] {
		let userId = AuthManager.shared.currentUserId
		try checkConnection()
		
		let snapshot = try await db.collection("transactions")
			.whereField("userId", isEqualTo: userId)
			.order(by: "date", descending: true)
			.getDocuments()
		
		let transactions = try snapshot.documents.compactMap { document in
			var transaction = try document.data(as: Transaction.self)
			transaction.id = document.documentID
			return transaction
		}
		
		print("Retrieved \(transactions.count) transactions")
		return transactions
	}
	
	func addTransaction(_ transaction: Transaction) async throws {
		try checkConnection()
		let userId = AuthManager.shared.currentUserId
		var transaction = transaction
		transaction.userId = userId
		
		if transaction.id == nil {
			transaction.id = UUID().uuidString
		}
		
		let data = transaction.asDictionary()
		
		do {
			try await db.collection("transactions")
				.document(transaction.id!)
				.setData(data)
			
			try await updateBudgetSpending(for: transaction)
		} catch {
			throw error
		}
	}
	
	func deleteTransaction(_ transaction: Transaction) async throws {
		try await db.collection("transactions")
			.document(transaction.documentId)
			.delete()
		
	}
	
	// MARK: - Dinleyiciler
	func addTransactionListener(completion: @escaping ([Transaction]) -> Void) -> ListenerRegistration {
		let userId = AuthManager.shared.currentUserId
		
		return db.collection("transactions")
			.whereField("userId", isEqualTo: userId)
			.order(by: "date", descending: true)
			.addSnapshotListener { snapshot, error in
				guard let documents = snapshot?.documents else {
					print("Error fetching transactions: \(error?.localizedDescription ?? "Unknown error")")
					return
				}
				
				let transactions = documents.compactMap { document -> Transaction? in
					do {
						var transaction = try document.data(as: Transaction.self)
						transaction.id = document.documentID
						return transaction
					} catch {
						print("Error decoding transaction: \(error)")
						return nil
					}
				}
				
				completion(transactions)
			}
	}
	
	// MARK: - Budget Operations
	func setBudget(amount: Double, categoryLimits: [CategoryBudget]) async throws {
		let userId = AuthManager.shared.currentUserId
		print("🔄 Setting budget for user: \(userId)")
		
		let budget = Budget(
			userId: userId,
			amount: amount,
			categoryLimits: categoryLimits,
			month: Date().startOfMonth()
		)
		
		do {
			try await db.collection("budgets")
				.document(userId)
				.setData(budget.asDictionary())
			
			print("✅ Budget set successfully: \(amount)")
			
			// Kısa bir gecikme ekle
			try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 saniye
			
			// Listener'ı tetiklemek için bir güncelleme yap
			try await db.collection("budgets")
				.document(userId)
				.updateData([
					"lastUpdated": FieldValue.serverTimestamp()
				])
			
			print("✅ Budget listener triggered")
		} catch {
			print("❌ Error setting budget: \(error.localizedDescription)")
			throw error
		}
	}
	
	func addBudgetListener(completion: @escaping (Budget?) -> Void) -> ListenerRegistration {
		let userId = AuthManager.shared.currentUserId
		
		return db.collection("budgets")
			.document(userId)
			.addSnapshotListener { documentSnapshot, error in
				guard let document = documentSnapshot else {
					print("Error fetching budget: \(error?.localizedDescription ?? "Unknown error")")
					completion(nil)
					return
				}
				
				print("Snapshot listener triggered!") // Bu tetikleniyor mu?
				
				guard document.exists else {
					print("Document does not exist")
					completion(nil)
					return
				}
				
				do {
					let budget = try document.data(as: Budget.self)
					print("Decoded budget: \(budget)")
					completion(budget)
				} catch {
					print("Error decoding budget: \(error)")
					completion(nil)
				}
			}
	}
	
	func getCurrentBudget() async throws -> Budget? {
		try checkConnection()
		let userId = AuthManager.shared.currentUserId
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
	
	func addRecurringTransaction(_ transaction: RecurringTransaction) async throws {
		try await withRetry(maxAttempts: 3) {
			try checkConnection()
			let ref = db.collection("recurring_transactions").document()
			try await ref.setData(transaction.asDictionary())
		}
	}
	
	func deleteRecurringTransaction(_ transaction: RecurringTransaction) async throws {
		guard let id = transaction.id else {
			throw NetworkError.invalidData("TransactionId is missing")
		}
		try await db.collection("recurring_transactions").document(id).delete()
	}
	
	func getRecurringTransactions() async throws -> [RecurringTransaction] {
		try checkConnection()
		let userId = AuthManager.shared.currentUserId

		
		let snapshot = try await db.collection("recurring_transactions")
			.whereField("userId", isEqualTo: userId)
			.getDocuments()
		
		return try snapshot.documents.compactMap { document in
			try document.data(as: RecurringTransaction.self)
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
		guard let id = goal.id else { throw NetworkError.invalidData("Bir takım sorunlar oluştu") }
		try await db.collection("financial_goals").document(id).updateData(goal.asDictionary())
	}
	
	func deleteFinancialGoal(_ goal: FinancialGoal) async throws {
		try checkConnection()
		try await db.collection("financial_goals").document(goal.documentId).delete()
	}
	
	func getFinancialGoals() async throws -> [FinancialGoal] {
		try checkConnection()
		let userId = AuthManager.shared.currentUserId

		
		let snapshot = try await db.collection("financial_goals")
			.whereField("userId", isEqualTo: userId)
			.order(by: "deadline")
			.getDocuments()
		
		return try snapshot.documents.compactMap { document in
			try document.data(as: FinancialGoal.self)
		}
	}
	
	func addFinancialGoalListener(completion: @escaping ([FinancialGoal]) -> Void) -> ListenerRegistration {
		 let userId = AuthManager.shared.currentUserId

		
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
		let userId = AuthManager.shared.currentUserId

		
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
		let userId = AuthManager.shared.currentUserId

		
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
		 let userId = AuthManager.shared.currentUserId

		
		let currentMonth = Date().startOfMonth()
		
		return db.collection("budgets")
			.whereField("userId", isEqualTo: userId)
			.whereField("month", isLessThan: currentMonth)
			.order(by: "month", descending: true)
			.limit(to: 12)
			.addSnapshotListener { snapshot, error in
				guard let documents = snapshot?.documents else {
					completion([])
					return
				}
				
				do {
					let budgets = try documents.compactMap { document in
						try document.data(as: Budget.self)
					}
					completion(budgets)
				} catch {
					completion([])
				}
			}
	}
	
	// Bütçe harcamalarını güncelle
	func updateBudgetSpending(for transaction: Transaction) async throws {
		try checkConnection()
		let userId = AuthManager.shared.currentUserId

		
		let currentMonth = transaction.date.startOfMonth()
		let documentId = "\(userId)_\(currentMonth.timeIntervalSince1970)"
		
		
		// Mevcut bütçeyi al
		let budgetDoc = try await db.collection("budgets")
			.document(documentId)
			.getDocument()
		
		guard var budget = try? budgetDoc.data(as: Budget.self) else {
			return
		}
		
		
		// Sadece gider işlemleri için güncelleme yap
		if transaction.type == .expense {
			// Kategori limitini güncelle
			if let index = budget.categoryLimits.firstIndex(where: { $0.category == transaction.category }) {
				budget.categoryLimits[index].spent += transaction.amount
				budget.spentAmount += transaction.amount
				
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
				
			} else {
			}
		} else {
		}
	}
	
	// MARK: - Google Sign In
	
	// MARK: - Apple Sign In
	private var currentNonce: String?
	
	
	// Apple Sign In için yardımcı metodlar
	
	
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
		let userId = AuthManager.shared.currentUserId

		
		
		
		
		let data = budget.asDictionary()
		
		do {
			try await db.collection("budgets")
				.document(budget.documentId)
				.updateData(data)
		} catch {
			throw error
		}
	}
	

	
	// Aile bütçesi işlemleri
	func createFamilyBudget(_ budget: FamilyBudget) async throws {
		try checkConnection()
		
		let docRef = db.collection("familyBudgets").document()
		var budgetData = budget.asDictionary()
		budgetData["id"] = docRef.documentID  // Döküman ID'sini ekle
		
		try await docRef.setData(budgetData)
		print("Bütçe oluşturuldu: \(docRef.documentID)")
	}
	
	func updateFamilyBudget(_ budget: FamilyBudget) async throws {
		try checkConnection()
		guard let id = budget.id else {
			throw NetworkError.invalidData("Bütçe ID'si bulunamadı")
		}
		
		try await db.collection("familyBudgets")
			.document(id)
			.setData(budget.asDictionary(), merge: true)
	}
	
	func deleteFamilyBudget(_ budget: FamilyBudget) async throws {
		try checkConnection()
		try await db.collection("familyBudgets")
			.document(budget.documentId)
			.delete()
	}
	
	func getFamilyBudget(id: String) async throws -> FamilyBudget? {
		try checkConnection()
		let doc = try await db.collection("familyBudgets")
			.document(id)
			.getDocument()
		
		guard doc.exists else { return nil }
		
		var budget = try doc.data(as: FamilyBudget.self)
		budget.id = doc.documentID  // Döküman ID'sini set et
		return budget
	}
	
	// Aile bütçesi dinleyicisi
	func addFamilyBudgetListener(completion: @escaping (FamilyBudget?) -> Void) -> ListenerRegistration {
		let userId = AuthManager.shared.currentUserId
		print("Starting budget listener for user: \(userId)")
		
		// Önce tüm bütçeleri al ve debug için yazdır
		let listener = db.collection("familyBudgets")
			.addSnapshotListener { snapshot, error in
				if let error = error {
					print("❌ Error fetching family budget: \(error.localizedDescription)")
					completion(nil)
					return
				}
				
				print("📝 Total budgets in database: \(snapshot?.documents.count ?? 0)")
				
				// Tüm bütçeleri kontrol et
				for document in snapshot?.documents ?? [] {
					print("Checking budget: \(document.documentID)")
					if let data = try? document.data(as: FamilyBudget.self) {
						// Members array'ini kontrol et
						let members = data.members
						print("Budget members: \(members.map { $0.id })")
						
						if members.contains(where: { $0.id == userId }) {
							print("✅ Found matching budget for user: \(userId)")
							var budget = data
							budget.id = document.documentID
							completion(budget)
							return
						}
					}
				}
				
				print("❌ No matching budget found for user: \(userId)")
				completion(nil)
			}
		
		return listener
	}
	
	func addFamilyMember(withCode code: String) async throws -> FamilyMember {
		try checkConnection()
		let myUserId = AuthManager.shared.currentUserId
		
		// Kodu kullanan kullanıcıyı bul
		let snapshot = try await db.collection("users")
			.whereField("sharingCode", isEqualTo: code)
			.getDocuments()
		
		guard let memberDoc = snapshot.documents.first else {
			throw NetworkError.notFound("Paylaşım kodu geçersiz")
		}
		
		let memberId = memberDoc.documentID
		guard memberId != myUserId else {
			throw NetworkError.invalidData("Kendinizi ekleyemezsiniz")
		}
		
		// Aile üyesi ilişkisini kaydet
		let familyMember = FamilyMember(
			id: memberId,
			name: memberDoc.data()["name"] as? String ?? "Aile Üyesi",
			role: .member,
			spentAmount: 0
		)
		
		// İki yönlü ilişki kur
		try await db.collection("familyConnections").document().setData([
			"userId1": myUserId,
			"userId2": memberId,
			"createdAt": FieldValue.serverTimestamp()
		])
		
		return familyMember
	}
	
	// Aile işlemleri
	func addFamilyTransaction(_ transaction: FamilyTransaction, toBudget budget: FamilyBudget) async throws {
		try checkConnection()
		
		// Aile bütçesi işlemini kaydet
		try await db.collection("familyBudgets")
			.document(budget.id!)
			.collection("transactions")
			.document(transaction.documentId)
			.setData(transaction.asDictionary())
		
		// Bütçeyi güncelle
		var updatedBudget = budget
		updatedBudget.spentAmount += transaction.amount
		
		// Üye harcamasını güncelle
		if let index = updatedBudget.members.firstIndex(where: { $0.id == transaction.userId }) {
			updatedBudget.members[index].spentAmount += transaction.amount
		}
		
		try await updateFamilyBudget(updatedBudget)
		
		// Kişisel işlem olarak da kaydet
		let personalTransaction = Transaction(
			userId: transaction.userId,
			amount: transaction.amount,
			category: transaction.category.toPersonalCategory(), // Kategoriyi dönüştür
			type: .expense,
			date: transaction.date,
			note: "\(budget.name): \(transaction.note ?? "")",
			createdAt: transaction.createdAt
		)
		
		try await addTransaction(personalTransaction)
	}
	
	func getFamilyTransactions(budgetId: String) async throws -> [FamilyTransaction] {
		try checkConnection()
		
		let snapshot = try await db.collection("familyBudgets")
			.document(budgetId)
			.collection("transactions")
			.order(by: "date", descending: true)
			.getDocuments()
		
		return try snapshot.documents.compactMap { doc in
			var transaction = try doc.data(as: FamilyTransaction.self)
			transaction.id = doc.documentID
			return transaction
		}
	}
	
	// Admin kontrolleri
	func isAdmin(forBudget budget: FamilyBudget) -> Bool {
		let currentUserId = AuthManager.shared.currentUserId
		return budget.members.first { member in 
			member.id == currentUserId && member.role == .admin 
		} != nil
	}
	
	// MARK: - Reminder Operations
	func addReminder(_ reminder: Reminder) async throws {
		let userId = AuthManager.shared.currentUserId

		
		try await db.collection("reminders")
			.document(reminder.documentId)
			.setData(reminder.asDictionary())
	}
	
	func getReminders() async throws -> [Reminder] {
		let userId = AuthManager.shared.currentUserId

		
		let snapshot = try await db.collection("reminders")
			.whereField("userId", isEqualTo: userId)
			.whereField("isActive", isEqualTo: true)
			.order(by: "dueDate")
			.getDocuments()
		
		return try snapshot.documents.compactMap { document in
			var reminder = try document.data(as: Reminder.self)
			reminder.id = document.documentID
			return reminder
		}
	}
	
	func updateReminder(_ reminder: Reminder) async throws {
		guard let id = reminder.id else { return }
		
		try await db.collection("reminders")
			.document(id)
			.setData(reminder.asDictionary())
	}
	
	func deleteReminder(_ reminder: Reminder) async throws {
		guard let id = reminder.id else { return }
		
		try await db.collection("reminders")
			.document(id)
			.delete()
	}
	
	// Bildirim planlaması için yeni fonksiyonlar ekleyelim
	func scheduleReminder(_ reminder: Reminder) async throws {
		 let userId = await AuthManager.shared.currentUserId
		
		// Önce reminder'ı kaydet
		let reminderRef = db.collection("reminders").document()
		var reminderData = reminder.toDictionary()
		reminderData["documentId"] = reminderRef.documentID
		
		try await reminderRef.setData(reminderData)
		
		// FCM token'ı kontrol et
		let userDoc = try await db.collection("users").document(userId).getDocument()
		guard let fcmToken = userDoc.data()?["fcmToken"] as? String else {
			print("❌ FCM token bulunamadı")
			return
		}
		
		// Bildirim planlamasını kaydet
		let notificationData: [String: Any] = [
			"userId": userId,
			"fcmToken": fcmToken,
			"title": reminder.title,
			"body": "\(reminder.amount.currencyFormat()) tutarındaki \(reminder.type == .income ? "gelir" : "gider") hatırlatıcısı",
			"scheduledFor": Timestamp(date: reminder.dueDate),
			"createdAt": Timestamp(date: Date()),
			"status": "scheduled",
			"reminderId": reminderRef.documentID,
			"type": reminder.type.rawValue,
			"category": reminder.category.rawValue,
			"amount": reminder.amount,
			"isProcessed": false
		]
		
		try await db.collection("scheduledNotifications")
			.document()
			.setData(notificationData)
	}
	
	// Bildirim durumunu güncelle
	func updateNotificationStatus(_ notificationId: String, status: String) async throws {
		try await db.collection("scheduledNotifications")
			.document(notificationId)
			.updateData([
				"status": status,
				"processedAt": Timestamp(date: Date()),
				"isProcessed": true
			])
	}
	
	// Bildirimi iptal et
	func cancelNotification(_ notificationId: String) async throws {
		try await db.collection("scheduledNotifications")
			.document(notificationId)
			.updateData([
				"status": "cancelled",
				"cancelledAt": Timestamp(date: Date()),
				"isProcessed": true
			])
	}
	
	func checkFirebaseNotifications() async {
		 let userId = await AuthManager.shared.currentUserId 
		
		do {
			
			// scheduledNotifications koleksiyonunu kontrol et
			let scheduledSnapshot = try await db.collection("scheduledNotifications")
				.whereField("userId", isEqualTo: userId)
				.getDocuments()
			
			
			// notifications koleksiyonunu kontrol et
			let notificationsSnapshot = try await db.collection("notifications")
				.whereField("userId", isEqualTo: userId)
				.getDocuments()
			
		
			
		} catch {
		}
	}
	
	// MARK: - User Settings
	func getUserSettings() async throws -> UserSettings? {
		let userId = AuthManager.shared.currentUserId
		
		let document = try await db.collection("userSettings")
			.document(userId)
			.getDocument()
		
		return try? document.data(as: UserSettings.self)
	}
	
	func saveUserSettings(_ settings: UserSettings) async throws {
		let userId = AuthManager.shared.currentUserId
		
		var data = settings.asDictionary()
		data["updatedAt"] = FieldValue.serverTimestamp()
		
		try await db.collection("userSettings")
			.document(userId)
			.setData(data, merge: true)
	}
	
	// Paylaşım kodu ile bütçe bul
	func findFamilyBudgetByCode(_ code: String) async throws -> FamilyBudget? {
		let snapshot = try await db.collection("familyBudgets")
			.whereField("sharingCode", isEqualTo: code)
			.getDocuments()
		
		guard let doc = snapshot.documents.first else { return nil }
		return try? doc.data(as: FamilyBudget.self)
	}
	
	// Bütçeye katıl
	func joinFamilyBudget(withCode code: String) async throws {
		guard let budget = try await findFamilyBudgetByCode(code) else {
			throw NetworkError.serverError("Bütçe bulunamadı")
		}
		
		let userId = AuthManager.shared.currentUserId
		
		// Zaten üye mi kontrol et
		if budget.members.contains(where: { $0.id == userId }) {
			throw NetworkError.serverError("Bu bütçeye zaten üyesiniz")
		}
		
		// Yeni üye olarak ekle
		var updatedBudget = budget
		let newMember = FamilyBudget.FamilyMember(
			id: userId,
			name: AuthManager.shared.currentUserName,
			role: .member,
			spentAmount: 0
		)
		
		updatedBudget.members.append(newMember)
		try await updateFamilyBudget(updatedBudget)
	}
	
	func getFamilyBudget() async throws -> FamilyBudget? {
		let userId = AuthManager.shared.currentUserId
		print("🔍 Fetching family budget for user: \(userId)")
		
		let snapshot = try await db.collection("familyBudgets")
			.getDocuments()
		
		for document in snapshot.documents {
			if let data = try? document.data(as: FamilyBudget.self),
			   data.members.contains(where: { $0.id == userId }) {
				var budget = data
				budget.id = document.documentID
				print("✅ Found family budget: \(budget.name)")
				return budget
			}
		}
		
		print("ℹ️ No family budget found for user")
		return nil
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

// RecurringTransaction işlemleri için extension ekleyelim
extension FirebaseService {
	// Tekrarlanan işlem dinleyicisi ekle
	func addRecurringTransactionListener(userId: String, completion: @escaping ([RecurringTransaction]) -> Void) -> ListenerRegistration {
		let listener = db.collection("recurring_transactions")
			.whereField("userId", isEqualTo: userId)
			.addSnapshotListener { snapshot, error in
				guard let documents = snapshot?.documents else {
					print("Tekrarlanan işlemler dinlenirken hata: \(error?.localizedDescription ?? "")")
					return
				}
				
				let transactions = documents.compactMap { document -> RecurringTransaction? in
					var transaction = try? document.data(as: RecurringTransaction.self)
					transaction?.id = document.documentID
					return transaction
				}
				
				completion(transactions)
			}
		
		return listener
	}
	
	
	// Tekrarlanan işlem güncelle
	func updateRecurringTransaction(_ transaction: RecurringTransaction) async throws {
		let documentId = transaction.documentId
		
		print("🔄 Updating recurring transaction...")
		print("📝 Transaction data to update:")
		print("- Document ID: \(documentId)")
		print("- Title: \(transaction.title)")
		print("- Last Processed: \(transaction.lastProcessed?.description ?? "nil")")
		print("- Next Due Date: \(transaction.nextDueDate?.description ?? "nil")")
		
		var data = transaction.asDictionary()
		data.removeValue(forKey: "id")
		
		print("📄 Full update data: \(data)")
		
		do {
			try await db.collection("recurring_transactions")
				.document(documentId)
				.setData(data, merge: true)
			
			print("✅ Successfully updated recurring transaction: \(documentId)")
		} catch {
			print("❌ Failed to update recurring transaction: \(error.localizedDescription)")
			throw error
		}
	}
	
	
	
	// Tekrarlanan işlemleri işle
	func processRecurringTransactions() async throws {
		print("🔄 Starting recurring transactions processing...")
		let userId = AuthManager.shared.currentUserId
		
		let today = Calendar.current.startOfDay(for: Date())
		print("📅 Checking transactions for date: \(today)")
		
		let snapshot = try await db.collection("recurring_transactions")
			.whereField("userId", isEqualTo: userId)
			.whereField("isActive", isEqualTo: true)
			.getDocuments()
		
		print("📊 Found \(snapshot.documents.count) recurring transactions")
		
		for document in snapshot.documents {
			do {
				// Döküman ID'sini ekleyerek RecurringTransaction oluştur
				var transaction = try document.data(as: RecurringTransaction.self)
				transaction.id = document.documentID // Önemli: document ID'yi set et
				
				print("🔍 Processing transaction: \(transaction.title) (ID: \(transaction.documentId))")
				
				// İlk işlem için başlangıç tarihini kontrol et
				let baseDate = transaction.nextDueDate ?? transaction.lastProcessed ?? transaction.startDate
				let processDay = Calendar.current.startOfDay(for: baseDate)
				
				print("📅 Processing from date: \(processDay)")
				
				// Bugüne kadar olan tüm işlemleri oluştur
				var currentDate = processDay
				while currentDate <= today {
					print("✅ Creating transaction for date: \(currentDate)")
					
					// Yeni işlem oluştur ve ekle
					let newTransaction = Transaction(
						userId: transaction.userId,
						amount: transaction.amount,
						category: transaction.category,
						type: transaction.type,
						date: currentDate,
						note: "Otomatik oluşturuldu: \(transaction.title)",
						createdAt: Date()
					)
					
					try await addTransaction(newTransaction)
					
					// Son işlem tarihini güncelle
					transaction.lastProcessed = currentDate
					
					// Bir sonraki tarihi hesapla
					guard let nextDate = calculateNextDate(from: currentDate, frequency: transaction.frequency) else {
						break
					}
					
					currentDate = Calendar.current.startOfDay(for: nextDate)
				}
				
				// Bir sonraki planlanan tarihi hesapla ve kaydet
				if let nextDate = calculateNextDate(from: transaction.lastProcessed ?? today, frequency: transaction.frequency) {
					transaction.nextDueDate = nextDate
					print("📅 Setting next due date to: \(nextDate)")
					
					// Tekrarlanan işlemi güncelle
					try await updateRecurringTransaction(transaction)
					print("✅ Successfully updated recurring transaction: \(transaction.title)")
				}
			} catch {
				print("❌ Error processing transaction \(document.documentID): \(error.localizedDescription)")
				continue // Bir işlem başarısız olsa bile diğerlerine devam et
			}
		}
	}
	
	// Bir sonraki tarihi hesapla
	private func calculateNextDate(from date: Date, frequency: RecurringFrequency) -> Date? {
		let calendar = Calendar.current
		
		switch frequency {
		case .daily:
			return calendar.date(byAdding: .day, value: 1, to: date)
		case .weekly:
			return calendar.date(byAdding: .weekOfYear, value: 1, to: date)
		case .monthly:
			return calendar.date(byAdding: .month, value: 1, to: date)
		case .yearly:
			return calendar.date(byAdding: .year, value: 1, to: date)
		}
	}
}

extension FirebaseService {
	
	
	
	// Üye ekleme fonksiyonu güncelleme
	func addMemberToBudget(_ member: FamilyBudget.FamilyMember, toBudget budget: FamilyBudget) async throws {
		var updatedBudget = budget
		updatedBudget.members.append(member)
		try await updateFamilyBudget(updatedBudget)
	}
	
	

	
	// Kullanıcı bilgilerini getir
	func getFamilyMember(withCode code: String) async throws -> FamilyMember? {
		let snapshot = try await db.collection("users")
			.whereField("sharingCode", isEqualTo: code)
			.getDocuments()
		
		guard let doc = snapshot.documents.first else { return nil }
		
		return FamilyMember(
			id: doc.documentID,
			name: doc.data()["name"] as? String ?? "Aile Üyesi",
			role: .member,
			spentAmount: 0
		)
	}
}

// Aile üyesi modeli
struct FamilyMember: Identifiable, Codable {
	let id: String
	let name: String
	let role: FamilyRole
	var spentAmount: Double
	
	enum FamilyRole: String, Codable {
		case admin
		case member
	}
}

// FamilyBudget modelinde debug için extension ekleyelim
extension FamilyBudget: CustomDebugStringConvertible {
	var debugDescription: String {
		"""
		FamilyBudget(
			id: \(id ?? "nil"),
			name: \(name),
			members: \(members.map { "(\($0.id), \($0.name))" }),
			sharingCode: \(sharingCode)
		)
		"""
	}
}

extension FirebaseService {
	func removeMemberFromBudget(memberId: String, fromBudget budget: FamilyBudget) async throws {
		var updatedBudget = budget
		
		// Üyeyi listeden çıkar
		updatedBudget.members.removeAll { $0.id == memberId }
		
		// Bütçeyi güncelle
		try await updateFamilyBudget(updatedBudget)
		
		print("✅ Member removed from family budget: \(memberId)")
	}
}

