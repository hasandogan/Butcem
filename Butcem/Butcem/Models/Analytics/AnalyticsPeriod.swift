import Foundation

enum AnalyticsPeriod: String, CaseIterable {
    case week = "Hafta"
    case month = "Ay"
    case quarter = "Çeyrek"
    case year = "Yıl"
    
    var title: String {
        rawValue
    }
    
    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        case .year: return 365
        }
    }
    
    var monthCount: Int {
        switch self {
        case .week: return 1
        case .month: return 3
        case .quarter: return 6
        case .year: return 12
        }
    }
} 