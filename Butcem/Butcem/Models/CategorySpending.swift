import Foundation

struct CategorySpending {
    let category: Category
    let amount: Double
    let totalAmount: Double
    
    var percentage: Double {
        totalAmount > 0 ? (amount / totalAmount) * 100 : 0
    }
    
    init(category: Category, amount: Double, totalAmount: Double) {
        self.category = category
        self.amount = amount
        self.totalAmount = totalAmount
    }
}
