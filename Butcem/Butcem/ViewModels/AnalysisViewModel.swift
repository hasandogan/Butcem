import SwiftUI
import Combine

@MainActor
class AnalysisViewModel: ObservableObject {
    @Published private(set) var monthlyAnalysis: MonthlyAnalysis?
    @Published private(set) var categoryAnalysis: [CategoryAnalysis] = []
    @Published private(set) var trendAnalysis: TrendAnalysis?
    @Published private(set) var savingsAnalysis: SavingsAnalysis?
    @Published private(set) var predictionAnalysis: [PredictionAnalysis] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    
    private let firebaseService = FirebaseService.shared
    private var currentPeriod: AnalysisPeriod = .monthly
    
    func loadAnalysisData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let transactions = try await firebaseService.getTransactions()
            let budgets = try await firebaseService.getPastBudgets()
            
            await calculateAllAnalytics(transactions: transactions, budgets: budgets)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func calculateAllAnalytics(transactions: [Transaction], budgets: [Budget]) async {
        // Aylık Analiz
        monthlyAnalysis = calculateMonthlyAnalysis(transactions: transactions)
        
        // Kategori Analizi
        categoryAnalysis = calculateCategoryAnalysis(transactions: transactions)
        
        // Trend Analizi
        trendAnalysis = calculateTrendAnalysis(transactions: transactions)
        
        // Tasarruf Analizi
        savingsAnalysis = calculateSavingsAnalysis(transactions: transactions, budgets: budgets)
        
        // Tahmin Analizi
        predictionAnalysis = calculatePredictionAnalysis(transactions: transactions)
    }
    
    private func calculateMonthlyAnalysis(transactions: [Transaction]) -> MonthlyAnalysis {
        let calendar = Calendar.current
        let startOfMonth = Date().advstartOfMonth()
        let currentMonthTransactions = transactions.filter { $0.date >= startOfMonth }
        
        let totalIncome = currentMonthTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let totalExpense = currentMonthTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        let netAmount = totalIncome - totalExpense
        let savingsRate = totalIncome > 0 ? ((totalIncome - totalExpense) / totalIncome) * 100 : 0
        
        return MonthlyAnalysis(
            totalIncome: totalIncome,
            totalExpense: totalExpense,
            netAmount: netAmount,
            savingsRate: savingsRate,
            transactionCount: currentMonthTransactions.count,
            averageTransactionAmount: totalExpense / Double(max(currentMonthTransactions.count, 1))
        )
    }
    
    private func calculateCategoryAnalysis(transactions: [Transaction]) -> [CategoryAnalysis] {
        let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
        let recentTransactions = transactions.filter { $0.date >= threeMonthsAgo && $0.type == .expense }
        
        var categoryAnalysis: [Category: CategoryAnalysis] = [:]
        
        for category in Category.expenseCategories {
            let categoryTransactions = recentTransactions.filter { $0.category == category }
            let totalAmount = categoryTransactions.reduce(0) { $0 + $1.amount }
            let averageAmount = totalAmount / 3 // 3 aylık ortalama
            
            // Trend hesaplama
            let monthlyAmounts = Dictionary(grouping: categoryTransactions) {
                $0.date.startOfMonth()
            }.mapValues { transactions in
                transactions.reduce(0) { $0 + $1.amount }
            }
            
            let sortedMonths = monthlyAmounts.keys.sorted()
            let trend: TrendDirection
            if sortedMonths.count >= 2 {
                let lastMonth = monthlyAmounts[sortedMonths.last!] ?? 0
                let previousMonth = monthlyAmounts[sortedMonths.dropLast().last!] ?? 0
                trend = lastMonth > previousMonth ? .increasing : .decreasing
            } else {
                trend = .stable
            }
            
            categoryAnalysis[category] = CategoryAnalysis(
                category: category,
                totalAmount: totalAmount,
                averageAmount: averageAmount,
                transactionCount: categoryTransactions.count,
                trend: trend,
                largestTransaction: categoryTransactions.max(by: { $0.amount < $1.amount })
            )
        }
        
        return Array(categoryAnalysis.values).sorted { $0.totalAmount > $1.totalAmount }
    }
    
    private func calculateTrendAnalysis(transactions: [Transaction]) -> TrendAnalysis {
        let calendar = Calendar.current
        let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        
        let recentTransactions = transactions.filter { $0.date >= sixMonthsAgo }
        let monthlyData = Dictionary(grouping: recentTransactions) {
            calendar.advstartOfMonth(for: $0.date)
        }.mapValues { transactions -> (income: Double, expense: Double) in
            let income = transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let expense = transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            return (income, expense)
        }
        
        let sortedMonths = monthlyData.keys.sorted()
        let monthlyTrends = sortedMonths.map { month in
            let data = monthlyData[month] ?? (0, 0)
            return MonthlyTrendData(
                month: month,
                income: data.income,
                expense: data.expense,
                savings: data.income - data.expense
            )
        }
        
        return TrendAnalysis(
            monthlyTrends: monthlyTrends,
            averageIncome: monthlyTrends.map(\.income).reduce(0, +) / Double(monthlyTrends.count),
            averageExpense: monthlyTrends.map(\.expense).reduce(0, +) / Double(monthlyTrends.count),
            averageSavings: monthlyTrends.map(\.savings).reduce(0, +) / Double(monthlyTrends.count)
        )
    }
    
