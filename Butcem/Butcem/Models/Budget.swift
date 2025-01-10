import SwiftUI
import FirebaseFirestore

struct Budget: Identifiable, Codable {
    var id: String?
    let userId: String
    let amount: Double
    var categoryLimits: [CategoryBudget]
    let createdAt: Date?
	let month: Date

    // Yeni özellikler için varsayılan değerler
    var warningThreshold: Double
    var dangerThreshold: Double
    var notificationsEnabled: Bool
    var spentAmount: Double
    
    var documentId: String {
        id ?? "\(userId)_\(month.timeIntervalSince1970)"
    }
    
    var remainingAmount: Double { amount - spentAmount }
    var spentPercentage: Double { (spentAmount / amount) * 100 }
    
    var status: BudgetStatus {
        let percentage = spentAmount / amount
        switch percentage {
        case 0..<0.5: return .safe
        case 0.5..<0.75: return .quarterWarning
        case 0.75..<0.85: return .halfWarning
        case 0.85..<1.0: return .criticalWarning
        default: return .danger
        }
    }
    
    var totalSpent: Double {
        categoryLimits.reduce(0) { $0 + $1.spent }
    }
    
    // CodingKeys ve init ekleyelim
    enum CodingKeys: String, CodingKey {
        case id, userId, amount,  categoryLimits, createdAt ,month
        case warningThreshold, dangerThreshold, notificationsEnabled, spentAmount
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Zorunlu alanları decode et
        id = try container.decodeIfPresent(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        amount = try container.decode(Double.self, forKey: .amount)
        categoryLimits = try container.decode([CategoryBudget].self, forKey: .categoryLimits)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
		month = try container.decode(Date.self, forKey: .month)

        // Opsiyonel alanları varsayılan değerlerle decode et
        warningThreshold = try container.decodeIfPresent(Double.self, forKey: .warningThreshold) ?? 0.7
        dangerThreshold = try container.decodeIfPresent(Double.self, forKey: .dangerThreshold) ?? 0.9
        notificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .notificationsEnabled) ?? true
        spentAmount = try container.decodeIfPresent(Double.self, forKey: .spentAmount) ?? 0.0
    }
    
    init(id: String? = nil,
         userId: String,
         amount: Double,
         categoryLimits: [CategoryBudget],
         month: Date,
         createdAt: Date? = nil,
         warningThreshold: Double = 0.7,
         dangerThreshold: Double = 0.9,
         notificationsEnabled: Bool = true,
         spentAmount: Double? = nil) {
        self.id = id
        self.userId = userId
        self.amount = amount
        self.categoryLimits = categoryLimits
        self.month = month
        self.createdAt = createdAt
        self.warningThreshold = warningThreshold
        self.dangerThreshold = dangerThreshold
        self.notificationsEnabled = notificationsEnabled
        self.spentAmount = spentAmount ?? categoryLimits.reduce(0) { $0 + $1.spent }
    }
    
    var isCurrentMonth: Bool {
        Calendar.current.isDate(month, equalTo: Date(), toGranularity: .month)
    }
    
    var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: month)
    }
    
    func asDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "userId": userId,
            "amount": amount,
            "categoryLimits": categoryLimits.map { [
                "id": $0.id,
                "category": $0.category.rawValue,
                "limit": $0.limit,
                "spent": $0.spent
            ] },
			"month": month,
            "notificationsEnabled": notificationsEnabled,
            "warningThreshold": warningThreshold,
            "dangerThreshold": dangerThreshold,
            "spentAmount": spentAmount
        ]
        
        if let id = id {
            dict["id"] = id
        }
        
        if let createdAt = createdAt {
            dict["createdAt"] = createdAt
        } else {
            dict["createdAt"] = FieldValue.serverTimestamp()
        }
        
        return dict
    }
}

struct CategoryBudget: Identifiable, Codable {
    let id: String
    let category: Category
    let limit: Double
    var spent: Double = 0
    
    var remainingAmount: Double { limit - spent }
    var spentPercentage: Double { (spent / limit) * 100 }
    var isOverBudget: Bool { spent > limit }
	
	func asDictionary() -> [String: Any] {
		return [
			"id": id,
			"category": category.rawValue,
			"limit": limit,
			"spent": spent
		]
	}
    var status: BudgetStatus {
        let percentage = spent / limit
        switch percentage {
        case 0..<0.5: return .safe
        case 0.5..<0.75: return .quarterWarning
        case 0.75..<0.85: return .halfWarning
        case 0.85..<1.0: return .criticalWarning
        default: return .danger
        }
    }
}

enum BudgetStatus {
    case safe
    case quarterWarning    // %50
    case halfWarning      // %75
    case criticalWarning  // %85-90
    case danger           // %100+
    
    var color: Color {
        switch self {
        case .safe: return .green
        case .quarterWarning: return .blue
        case .halfWarning: return .yellow
        case .criticalWarning: return .orange
        case .danger: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .safe: return "checkmark.circle.fill"
        case .quarterWarning: return "info.circle.fill"
        case .halfWarning: return "exclamationmark.circle.fill"
        case .criticalWarning: return "exclamationmark.triangle.fill"
        case .danger: return "xmark.circle.fill"
        }
    }
    
    var message: String {
        switch self {
        case .safe: return "Bütçeniz kontrol altında"
        case .quarterWarning: return "Bütçenizin yarısına ulaştınız"
        case .halfWarning: return "Bütçenizin %75'ine ulaştınız"
        case .criticalWarning: return "Dikkat! Bütçe limitine yaklaşıyorsunuz"
        case .danger: return "Bütçe limitini aştınız!"
        }
    }
} 
