import Foundation

struct SubscriptionInfo {
    let isActive: Bool
    let planName: String
    let endDate: Date?
    let startDate: Date?
    let price: Double
    let billingPeriod: BillingPeriod
    
    enum BillingPeriod: String {
        case monthly = "aylık"
        case yearly = "yıllık"
        case lifetime = "tek seferlik"
        
        var label: String {
            switch self {
            case .monthly: return "Aylık Ücret"
            case .yearly: return "Yıllık Ücret"
            case .lifetime: return "Ücret"
            }
        }
    }
    
    static let free = SubscriptionInfo(
        isActive: false,
        planName: "Ücretsiz",
        endDate: nil,
        startDate: nil,
        price: 0.0,
        billingPeriod: .monthly
    )
} 
