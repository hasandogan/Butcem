import Foundation

struct FinancialGoal: Identifiable, Codable {
    var id: String?
    let userId: String
    let title: String
    let targetAmount: Double
    let currentAmount: Double
    let deadline: Date
    let type: GoalType
    let category: GoalCategory
    let createdAt: Date
    var notes: String?
    
    var progress: Double {
        (currentAmount / targetAmount) * 100
    }
    
    var remainingAmount: Double {
        targetAmount - currentAmount
    }
    
    var remainingDays: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
    }
    
    var isCompleted: Bool {
        currentAmount >= targetAmount
    }
    
    var monthlyTargetAmount: Double {
        let months = Double(Calendar.current.dateComponents([.month], from: Date(), to: deadline).month ?? 1)
        return remainingAmount / max(months, 1)
    }
    
    var documentId: String {
        id ?? UUID().uuidString
    }
    
    // MARK: - Firestore Conversion
    func asDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "userId": userId,
            "title": title,
            "targetAmount": targetAmount,
            "currentAmount": currentAmount,
            "deadline": deadline,
            "type": type.rawValue,
            "category": category.rawValue,
            "createdAt": createdAt
        ]
        
        if let id = id {
            dict["id"] = id
        }
        
        if let notes = notes {
            dict["notes"] = notes
        }
        
        return dict
    }
}

enum GoalType: String, Codable, CaseIterable {
    case shortTerm = "Kısa Vadeli"  // 0-6 ay
    case mediumTerm = "Orta Vadeli"  // 6-12 ay
    case longTerm = "Uzun Vadeli"    // 12+ ay
    
    var maxMonths: Int {
        switch self {
        case .shortTerm: return 6
        case .mediumTerm: return 12
        case .longTerm: return 60
        }
    }
}

enum GoalCategory: String, Codable, CaseIterable {
    case savings = "Tasarruf"
    case investment = "Yatırım"
    case debt = "Borç Ödeme"
    case purchase = "Satın Alma"
    case emergency = "Acil Durum Fonu"
    case education = "Eğitim"
    case retirement = "Emeklilik"
    case travel = "Seyahat"
    case other = "Diğer"
    
    var icon: String {
        switch self {
        case .savings: return "banknote"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .debt: return "creditcard"
        case .purchase: return "cart"
        case .emergency: return "exclamationmark.shield"
        case .education: return "book"
        case .retirement: return "house"
        case .travel: return "airplane"
        case .other: return "star"
        }
    }
} 