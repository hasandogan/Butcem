import Foundation
import FirebaseFirestore

struct Reminder: Identifiable, Codable, Equatable {
    var id: String?
    let userId: String
    let title: String
    let amount: Double
    let category: Category
    let type: TransactionType
    let dueDate: Date
    let frequency: ReminderFrequency
    let isActive: Bool
    let note: String?
    let createdAt: Date?
    
    var documentId: String {
        id ?? UUID().uuidString
    }
    
    enum ReminderFrequency: String, Codable, CaseIterable {
        case once = "Bir Kez"
        case daily = "Günlük"
        case weekly = "Haftalık"
        case monthly = "Aylık"
        case yearly = "Yıllık"
    }
    
    static func == (lhs: Reminder, rhs: Reminder) -> Bool {
        lhs.id == rhs.id &&
        lhs.userId == rhs.userId &&
        lhs.title == rhs.title &&
        lhs.amount == rhs.amount &&
        lhs.category == rhs.category &&
        lhs.type == rhs.type &&
        lhs.dueDate == rhs.dueDate &&
        lhs.frequency == rhs.frequency &&
        lhs.isActive == rhs.isActive &&
        lhs.note == rhs.note &&
        lhs.createdAt == rhs.createdAt
    }
    
    func asDictionary() -> [String: Any] {
        var data: [String: Any] = [
            "userId": userId,
            "title": title,
            "amount": amount,
            "category": category.rawValue,
            "type": type.rawValue,
            "dueDate": dueDate,
            "frequency": frequency.rawValue,
            "isActive": isActive
        ]
        
        if let note = note {
            data["note"] = note
        }
        
        if let createdAt = createdAt {
            data["createdAt"] = createdAt
        }
        
        return data
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "userId": userId,
            "title": title,
            "amount": amount,
            "category": category.rawValue,
            "type": type.rawValue,
            "dueDate": dueDate,
            "frequency": frequency.rawValue,
            "isActive": isActive,
            "createdAt": createdAt
        ]
        
        if let note = note {
            dict["note"] = note
        }
        
        if let id = id {
            dict["id"] = id
        }
        
        return dict
    }
} 