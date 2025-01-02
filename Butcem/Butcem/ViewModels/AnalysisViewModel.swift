import SwiftUI
import Combine

@MainActor
class AnalysisViewModel: ObservableObject {
    @Published var selectedPeriod: AnalysisPeriod = .monthly
    @Published private(set) var categorySpending: [CategorySpending] = []
    @Published private(set) var monthlyTrends: [(month: String, amount: Double)] = []
    @Published private(set) var summary: AnalysisSummary = .empty
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        $selectedPeriod
            .sink { [weak self] _ in
                self?.fetchData()
            }
            .store(in: &cancellables)
    }
    
    func fetchData() {
        Task {
            await updateAnalysisData()
        }
    }
    
    private func updateAnalysisData() async {
        let transactions = TransactionStore.shared.transactions
        let filteredTransactions = filterTransactionsByPeriod(transactions)
        
        updateCategorySpending(with: filteredTransactions)
        updateMonthlyTrends(with: filteredTransactions)
        updateSummary(with: filteredTransactions)
    }
    
    private func filterTransactionsByPeriod(_ transactions: [Transaction]) -> [Transaction] {
        let calendar = Calendar.current
        let startDate = calendar.date(
            byAdding: selectedPeriod.dateRange,
            to: Date()
        ) ?? Date()
        
        return transactions.filter { $0.date >= startDate }
    }
    
    private func updateCategorySpending(with transactions: [Transaction]) {
        let expensesByCategory = Dictionary(grouping: transactions.filter { $0.type == .expense }) {
            $0.category
        }
        
        let totalExpense = transactions.filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
        
        categorySpending = expensesByCategory.map { category, transactions in
            let amount = transactions.reduce(0) { $0 + $1.amount }
            return CategorySpending(
                category: category,
                amount: amount,
                totalAmount: totalExpense
            )
        }.sorted { $0.amount > $1.amount }
    }
    
    private func updateMonthlyTrends(with transactions: [Transaction]) {
        let monthlyData = Dictionary(grouping: transactions) { transaction in
            transaction.date.monthYearString()
        }
        
        monthlyTrends = monthlyData.map { month, transactions in
            let amount = transactions.filter { $0.type == .expense }
                .reduce(0) { $0 + $1.amount }
            return (month: month, amount: amount)
        }.sorted { $0.month < $1.month }
    }
    
    private func updateSummary(with transactions: [Transaction]) {
        let income = transactions.filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
        
        let expense = transactions.filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
        
        summary = AnalysisSummary(
            income: income,
            expense: expense,
            balance: income - expense,
            transactionCount: transactions.count
        )
    }
}


struct AnalysisSummary {
    let income: Double
    let expense: Double
    let balance: Double
    let transactionCount: Int
    
    static let empty = AnalysisSummary(
        income: 0,
        expense: 0,
        balance: 0,
        transactionCount: 0
    )
}

