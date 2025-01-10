import SwiftUI
import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

protocol TransactionStoreProtocol {
    var transactions: [Transaction] { get }
    var currentMonthTransactions: [Transaction] { get }
    var currentMonthExpenses: [Transaction] { get }
    var currentMonthIncomes: [Transaction] { get }
    
    func update(with transactions: [Transaction])
    func getExpensesForCategory(_ category: Category) -> Double
    func getExpensesForCategories(_ categories: [Category]) -> [Category: Double]
}

@MainActor
class TransactionStore: ObservableObject, TransactionStoreProtocol {
    static let shared = TransactionStore()
    
    @Published private(set) var transactions: [Transaction] = []
    @Published private(set) var recurringTransactions: [RecurringTransaction] = []
    
    private init() {}
    
    func update(with transactions: [Transaction]) {
        // Tarihe göre sırala (en yeniden en eskiye)
        self.transactions = transactions.sorted { $0.date > $1.date }
        NotificationCenter.default.post(name: .transactionsDidUpdate, object: nil)
    }
    
    func refresh() async {
		 let userId = AuthManager.shared.currentUserId
        
        do {
            // Normal işlemleri al
            let snapshot = try await FirebaseService.shared.db.collection("transactions")
                .whereField("userId", isEqualTo: userId)
                .order(by: "date", descending: true)
                .getDocuments()
            
            let transactions = snapshot.documents.compactMap { document -> Transaction? in
                var transaction = try? document.data(as: Transaction.self)
                transaction?.id = document.documentID
                return transaction
            }
            
            // Tekrarlanan işlemleri al
            let recurringSnapshot = try await FirebaseService.shared.db.collection("recurring_transactions")
                .whereField("userId", isEqualTo: userId)
                .getDocuments()
            
            let recurringTransactions = recurringSnapshot.documents.compactMap { document -> RecurringTransaction? in
                var transaction = try? document.data(as: RecurringTransaction.self)
                transaction?.id = document.documentID
                return transaction
            }
            
            await MainActor.run {
                self.transactions = transactions
                self.recurringTransactions = recurringTransactions
            }
            
            // Tekrarlanan işlemleri işle
            try await FirebaseService.shared.processRecurringTransactions()
            
        } catch {
            print("❌ TransactionStore refresh hatası: \(error.localizedDescription)")
        }
    }
    
    var currentMonthTransactions: [Transaction] {
        let startOfMonth = Date().startOfMonth()
        return transactions.filter { $0.date >= startOfMonth }
    }
    
    var currentMonthIncomes: [Transaction] {
        currentMonthTransactions.filter { $0.type == .income }
    }
    
    var currentMonthExpenses: [Transaction] {
        currentMonthTransactions.filter { $0.type == .expense }
    }
    
    // TransactionStoreProtocol gereksinimleri
    func getExpensesForCategory(_ category: Category) -> Double {
        currentMonthExpenses
            .filter { $0.category == category }
            .reduce(0) { $0 + $1.amount }
    }
    
    func getExpensesForCategories(_ categories: [Category]) -> [Category: Double] {
        var result: [Category: Double] = [:]
        categories.forEach { category in
            result[category] = getExpensesForCategory(category)
        }
        return result
    }
    
    func updateRecurringTransactions(_ transactions: [RecurringTransaction]) {
        self.recurringTransactions = transactions.sorted { $0.startDate > $1.startDate }
    }
}

// Calendar extension
private extension Calendar {
    func isDateInCurrentMonth(_ date: Date) -> Bool {
        isDate(date, equalTo: Date(), toGranularity: .month)
    }
} 
