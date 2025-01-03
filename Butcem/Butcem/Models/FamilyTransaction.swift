import Foundation
import FirebaseFirestore

struct FamilyTransaction: Identifiable, Codable {
    var id: String?
    let userId: String
    let amount: Double
	let memberName: String
    let memberEmail: String
    let category: FamilyBudgetCategory
    let date: Date
    let note: String?
    let createdAt: Date?
    
    var documentId: String {
        id ?? UUID().uuidString
    }
    
    // Firestore için dictionary dönüşümü
    func asDictionary() -> [String: Any] {
        var data: [String: Any] = [
            "userId": userId,
            "amount": amount,
            "memberName": memberName,
            "memberEmail": memberEmail,
            "category": category.rawValue,
            "date": date,
        ]
        
        if let note = note {
            data["note"] = note
        }
        
        if let createdAt = createdAt {
            data["createdAt"] = createdAt
        }
        
        return data
    }
} 
