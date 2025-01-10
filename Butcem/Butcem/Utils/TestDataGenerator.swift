import Foundation
import FirebaseFirestore
import FirebaseAuth
class TestDataGenerator {
    static let shared = TestDataGenerator()
    private let db = Firestore.firestore()
    
    private let incomeCategories: [Category] = [
        .maas,
        .kira,
        .yatirim,
        .faiz,
        .ikramiye
    ]
    
    private let expenseCategories: [Category] = [
        .market,
        .faturalar,
        .ulasim,
        .saglik,
        .egitim,
        .restoran,
        .giyim,
        .eglence,
        .teknoloji
    ]
    
    private let expenseNotes: [String] = [
        "Market alışverişi",
        "Elektrik faturası",
        "Akbil yükleme",
        "İlaç",
        "Kurs ödemesi",
        "Dışarıda yemek",
        "Kıyafet alışverişi",
        "Sinema bileti",
        "Telefon tamiri"
    ]
    
    func generateYearlyData(for userId: String) async throws {
        let batch = db.batch()
        let now = Date()
        let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: now) ?? now
        
        // Sabit gelir (Maaş)
        let baseSalary: Double = 15000
        var currentDate = oneYearAgo
        
        while currentDate <= now {
            // Her ay için maaş
            let salaryVariation = Double.random(in: -1000...1000)
            let salary = Transaction(
                userId: userId,
                amount: baseSalary + salaryVariation,
                category: .maas,
                type: .income,
                date: currentDate,
                note: "Aylık maaş",
                createdAt: currentDate
            )
            
            let salaryRef = db.collection("transactions").document()
            try batch.setData(from: salary, forDocument: salaryRef)
            
            // Her ay için 15-20 arası rastgele harcama
            let numberOfExpenses = Int.random(in: 15...20)
            
            for _ in 0..<numberOfExpenses {
                let expenseDate = Calendar.current.date(
                    byAdding: .day,
                    value: Int.random(in: 1...30),
                    to: currentDate
                ) ?? currentDate
                
                let categoryIndex = Int.random(in: 0..<expenseCategories.count)
                let amount = Double.random(in: 100...1600)
                
                let expense = Transaction(
                    userId: userId,
                    amount: amount,
                    category: expenseCategories[categoryIndex],
                    type: .expense,
                    date: expenseDate,
                    note: expenseNotes[categoryIndex],
                    createdAt: expenseDate
                )
                
                let expenseRef = db.collection("transactions").document()
                try batch.setData(from: expense, forDocument: expenseRef)
            }
            
            // Ekstra gelirler (ayda %30 ihtimalle)
            if Double.random(in: 0...1) > 0.7 {
                let extraIncomeDate = Calendar.current.date(
                    byAdding: .day,
                    value: Int.random(in: 1...30),
                    to: currentDate
                ) ?? currentDate
                
                let categoryIndex = Int.random(in: 1..<incomeCategories.count)
                let amount = Double.random(in: 1000...6000)
                
                let extraIncome = Transaction(
                    userId: userId,
                    amount: amount,
                    category: incomeCategories[categoryIndex],
                    type: .income,
                    date: extraIncomeDate,
                    note: "\(incomeCategories[categoryIndex].rawValue) geliri",
                    createdAt: extraIncomeDate
                )
                
                let incomeRef = db.collection("transactions").document()
                try batch.setData(from: extraIncome, forDocument: incomeRef)
            }
            
            // Bir sonraki aya geç
            currentDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
        }
        
        try await batch.commit()
    }
}

// Kullanımı için extension
extension TestDataGenerator {
    func generateTestData(completion: @escaping (Error?) -> Void) {
         let userId =  AuthManager.shared.currentUserId
        
        Task {
            do {
                try await generateYearlyData(for: userId)
                await MainActor.run {
                    completion(nil)
                }
            } catch {
                await MainActor.run {
                    completion(error)
                }
            }
        }
    }
} 
