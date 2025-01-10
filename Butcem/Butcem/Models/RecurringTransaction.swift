import Foundation
import FirebaseFirestore

struct RecurringTransaction: Identifiable, Codable {
    var id: String?
    let userId: String
    let title: String
    let amount: Double
    let category: Category
    let type: TransactionType
    let frequency: RecurringFrequency
    let startDate: Date
    let endDate: Date?
    var lastProcessed: Date?
    var nextDueDate: Date?
    let note: String?
    let createdAt: Date?
    let isActive: Bool
    
    var documentId: String {
        id ?? UUID().uuidString
    }
    
    // Bir sonraki işlem tarihini hesapla
    var nextProcessDate: Date? {
        // Eğer nextDueDate varsa ve gelecekte ise onu kullan
        if let nextDue = nextDueDate, nextDue > Date() {
            return nextDue
        }
        
        guard isActive else { return nil }
        
        let calendar = Calendar.current
        let baseDate = lastProcessed ?? startDate
        
        // Eğer bitiş tarihi varsa ve geçilmişse nil döndür
        if let endDate = endDate, baseDate > endDate {
            return nil
        }
        
        // Bir sonraki tarihi hesapla
        let nextDate: Date?
        switch frequency {
        case .daily:
            nextDate = calendar.date(byAdding: .day, value: 1, to: baseDate)
        case .weekly:
            nextDate = calendar.date(byAdding: .weekOfYear, value: 1, to: baseDate)
        case .monthly:
            nextDate = calendar.date(byAdding: .month, value: 1, to: baseDate)
        case .yearly:
            nextDate = calendar.date(byAdding: .year, value: 1, to: baseDate)
        }
        
        return nextDate
    }
    
    func asDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "userId": userId,
            "title": title,
            "amount": amount,
            "category": category.rawValue,
            "type": type.rawValue,
            "frequency": frequency.rawValue,
            "startDate": startDate,
            "isActive": isActive
        ]
        
        // ID varsa ekle
        if let id = id {
            dict["id"] = id
        }
        
        // Opsiyonel alanları ekle
        if let endDate = endDate {
            dict["endDate"] = endDate
        }
        
        if let lastProcessed = lastProcessed {
            dict["lastProcessed"] = Timestamp(date: lastProcessed)
        }
        
        if let nextDueDate = nextDueDate {
            dict["nextDueDate"] = Timestamp(date: nextDueDate)
        }
        
        if let note = note {
            dict["note"] = note
        }
        
        if let createdAt = createdAt {
            dict["createdAt"] = Timestamp(date: createdAt)
        }
        
        print("📝 Dictionary created for transaction:")
        print(dict)
        
        return dict
    }
}

enum RecurringFrequency: String, Codable, CaseIterable {
    case daily = "Günlük"
    case weekly = "Haftalık"
    case monthly = "Aylık"
    case yearly = "Yıllık"
    
    var description: String {
        switch self {
        case .daily: return "Günlük".localized
        case .weekly: return "Haftalık".localized
        case .monthly: return "Aylık".localized
        case .yearly: return "Yıllık".localized
        }
    }
    
    var nextDate: Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: now) ?? now
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: now) ?? now
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: now) ?? now
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: now) ?? now
        }
    }
}
