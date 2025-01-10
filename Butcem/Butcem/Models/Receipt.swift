import Foundation

struct Receipt: Codable, Identifiable {
    let id: String
    let imageURL: String
    let date: Date
    let merchantName: String?
    let totalAmount: Double
    let items: [ReceiptItem]?
    let category: Category
    let status: ReceiptStatus
    let userId: String
    let createdAt: Date
    
    var transaction: Transaction? {
        Transaction(
            userId: userId,
            amount: totalAmount,
            category: category,
            type: .expense,
            date: date,
            note: merchantName,
            createdAt: createdAt
        )
    }
}

struct ReceiptItem: Codable, Identifiable {
    let id: String
    let name: String
    let quantity: Int
    let price: Double
    let totalPrice: Double
}

enum ReceiptStatus: String, Codable {
    case scanning
    case processing
    case completed
    case failed
} 
