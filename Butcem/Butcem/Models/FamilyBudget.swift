import Foundation
import FirebaseFirestore

struct FamilyBudget: Identifiable, Codable {
    var id: String?
    let creatorId: String
    var name: String
    var members: [FamilyMember]
    var categoryLimits: [CategoryBudget]
    var totalBudget: Double
    let createdAt: Date?
    var month: Date
    var spentAmount: Double
    
    var documentId: String {
        id ?? UUID().uuidString
    }
    
    struct FamilyMember: Codable, Identifiable {
        var id: String
        var name: String
        var email: String
        var role: MemberRole
        var spentAmount: Double
        
        enum MemberRole: String, Codable {
            case admin
            case member
            
            var canEditBudget: Bool {
                self == .admin
            }
        }
    }
    
    // Firestore için kodlama anahtarları
    enum CodingKeys: String, CodingKey {
        case id
        case creatorId
        case name
        case members
        case categoryLimits
        case totalBudget
        case createdAt
        case month
        case spentAmount
    }
    
    // Firestore'a kaydetmek için Dictionary'e çevir
    func asDictionary() -> [String: Any] {
        [
            "creatorId": creatorId,
            "name": name,
            "members": members.map { member in [
                "id": member.id,
                "name": member.name,
                "email": member.email,
                "role": member.role.rawValue,
                "spentAmount": member.spentAmount
            ]},
            "categoryLimits": categoryLimits.map { limit in [
                "id": limit.id,
                "category": limit.category.rawValue,
                "limit": limit.limit,
                "spent": limit.spent
            ]},
            "totalBudget": totalBudget,
            "createdAt": FieldValue.serverTimestamp(),
            "month": month,
            "spentAmount": spentAmount
        ]
    }
}

// Firestore Timestamp dönüşümü için extension
extension FamilyBudget {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(String.self, forKey: .id)
        creatorId = try container.decode(String.self, forKey: .creatorId)
        name = try container.decode(String.self, forKey: .name)
        members = try container.decode([FamilyMember].self, forKey: .members)
        categoryLimits = try container.decode([CategoryBudget].self, forKey: .categoryLimits)
        totalBudget = try container.decode(Double.self, forKey: .totalBudget)
        
        // Timestamp'i Date'e çevir
        if let timestamp = try container.decodeIfPresent(Timestamp.self, forKey: .createdAt) {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = nil
        }
        
        if let timestamp = try container.decodeIfPresent(Timestamp.self, forKey: .month) {
            month = timestamp.dateValue()
        } else {
            month = Date()
        }
        
        spentAmount = try container.decode(Double.self, forKey: .spentAmount)
    }
} 