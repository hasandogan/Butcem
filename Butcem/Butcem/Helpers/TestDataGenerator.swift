import Foundation
import FirebaseFirestore
import FirebaseAuth

class TestDataGenerator {
    static let shared = TestDataGenerator()
    private let db = Firestore.firestore()
    
    let testUser = (
        email: "test@example.com",
        password: "Test123!",
        name: "Test Kullanıcı"
    )
    
    func generateTestData() async throws {
        // Önce test kullanıcısını Authentication'da oluştur
        let authResult = try await createTestUserAuth()
        let userId = authResult.user.uid
        
        print("Test kullanıcısı oluşturuldu - UserID: \(userId)")
        
        // Firestore'da kullanıcı dokümanını oluştur
        try await createTestUser(userId: userId)
        
        // Son bir yıllık veri oluştur
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .year, value: -1, to: endDate)!
        
        // Aylık bütçeler oluştur
        try await generateBudgets(from: startDate, to: endDate, userId: userId)
        
        // İşlemler oluştur
        try await generateTransactions(from: startDate, to: endDate, userId: userId)
        
        // Finansal hedefler oluştur
        try await generateFinancialGoals(userId: userId)
    }
    
    private func createTestUserAuth() async throws -> AuthDataResult {
        // Kullanıcı zaten varsa silmeyi dene
        do {
            try await Auth.auth().signIn(withEmail: testUser.email, password: testUser.password)
            try await Auth.auth().currentUser?.delete()
        } catch {
            print("Existing user cleanup: \(error.localizedDescription)")
        }
        
        // Yeni test kullanıcısı oluştur
        return try await Auth.auth().createUser(withEmail: testUser.email, password: testUser.password)
    }
    
    private func createTestUser(userId: String) async throws {
        try await db.collection("users").document(userId).setData([
            "name": testUser.name,
            "email": testUser.email,
            "createdAt": FieldValue.serverTimestamp()
        ])
    }
    
    private func generateBudgets(from startDate: Date, to endDate: Date, userId: String) async throws {
        var currentDate = startDate
        
        while currentDate <= endDate {
            let documentId = "\(userId)_\(currentDate.timeIntervalSince1970)"
            
            // Rastgele kategori limitleri oluştur
            let categoryLimits = Category.expenseCategories.map { category in
                let limit = Double.random(in: 500...5000)
                return [
                    "id": UUID().uuidString,
                    "category": category.rawValue,
                    "limit": limit,
                    "spent": Double.random(in: 0...(limit * 0.8))  // Harcama limitin %80'ini geçmesin
                ]
            }
            
            let totalAmount = categoryLimits.reduce(0) { $0 + ($1["limit"] as? Double ?? 0) }
            let totalSpent = categoryLimits.reduce(0) { $0 + ($1["spent"] as? Double ?? 0) }
            
            let budget: [String: Any] = [
                "id": documentId,
                "userId": userId,
                "amount": totalAmount,
                "month": currentDate,
                "categoryLimits": categoryLimits,
                "createdAt": currentDate,
                "notificationsEnabled": true,
                "warningThreshold": 0.7,
                "dangerThreshold": 0.9,
                "spentAmount": totalSpent
            ]
            
            try await db.collection("budgets").document(documentId).setData(budget)
            
            // Bir sonraki aya geç
            if let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) {
                currentDate = nextMonth
            } else {
                break
            }
        }
    }
    
    private func generateTransactions(from startDate: Date, to endDate: Date, userId: String) async throws {
        var currentDate = startDate
        
        while currentDate <= endDate {
            let transactionCount = Int.random(in: 30...50)
            
            for _ in 0..<transactionCount {
                let isExpense = Double.random(in: 0...1) < 0.7
                let category = isExpense ? 
                    Category.expenseCategories.randomElement()! :
                    Category.incomeCategories.randomElement()!
                
                let transaction: [String: Any] = [
                    "userId": userId,
                    "amount": Double.random(in: 10...2000),
                    "category": category.rawValue,
                    "type": isExpense ? TransactionType.expense.rawValue : TransactionType.income.rawValue,
                    "date": Calendar.current.date(
                        byAdding: .day,
                        value: Int.random(in: 0...30),
                        to: currentDate
                    )!,
                    "note": generateRandomNote(for: category),
                    "createdAt": FieldValue.serverTimestamp()
                ]
                
                try await db.collection("transactions")
                    .document(UUID().uuidString)
                    .setData(transaction)
            }
            
            currentDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate)!
        }
    }
    
    private func generateFinancialGoals(userId: String) async throws {
        let goals = [
            (
                title: "Araba Alımı",
                amount: 250000.0,
                category: GoalCategory.purchase,
                type: GoalType.longTerm,
                months: 24
            ),
            (
                title: "Tatil Fonu",
                amount: 50000.0,
                category: GoalCategory.travel,
                type: GoalType.mediumTerm,
                months: 8
            ),
            (
                title: "Acil Durum Fonu",
                amount: 30000.0,
                category: GoalCategory.emergency,
                type: GoalType.shortTerm,
                months: 6
            )
        ]
        
        for goal in goals {
            let deadline = Calendar.current.date(
                byAdding: .month,
                value: goal.months,
                to: Date()
            )!
            
            let goalData: [String: Any] = [
                "userId": userId,
                "title": goal.title,
                "targetAmount": goal.amount,
                "currentAmount": Double.random(in: 0...goal.amount),
                "deadline": deadline,
                "type": goal.type.rawValue,
                "category": goal.category.rawValue,
                "createdAt": Date(),
                "notes": "Test hedef notu"
            ]
            
            try await db.collection("financial_goals")
                .document(UUID().uuidString)
                .setData(goalData)
        }
    }
    
    private func generateRandomNote(for category: Category) -> String {
        let notes: [Category: [String]] = [
            .market: ["Haftalık market alışverişi", "Migros", "A101", "BİM", "Şok"],
            .faturalar: ["Elektrik faturası", "Su faturası", "Doğalgaz", "İnternet"],
            .ulasim: ["Akbil", "Benzin", "Taksi", "Otobüs"],
            .saglik: ["Eczane", "Muayene", "İlaç"],
            .giyim: ["Kıyafet", "Ayakkabı", "Aksesuar"],
            .egitim: ["Kurs ödemesi", "Kitap", "Kırtasiye"],
            .eglence: ["Sinema", "Tiyatro", "Konser", "Cafe"],
			.digerGider: ["Çeşitli harcamalar", "Diğer"],
            .maas: ["Maaş ödemesi", "Ek ödeme"],
            .kira: ["Kira geliri"],
            .faiz: ["Faiz geliri", "Temettü"],
        ]
        
        return notes[category]?.randomElement() ?? "Test notu"
    }
} 
