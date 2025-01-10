import Foundation
import FirebaseFirestore

struct FamilyBudget: Identifiable, Codable {
    var id: String?
    let creatorId: String
    var name: String
    var members: [FamilyMember]
    var categoryLimits: [FamilyCategoryBudget]
    var totalBudget: Double
    let createdAt: Date?
    var month: Date
    var spentAmount: Double
    let sharingCode: String
    
    var documentId: String {
        id ?? UUID().uuidString
    }
    
    init(creatorId: String, name: String, members: [FamilyMember], categoryLimits: [FamilyCategoryBudget], totalBudget: Double, createdAt: Date?, month: Date, spentAmount: Double) {
        self.creatorId = creatorId
        self.name = name
        self.members = members
        self.categoryLimits = categoryLimits
        self.totalBudget = totalBudget
        self.createdAt = createdAt
        self.month = month
        self.spentAmount = spentAmount
        self.sharingCode = FamilyBudget.generateSharingCode()
    }
    
    static func generateSharingCode() -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let randomString = String((0..<6).map { _ in letters.randomElement()! })
        return randomString
    }
    
    struct FamilyMember: Identifiable, Codable {
        let id: String
        var name: String
        let role: MemberRole
        var spentAmount: Double
        
        func asDictionary() -> [String: Any] {
            [
                "id": id,
                "name": name,
                "role": role.rawValue,
                "spentAmount": spentAmount
            ]
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
        case sharingCode
    }
    
    // Firestore'a kaydetmek için Dictionary'e çevir
    func asDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "creatorId": creatorId,
            "name": name,
            "totalBudget": totalBudget,
            "spentAmount": spentAmount,
            "month": month,
            "members": members.map { $0.asDictionary() },
            "categoryLimits": categoryLimits.map { $0.asDictionary() },
            "sharingCode": sharingCode
        ]
        
        if let id = id {
            dict["id"] = id
        }
        
        if let createdAt = createdAt {
            dict["createdAt"] = Timestamp(date: createdAt)
        }
        
        return dict
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
        categoryLimits = try container.decode([FamilyCategoryBudget].self, forKey: .categoryLimits)
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
        
        // Paylaşım kodunu decode et veya yeni oluştur
        if let code = try container.decodeIfPresent(String.self, forKey: .sharingCode) {
            sharingCode = code
        } else {
            sharingCode = FamilyBudget.generateSharingCode()
        }
    }
}


enum MemberRole: String, Codable {
    case admin = "admin"
    case member = "member"
} 
