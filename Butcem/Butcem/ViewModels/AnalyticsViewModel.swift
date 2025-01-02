import Foundation
import FirebaseFirestore

@MainActor
class AnalyticsViewModel: ObservableObject {
    @Published private(set) var periodData: [(date: Date, income: Double, expense: Double)] = []
    @Published private(set) var categoryData: [(category: Category, amount: Double, percentage: Double)] = []
    @Published private(set) var trendData: [(date: Date, value: Double)] = []
    @Published private(set) var savingsRate: Double = 0
    @Published var showAdvancedAnalytics = false
    
    private let transactionStore: TransactionStoreProtocol
    private var currentPeriod: AnalysisPeriod = .monthly
    
    init(transactionStore: TransactionStoreProtocol = TransactionStore.shared) {
        self.transactionStore = transactionStore
        setupObservers()
        calculateAnalytics()
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTransactionsUpdate),
            name: .transactionsDidUpdate,
            object: nil
        )
    }
    
    @objc private func handleTransactionsUpdate() {
        calculateAnalytics()
    }
    
    func updatePeriod(_ period: AnalysisPeriod) {
        currentPeriod = period
        calculateAnalytics()
    }
    
    private func calculateAnalytics() {
        let startDate = Calendar.current.date(byAdding: currentPeriod.dateRange, to: Date()) ?? Date()
        let transactions = transactionStore.transactions.filter { $0.date >= startDate }
        
        calculatePeriodData(transactions)
        calculateCategoryData(transactions)
        calculateTrendData(transactions)
        calculateSavingsRate(transactions)
    }
    
    private func calculatePeriodData(_ transactions: [Transaction]) {
        var result: [(date: Date, income: Double, expense: Double)] = []
        let calendar = Calendar.current
        
        // Dönem başlangıcından bugüne kadar olan günleri grupla
        let groupedTransactions = Dictionary(grouping: transactions) { transaction in
            calendar.startOfDay(for: transaction.date)
        }
        
        // Her gün için gelir ve giderleri hesapla
        let sortedDates = groupedTransactions.keys.sorted()
        for date in sortedDates {
            let dayTransactions = groupedTransactions[date] ?? []
            let income = dayTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let expense = dayTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            result.append((date: date, income: income, expense: expense))
        }
        
        periodData = result
    }
    
    private func calculateCategoryData(_ transactions: [Transaction]) {
        let expenses = transactions.filter { $0.type == .expense }
        var categoryAmounts: [Category: Double] = [:]
        
        // Kategori bazlı toplam harcamaları hesapla
        expenses.forEach { transaction in
            categoryAmounts[transaction.category, default: 0] += transaction.amount
        }
        
        let totalExpense = expenses.reduce(0) { $0 + $1.amount }
        
        // Yüzdeleri hesapla ve sırala
        categoryData = categoryAmounts.map { category, amount in
            (
                category: category,
                amount: amount,
                percentage: totalExpense > 0 ? (amount / totalExpense) * 100 : 0
            )
        }.sorted { $0.amount > $1.amount }
    }
    
    private func calculateTrendData(_ transactions: [Transaction]) {
        var result: [(date: Date, value: Double)] = []
        let calendar = Calendar.current
        
        // Günlük toplam harcamaları hesapla
        let groupedTransactions = Dictionary(grouping: transactions) { transaction in
            calendar.startOfDay(for: transaction.date)
        }
        
        // Her gün için toplam harcamayı hesapla
        let sortedDates = groupedTransactions.keys.sorted()
        for date in sortedDates {
            let dayExpenses = groupedTransactions[date]?
                .filter { $0.type == .expense }
                .reduce(0) { $0 + $1.amount } ?? 0
            result.append((date: date, value: dayExpenses))
        }
        
        trendData = result
    }
    
    private func calculateSavingsRate(_ transactions: [Transaction]) {
        let income = transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let expense = transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        savingsRate = income > 0 ? ((income - expense) / income) * 100 : 0
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
} 
