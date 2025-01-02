import SwiftUI
import Foundation
import Combine
import FirebaseFirestore

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
        do {
            let transactions = try await FirebaseService.shared.getTransactions()
            await MainActor.run {
                update(with: transactions)
            }
        } catch {
            print("Failed to refresh transactions: \(error)")
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
}

// Calendar extension
private extension Calendar {
    func isDateInCurrentMonth(_ date: Date) -> Bool {
        isDate(date, equalTo: Date(), toGranularity: .month)
    }
} 
