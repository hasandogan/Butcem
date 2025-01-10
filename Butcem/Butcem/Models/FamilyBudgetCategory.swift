import Foundation
import SwiftUI
enum FamilyBudgetCategory: String, CaseIterable, Codable {
    // Ev Giderleri
    case kira = "Kira"
    case aidat = "Aidat"
    case elektrik = "Elektrik"
    case su = "Su"
    case dogalgaz = "Doğalgaz"
    case internet = "İnternet"
    
    // Mutfak Giderleri
    case market = "Market"
    case gida = "Gıda"
    
    // Ulaşım
    case yakit = "Yakıt"
    case topluTasima = "Toplu Taşıma"
    
    // Eğitim
    case okul = "Okul"
    case kurs = "Kurs"
    case kitap = "Kitap"
    
    // Sağlık
    case saglik = "Sağlık"
    case ilac = "İlaç"
    
    // Diğer
    case giyim = "Giyim"
    case eglence = "Eğlence"
    case diger = "Diğer"
    
    var icon: String {
        switch self {
        case .kira: return "house.fill"
        case .aidat: return "building.2.fill"
        case .elektrik: return "bolt.fill"
        case .su: return "drop.fill"
        case .dogalgaz: return "flame.fill"
        case .internet: return "wifi"
        case .market: return "cart.fill"
        case .gida: return "fork.knife"
        case .yakit: return "fuelpump.fill"
        case .topluTasima: return "bus.fill"
        case .okul: return "graduationcap.fill"
        case .kurs: return "book.fill"
        case .kitap: return "books.vertical.fill"
        case .saglik: return "cross.case.fill"
        case .ilac: return "pills.fill"
        case .giyim: return "tshirt.fill"
        case .eglence: return "party.popper.fill"
        case .diger: return "ellipsis.circle.fill"
        }
    }
	
	var localizedName: String {
		switch self {
		case .kira: return "Kira".localized
		case .aidat: return "Aidat".localized
		case .elektrik: return "Elektirik".localized
		case .su: return "Su".localized
		case .dogalgaz: return "Doğal Gaz".localized
		case .internet: return "İnternet".localized
		case .market: return "Market".localized
		case .gida: return "Gıda".localized
		case .yakit: return "Yakıt".localized
		case .topluTasima: return "Toplu Taşıma".localized
		case .okul: return "Okul".localized
		case .kurs: return "Kurs".localized
		case .kitap: return "Kitap".localized
		case .saglik: return "Sağlık".localized
		case .ilac: return "İlaç".localized
		case .giyim: return "Giyim".localized
		case .eglence: return "Eğlence".localized
		case .diger: return "Diğer".localized
		}
	}
    
    var color: Color {
        switch self {
        case .kira, .aidat: return .brown
        case .elektrik, .su, .dogalgaz, .internet: return .blue
        case .market, .gida: return .green
        case .yakit, .topluTasima: return .orange
        case .okul, .kurs, .kitap: return .purple
        case .saglik, .ilac: return .red
        case .giyim: return .pink
        case .eglence: return .yellow
        case .diger: return .gray
        }
    }
    
    func toPersonalCategory() -> Category {
        switch self {
        case .kira: return .kiraGider
        case .aidat: return .aidat
        case .elektrik, .su, .dogalgaz, .internet: return .faturalar
        case .market, .gida: return .market
        case .yakit, .topluTasima: return .ulasim
        case .okul, .kurs, .kitap: return .egitim
        case .saglik, .ilac: return .saglik
        case .giyim: return .giyim
        case .eglence: return .eglence
        case .diger: return .digerGider
        }
    }
} 
