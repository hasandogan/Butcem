import SwiftUI
import FirebaseFirestore

struct UserSettings: Codable {
    var id: String?
    let userId: String
    var billingDay: Int // 1-31 arası
    var createdAt: Date?
    
    static let defaultBillingDay = 1
    
    init(userId: String, billingDay: Int = defaultBillingDay, createdAt: Date? = nil) {
        self.userId = userId
        self.billingDay = billingDay
        self.createdAt = createdAt
    }
    
    // Firestore için dictionary dönüşümü
    func asDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "userId": userId,
            "billingDay": billingDay
        ]
        
        if let id = id {
            dict["id"] = id
        }
        
        if let createdAt = createdAt {
            dict["createdAt"] = Timestamp(date: createdAt)
        }
        
        return dict
    }
    
    var nextBillingDate: Date {
        let calendar = Calendar.current
        let now = Date()
        let currentDay = calendar.component(.day, from: now)
        
        // Eğer bugün kesim gününden önceyse bu ay, değilse gelecek ay
        if currentDay <= billingDay {
            return calendar.date(bySetting: .day, value: billingDay, of: now) ?? now
        } else {
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: now) ?? now
            return calendar.date(bySetting: .day, value: billingDay, of: nextMonth) ?? nextMonth
        }
    }
    
    struct BillingPeriod {
        let startDate: Date
        let endDate: Date
    }
    
    var currentBillingPeriod: BillingPeriod {
        let calendar = Calendar.current
        let now = Date()
        
        let currentDay = calendar.component(.day, from: now)
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        var startComponents = DateComponents()
        startComponents.year = currentYear
        startComponents.month = currentDay <= billingDay ? currentMonth - 1 : currentMonth
        startComponents.day = billingDay
        startComponents.hour = 0
        startComponents.minute = 0
        startComponents.second = 0
        
        var endComponents = DateComponents()
        endComponents.year = currentYear
        endComponents.month = currentDay <= billingDay ? currentMonth : currentMonth + 1
        endComponents.day = billingDay
        endComponents.hour = 23
        endComponents.minute = 59
        endComponents.second = 59
        
        let startDate = calendar.date(from: startComponents) ?? now
        let endDate = calendar.date(from: endComponents) ?? now
        
        return BillingPeriod(startDate: startDate, endDate: endDate)
    }
} 
