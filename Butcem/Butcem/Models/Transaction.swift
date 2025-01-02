import Foundation
import FirebaseFirestore

struct Transaction: Identifiable, Codable {
    var id: String?
    let userId: String
    let amount: Double
    let category: Category
    let type: TransactionType
    let date: Date
    let note: String?
    let createdAt: Date?
    
    var documentId: String {
        id ?? UUID().uuidString
    }
    
    // Kopyalama için yardımcı metod
    func copy(with type: TransactionType? = nil) -> Transaction {
        Transaction(
            id: self.id,
            userId: self.userId,
            amount: self.amount,
            category: self.category,
            type: type ?? self.type,
            date: self.date,
            note: self.note,
            createdAt: self.createdAt
        )
    }
    
    // Firestore için dictionary dönüşümü
    func asDictionary() -> [String: Any] {
        var data: [String: Any] = [
            "userId": userId,
            "amount": amount,
            "category": category.rawValue,
            "type": type.rawValue,
            "date": date,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        if let note = note {
            data["note"] = note
        }
        
        return data
    }
    
    // Formatlı gösterimler
    var formattedAmount: String {
        let prefix = type == .expense ? "- " : "+ "
        return prefix + amount.currencyFormat()
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case amount
        case category
        case type
        case date
        case note
        case createdAt
    }
} 
