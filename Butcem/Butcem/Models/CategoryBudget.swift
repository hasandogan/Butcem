import SwiftUI

struct FamilyCategoryBudget: Identifiable, Codable {
    let id: String
    let category: FamilyBudgetCategory
    var limit: Double
    var spent: Double
    
	
	func asDictionary() -> [String: Any] {
		[
			"id": id,
			"category": category.rawValue,
			"limit": limit,
			"spent": spent
		]
	}
	
    var spentPercentage: Double {
        guard limit > 0 else { return 0 }
        return (spent / limit) * 100
    }
    
    var remainingAmount: Double {
        limit - spent
    }
    
    var isOverBudget: Bool {
        spent > limit
    }
} 
