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
    @Published var categoryPredictions: [CategoryPrediction] = []
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
        
        // Kategori tahminlerini hesapla
        categoryPredictions = await calculateCategoryPredictions(from: transactions)
        
        updateSavingsAnalysis(transactions)
    }
    
    private func calculateCategoryPredictions(from transactions: [Transaction]) async -> [CategoryPrediction] {
        await withTaskGroup(of: CategoryPrediction.self) { group in
            for category in Category.allCases {
                group.addTask {
                    let categoryTransactions = transactions.filter { $0.category == category }
                    let amounts = categoryTransactions.map { $0.amount }
                    
                    // Ortalama hesapla
                    let average = amounts.reduce(0, +) / Double(max(amounts.count, 1))
                    
                    // Güven skorunu hesapla
                    let confidence: Double
                    if amounts.isEmpty {
                        confidence = 0.5 // Hiç işlem yoksa düşük güven
                    } else {
                        // Son 3 ayın işlem sayılarını hesapla
                        let calendar = Calendar.current
                        let currentDate = Date()
                        
                        let monthlyTransactionCounts = (0..<3).map { monthsAgo -> Int in
                            let startOfMonth = calendar.date(byAdding: .month, value: -monthsAgo, to: currentDate)?.startOfMonth() ?? Date()
                            let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)?.startOfMonth() ?? Date()
                            
                            return categoryTransactions.filter {
                                $0.date >= startOfMonth && $0.date < endOfMonth
                            }.count
                        }
                        
                        // İşlem sayısı tutarlılığını kontrol et
                        let transactionCountConsistency: Double
                        if monthlyTransactionCounts.count >= 2 {
                            let differences = zip(monthlyTransactionCounts, monthlyTransactionCounts.dropFirst())
                                .map { abs($0 - $1) }
                            let avgDifference = Double(differences.reduce(0, +)) / Double(differences.count)
                            
                            // Eğer fark artıyorsa güven düşer
                            transactionCountConsistency = 1.0 - min(avgDifference / 5.0, 0.5)
                        } else {
                            transactionCountConsistency = 0.5
                        }
                        
                        // Bütçe limit kontrolü
                        let budgetLimitScore: Double
                        if let currentBudget = try? await FirebaseService.shared.getCurrentBudget(),
                           let categoryBudget = currentBudget.categoryLimits.first(where: { $0.category == category }) {
                            let spentRatio = categoryBudget.spent / categoryBudget.limit
                            
                            if spentRatio > 1.0 { // Limit aşılmış
                                budgetLimitScore = 0.3
                            } else if spentRatio > 0.9 { // Limite yaklaşılmış
                                budgetLimitScore = 0.6
                            } else {
                                budgetLimitScore = 1.0
                            }
                        } else {
                            budgetLimitScore = 0.7 // Bütçe limiti yoksa orta güven
                        }
                        
                        // İşlem sıklığı skoru
                        let frequencyScore: Double
                        let monthlyAverage = Double(monthlyTransactionCounts[0])
                        if monthlyAverage > 8 { // Yüksek sıklık
                            frequencyScore = 0.9
                        } else if monthlyAverage > 5 {
                            frequencyScore = 0.7
                        } else if monthlyAverage > 3 {
                            frequencyScore = 0.5
                        } else {
                            frequencyScore = 0.3
                        }
                        
                        // Son aydaki işlem sayısı önceki aylara göre çok farklıysa güveni düşür
                        let lastMonthVariance = abs(Double(monthlyTransactionCounts[0]) -
                                                  Double(monthlyTransactionCounts.dropFirst().reduce(0, +)) /
                                                  Double(max(monthlyTransactionCounts.count - 1, 1)))
                        
                        let stabilityScore = 1.0 - min(lastMonthVariance / 5.0, 0.5)
                        
                        // Tüm faktörleri birleştir
                        confidence = min((
                            transactionCountConsistency * 0.3 + // İşlem sayısı tutarlılığı
                            budgetLimitScore * 0.3 +           // Bütçe limit durumu
                            frequencyScore * 0.2 +             // İşlem sıklığı
                            stabilityScore * 0.2               // Son ay stabilitesi
                        ), 1.0)
                    }
                    
                    return CategoryPrediction(
                        category: category,
                        predictedAmount: average * 1.1,
                        confidence: confidence
                    )
                }
            }
            
            var predictions: [CategoryPrediction] = []
            for await prediction in group {
                predictions.append(prediction)
            }
            return predictions.sorted { $0.category.rawValue < $1.category.rawValue }
        }
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
			return "\(category.localizedName) kategorisindeki harcamalarınızı gözden geçirin"
        }
    }
} 
