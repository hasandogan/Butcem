import Foundation

struct AnalyticsData {
    let totalIncome: Double
    let totalExpense: Double
    let netSavings: Double
    let categoryAnalytics: [CategoryAnalytics]
    let monthlyComparison: [MonthlyComparison]
    let savingsProgress: [SavingsProgress]
    
    var savingsRate: Double {
        guard totalIncome > 0 else { return 0 }
        return (netSavings / totalIncome) * 100
    }
    
    // Boş başlangıç verisi
    static let empty = AnalyticsData(
        totalIncome: 0,
        totalExpense: 0,
        netSavings: 0,
        categoryAnalytics: [],
        monthlyComparison: [],
        savingsProgress: []
    )
}

struct CategoryAnalytics: Identifiable {
    let id = UUID()
    let category: Category
    let amount: Double
    let percentage: Double
}

struct MonthlyComparison: Identifiable {
    let id: UUID
    let month: Date
    let income: Double
    let expense: Double
    let savings: Double
}

struct SavingsProgress: Identifiable {
    let id = UUID()
    let currentAmount: Double
    let percentage: Double
} 
