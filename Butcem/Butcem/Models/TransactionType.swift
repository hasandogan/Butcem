import Foundation

enum TransactionType: String, CaseIterable, Codable {
    case income = "Gelir"
    case expense = "Gider"
    case all = "Tümü"
	
	var localizedName: String {
		switch self {
		case .income: return "Gelir".localized
		case .expense: return "Gider".localized
		case .all: return "Tümü".localized
		}
	}
}