    private func calculateSavingsAnalysis(transactions: [Transaction], budgets: [Budget]) -> SavingsAnalysis {
        let calendar = Calendar.current
        let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        
        let yearlyTransactions = transactions.filter { $0.date >= oneYearAgo }
        let monthlyData = Dictionary(grouping: yearlyTransactions) {
            calendar.advstartOfMonth(for: $0.date)
        }
        
        var monthlySavings: [(month: Date, amount: Double)] = []
        var totalSavings: Double = 0
        
        for (month, transactions) in monthlyData {
            let income = transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let expense = transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            let savings = income - expense
            totalSavings += savings
            monthlySavings.append((month: month, amount: savings))
        }
        
        let averageMonthlySavings = totalSavings / Double(monthlySavings.count)
        let projectedAnnualSavings = averageMonthlySavings * 12
        
        return SavingsAnalysis(
            totalSavings: totalSavings,
            averageMonthlySavings: averageMonthlySavings,
            projectedAnnualSavings: projectedAnnualSavings,
            monthlySavingsHistory: monthlySavings.sorted { $0.month < $1.month }
        )
    }
    
    private func calculatePredictionAnalysis(transactions: [Transaction]) -> [PredictionAnalysis] {
        var predictions: [PredictionAnalysis] = []
        let calendar = Calendar.current
        
        for category in Category.expenseCategories {
            let categoryTransactions = transactions.filter { $0.category == category && $0.type == .expense }
            let monthlyData = Dictionary(grouping: categoryTransactions) {
                calendar.advstartOfMonth(for: $0.date)
            }.mapValues { transactions in
                transactions.reduce(0) { $0 + $1.amount }
            }
            
            let amounts = Array(monthlyData.values)
            guard !amounts.isEmpty else { continue }
            
            let average = amounts.reduce(0, +) / Double(amounts.count)
            let variance = amounts.map { pow($0 - average, 2) }.reduce(0, +) / Double(amounts.count)
            let standardDeviation = sqrt(variance)
            
            let predictedAmount = average * 1.1 // %10 artış tahmini
            let confidence = calculateConfidence(
                standardDeviation: standardDeviation,
                average: average,
                sampleCount: amounts.count
            )
            
            predictions.append(PredictionAnalysis(
                category: category,
                predictedAmount: predictedAmount,
                confidence: confidence,
                historicalAverage: average,
                standardDeviation: standardDeviation
            ))
        }
        
        return predictions.sorted { $0.predictedAmount > $1.predictedAmount }
    }
    
    private func calculateConfidence(standardDeviation: Double, average: Double, sampleCount: Int) -> Double {
        guard average > 0 else { return 0 }
        let coefficientOfVariation = standardDeviation / average
        let sampleSizeFactor = min(Double(sampleCount) / 12.0, 1.0) // 12 ay için normalize
        
        let baseConfidence = 1.0 - min(coefficientOfVariation, 1.0)
        return baseConfidence * sampleSizeFactor
    }
}

// MARK: - Analysis Models
struct MonthlyAnalysis {
    let totalIncome: Double
    let totalExpense: Double
    let netAmount: Double
    let savingsRate: Double
    let transactionCount: Int
    let averageTransactionAmount: Double
}

struct CategoryAnalysis {
    let category: Category
    let totalAmount: Double
    let averageAmount: Double
    let transactionCount: Int
    let trend: TrendDirection
    let largestTransaction: Transaction?
}

struct TrendAnalysis {
    let monthlyTrends: [MonthlyTrendData]
    let averageIncome: Double
    let averageExpense: Double
    let averageSavings: Double
}

struct MonthlyTrendData {
    let month: Date
    let income: Double
    let expense: Double
    let savings: Double
}

struct SavingsAnalysis {
    let totalSavings: Double
    let averageMonthlySavings: Double
    let projectedAnnualSavings: Double
    let monthlySavingsHistory: [(month: Date, amount: Double)]
}

struct PredictionAnalysis {
    let category: Category
    let predictedAmount: Double
    let confidence: Double
    let historicalAverage: Double
    let standardDeviation: Double
}

enum TrendDirection {
    case increasing
    case decreasing
    case stable
}

// MARK: - Date Extensions
extension Date {
    func advstartOfMonth() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }
    
    func advendOfMonth() -> Date {
        let calendar = Calendar.current
        guard let startOfNextMonth = calendar.date(byAdding: DateComponents(month: 1), to: self.startOfMonth()) else {
            return self
        }
        return calendar.date(byAdding: DateComponents(second: -1), to: startOfNextMonth) ?? self
    }
}

// MARK: - Calendar Extensions
extension Calendar {
    func advstartOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
    
    func advendOfMonth(for date: Date) -> Date {
        guard let startOfNextMonth = self.date(byAdding: DateComponents(month: 1), to: date.startOfMonth()) else {
            return date
        }
        return self.date(byAdding: DateComponents(second: -1), to: startOfNextMonth) ?? date
    }
}

