import Foundation

struct MonthlyTrend: Identifiable {
    let id = UUID()
    let month: String
    let amount: Double
}

struct CategoryComparison: Identifiable {
    let id = UUID()
    let category: Category
    let currentAmount: Double
    let previousAmount: Double
}

struct CategoryPrediction: Identifiable {
    let id = UUID()
    let category: Category
    let predictedAmount: Double
    let confidence: Double
}

@MainActor
class AdvancedAnalyticsViewModel: ObservableObject {
    @Published private(set) var monthlyTrends: [MonthlyTrend] = []
    @Published private(set) var categoryComparisons: [CategoryComparison] = []
    @Published private(set) var categoryPredictions: [CategoryPrediction] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var savingsGoal: Double = 1000 // Örnek değer
    @Published private(set) var savingsProgress: Double = 0.0
    @Published private(set) var savingsSuggestions: [String] = []
    
    // Hesaplanan özellikler
    var averageSpending: Double {
        monthlyTrends.map { $0.amount }.reduce(0, +) / Double(monthlyTrends.count)
    }
    
    var spendingTrend: Double {
        guard let last = monthlyTrends.last?.amount,
              let previous = monthlyTrends.dropLast().last?.amount else { return 0 }
        return ((last - previous) / previous) * 100
    }
    
    var highestSpending: Double {
        monthlyTrends.map { $0.amount }.max() ?? 0
    }
    
    var highestSpendingMonth: String {
        monthlyTrends.max { $0.amount < $1.amount }?.month ?? ""
    }
    
    var predictedSpending: Double {
        // ML modeli entegre edildiğinde güncellenecek
        averageSpending * 1.1
    }
    
    var predictedSaving: Double {
        // ML modeli entegre edildiğinde güncellenecek
        averageSpending * 0.2
    }
    
    var predictedTrend: Double {
        ((predictedSpending - averageSpending) / averageSpending) * 100
    }
    
    var savingTrend: Double {
        5.0 // ML modeli entegre edildiğinde güncellenecek
    }
    
    init() {
        Task {
            await loadData()
        }
    }
    
    func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Son 6 ayın verilerini al
            let transactions = try await FirebaseService.shared.getTransactions()
            await processTransactions(transactions)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func processTransactions(_ transactions: [Transaction]) async {
        // Aylık trendleri hesapla
        let grouped = Dictionary(grouping: transactions) { transaction in
            transaction.date.formatted(.dateTime.month(.abbreviated))
        }
        
        monthlyTrends = grouped.map { month, transactions in
            MonthlyTrend(
                month: month,
                amount: transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            )
        }.sorted { $0.month < $1.month }
        
        // Kategori karşılaştırmalarını hesapla
        let currentMonth = Date().startOfMonth()
        let previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth)!
        
        let currentMonthTransactions = transactions.filter { $0.date >= currentMonth }
        let previousMonthTransactions = transactions.filter { $0.date >= previousMonth && $0.date < currentMonth }
        
        categoryComparisons = Category.allCases.map { category in
            let currentAmount = currentMonthTransactions
                .filter { $0.category == category }
                .reduce(0) { $0 + $1.amount }
            
            let previousAmount = previousMonthTransactions
                .filter { $0.category == category }
                .reduce(0) { $0 + $1.amount }
            
            return CategoryComparison(
                category: category,
                currentAmount: currentAmount,
                previousAmount: previousAmount
            )
        }
        
        // Kategori tahminlerini hesapla (basit bir tahmin)
        categoryPredictions = Category.allCases.map { category in
            let amounts = transactions
                .filter { $0.category == category }
                .map { $0.amount }
            
            let average = amounts.reduce(0, +) / Double(max(amounts.count, 1))
            
            return CategoryPrediction(
                category: category,
                predictedAmount: average * 1.1,
                confidence: 0.8
            )
        }
        
        updateSavingsAnalysis(transactions)
    }
    
    private func updateSavingsAnalysis(_ transactions: [Transaction]) {
        // Tasarruf hedefine ilerlemeyi hesapla
        let currentMonth = Date().startOfMonth()
        let currentMonthTransactions = transactions.filter { $0.date >= currentMonth }
        
        let income = currentMonthTransactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
        
        let expenses = currentMonthTransactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
        
        let actualSavings = income - expenses
        savingsProgress = min(max(actualSavings / savingsGoal, 0), 1)
        
        // Tasarruf önerilerini güncelle
        updateSavingsSuggestions(transactions)
    }
    
    private func updateSavingsSuggestions(_ transactions: [Transaction]) {
        var suggestions: [String] = []
        
        // En yüksek harcama kategorilerini bul
        let topExpenseCategories = categoryComparisons
            .sorted { $0.currentAmount > $1.currentAmount }
            .prefix(2)
        
        for category in topExpenseCategories {
            let suggestion = generateSuggestion(for: category.category, amount: category.currentAmount)
            suggestions.append(suggestion)
        }
        
        // Genel tasarruf önerileri
        suggestions.append("Düzenli gelir ve giderlerinizi takip ederek bütçe planı oluşturun")
        suggestions.append("Gereksiz abonelikleri iptal ederek aylık tasarruf yapın")
        
        savingsSuggestions = suggestions
    }
    
    private func generateSuggestion(for category: Category, amount: Double) -> String {
        switch category {
        case .market:
            return "Market alışverişlerinizi liste yaparak ve indirim günlerini takip ederek optimize edin"
        case .ulasim:
            return "Toplu taşıma kullanarak veya araç paylaşımı yaparak ulaşım giderlerinizi azaltın"
        case .eglence:
            return "Eğlence harcamalarınızı ücretsiz etkinliklerle dengeleyebilirsiniz"
        default:
            return "\(category.rawValue) kategorisindeki harcamalarınızı gözden geçirin"
        }
    }
} 
