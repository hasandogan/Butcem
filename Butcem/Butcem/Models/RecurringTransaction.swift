import Foundation
import FirebaseFirestore

struct RecurringTransaction: Identifiable, Codable {
    var id: String?
    let userId: String
    let amount: Double
    let category: Category
    let type: TransactionType
    let note: String?
    let frequency: RecurringFrequency
    let startDate: Date
    let endDate: Date?
    let lastProcessed: Date?
    let createdAt: Date?
    
    var documentId: String {
        id ?? UUID().uuidString
    }
    
    func asDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "userId": userId,
            "amount": amount,
            "category": category.rawValue,
            "type": type.rawValue,
            "frequency": frequency.rawValue,
            "startDate": startDate,
            "createdAt": createdAt ?? Date()
        ]
        
        // Opsiyonel alanları ekle
        if let note = note {
            dict["note"] = note
        }
        if let endDate = endDate {
            dict["endDate"] = endDate
        }
        if let lastProcessed = lastProcessed {
            dict["lastProcessed"] = lastProcessed
        }
        
        return dict
    }
}

enum RecurringFrequency: String, Codable, CaseIterable {
    case daily = "Günlük"
    case weekly = "Haftalık"
    case monthly = "Aylık"
    case yearly = "Yıllık"
    
    var calendarComponent: Calendar.Component {
        switch self {
        case .daily: return .day
        case .weekly: return .weekOfYear
        case .monthly: return .month
        case .yearly: return .year
        }
    }
    
    var nextDate: Date {
        Calendar.current.date(
            byAdding: calendarComponent,
            value: 1,
            to: Date()
        ) ?? Date()
    }
} 