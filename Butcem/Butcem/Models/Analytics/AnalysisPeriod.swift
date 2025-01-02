import Foundation

enum AnalysisPeriod: String, CaseIterable {
	case weekly = "Haftalık"
	case monthly = "Aylık"
	case quarterly = "3 Aylık"
	case yearly = "Yıllık"
	
	var dateComponent: Calendar.Component {
		switch self {
		case .weekly: return .weekOfYear
		case .monthly: return .month
		case .quarterly: return .quarter
		case .yearly: return .year
		}
	}
	
	var dateRange: DateComponents {
		switch self {
		case .weekly:
			return DateComponents(weekOfYear: -1)
		case .monthly:
			return DateComponents(month: -1)
		case .quarterly:
			return DateComponents(month: -3)
		case .yearly:
			return DateComponents(year: -1)
		}
	}
}
