import Foundation
import FirebaseFirestore

@MainActor
class AnalyticsViewModel: ObservableObject {
    @Published private(set) var monthlyTrends: [MonthlyTrend] = []
    @Published private(set) var categoryComparisons: [CategoryComparison] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var showAdvancedAnalytics = false
	@Published private(set) var periodData: [AnalyticstcsCategorySpending] = []
    
    private var currentPeriod: AnalysisPeriod = .monthly
    private let firebaseService = FirebaseService.shared
    
    init() {
        Task {
            await loadData()
        }
    }
    
    func updatePeriod(_ period: AnalysisPeriod) {
        currentPeriod = period
        Task {
            await loadData()
        }
    }
    
    func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let transactions = try await firebaseService.getTransactions()
            processTransactions(transactions)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func processTransactions(_ transactions: [Transaction]) {
        let calendar = Calendar.current
        let now = Date()
        
        // Seçilen periyoda göre başlangıç tarihini belirle
        let startDate: Date
        switch currentPeriod {
        case .weekly:
            startDate = calendar.date(byAdding: .weekOfYear, value: -12, to: now) ?? now
        case .monthly:
            startDate = calendar.date(byAdding: .month, value: -12, to: now) ?? now
        case .quarterly:
            startDate = calendar.date(byAdding: .month, value: -12, to: now) ?? now
        case .yearly:
            startDate = calendar.date(byAdding: .year, value: -3, to: now) ?? now
        }
        
        // Filtrelenmiş işlemler
        let filteredTransactions = transactions.filter { $0.date >= startDate }
        
        // Aylık trendleri hesapla
        var trends: [String: Double] = [:]
        var monthlyTransactions: [String: [Transaction]] = [:]
        
        for transaction in filteredTransactions {
            let monthKey = formatDateKey(transaction.date)
            trends[monthKey, default: 0] += transaction.type == .expense ? transaction.amount : 0
            monthlyTransactions[monthKey, default: []].append(transaction)
        }
        
        // Trendleri sırala ve MonthlyTrend dizisine dönüştür
        monthlyTrends = trends.map { MonthlyTrend(month: $0.key, amount: $0.value) }
            .sorted { $0.month < $1.month }
        
        // Kategori karşılaştırmalarını hesapla
        if let lastMonth = monthlyTransactions[formatDateKey(now)],
           let previousMonth = monthlyTransactions[formatDateKey(calendar.date(byAdding: .month, value: -1, to: now) ?? now)] {
            
            var comparisons: [CategoryComparison] = []
            
            for category in Category.expenseCategories {
                let currentAmount = lastMonth
                    .filter { $0.category == category && $0.type == .expense }
                    .reduce(0) { $0 + $1.amount }
                
                let previousAmount = previousMonth
                    .filter { $0.category == category && $0.type == .expense }
                    .reduce(0) { $0 + $1.amount }
                
                if currentAmount > 0 || previousAmount > 0 {
                    comparisons.append(CategoryComparison(
                        category: category,
                        currentAmount: currentAmount,
                        previousAmount: previousAmount
                    ))
                }
            }
            
            categoryComparisons = comparisons.sorted { $0.currentAmount > $1.currentAmount }
        }
        
        // Dönem verilerini hesapla
        var categorySpending: [Category: Double] = [:]
        let totalSpending = filteredTransactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
        
        for transaction in filteredTransactions where transaction.type == .expense {
            categorySpending[transaction.category, default: 0] += transaction.amount
        }
        
        // CategorySpending dizisini oluştur
        periodData = categorySpending.map { category, amount in
            let percentage = totalSpending > 0 ? (amount / totalSpending) * 100 : 0
            return AnalyticstcsCategorySpending(
                category: category,
                amount: amount,
                percentage: percentage
            )
        }.sorted { $0.amount > $1.amount }
    }
    
    private func formatDateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        switch currentPeriod {
        case .weekly:
            formatter.dateFormat = "'Hafta' w, MMM yyyy"
        case .monthly:
            formatter.dateFormat = "MMM yyyy"
        case .quarterly:
            let quarter = Calendar.current.component(.quarter, from: date)
            formatter.dateFormat = "yyyy"
            return "Q\(quarter) " + formatter.string(from: date)
        case .yearly:
            formatter.dateFormat = "yyyy"
        }
        
        return formatter.string(from: date)
    }
}

struct AnalyticstcsCategorySpending: Identifiable {
    let id = UUID()
    let category: Category
    let amount: Double
    let percentage: Double
} 
