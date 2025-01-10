import Foundation
import SwiftUI

enum Category: String, CaseIterable, Codable {
    // Gelir Kategorileri
    case maas = "Maaş"
    case kira = "Kira Geliri"
    case yatirim = "Yatırım Geliri"
    case faiz = "Faiz Geliri"
    case ikramiye = "İkramiye/Prim"
    case emekliMaasi = "Emekli Maaşı"
    case serbest = "Serbest Meslek"
    case digerGelir = "Diğer Gelir"
    
    // Gider Kategorileri
    case market = "Market"
    case ulasim = "Ulaşım"
    case faturalar = "Faturalar"
    case kiraGider = "Kira Gideri"
    case giyim = "Giyim"
    case eglence = "Eğlence"
    case saglik = "Sağlık"
    case egitim = "Eğitim"
    case restoran = "Restoran"
    case spor = "Spor"
    case teknoloji = "Teknoloji"
    case tatil = "Tatil"
    case bakim = "Bakım"
    case hediyelik = "Hediyelik"
    case ev = "Ev"
    case sigorta = "Sigorta"
    case aidat = "Aidat"
    case digerGider = "Diğer Gider"
    
    static var incomeCategories: [Category] {
        [.maas, .kira, .yatirim, .faiz, .ikramiye, .emekliMaasi, .serbest, .digerGelir]
    }
    
    static var expenseCategories: [Category] {
        [.market, .ulasim, .faturalar, .kiraGider, .giyim, .eglence, .saglik, 
         .egitim, .restoran, .spor, .teknoloji, .tatil, .bakim, .hediyelik, 
         .ev, .sigorta, .aidat, .digerGider]
    }
    
    var icon: String {
        switch self {
        case .maas: return "dollarsign.circle"
        case .kira: return "house"
        case .yatirim: return "chart.line.uptrend.xyaxis"
        case .faiz: return "percent"
        case .ikramiye: return "gift"
        case .emekliMaasi: return "person.crop.circle"
        case .serbest: return "briefcase"
        case .digerGelir: return "plus.circle"
            
        case .market: return "cart"
        case .ulasim: return "car"
        case .faturalar: return "doc.text"
        case .kiraGider: return "house.fill"
        case .giyim: return "tshirt"
        case .eglence: return "film"
        case .saglik: return "heart"
        case .egitim: return "book"
        case .restoran: return "fork.knife"
        case .spor: return "figure.run"
        case .teknoloji: return "laptopcomputer"
        case .tatil: return "airplane"
        case .bakim: return "scissors"
        case .hediyelik: return "gift.fill"
        case .ev: return "house.lodge"
        case .sigorta: return "checkmark.shield"
        case .aidat: return "building.2"
        case .digerGider: return "ellipsis.circle"
        }
    }
	
	var localizedName: String {
		switch self {
		case .maas: return "Maaş".localized
		case .kira: return "Kira Geliri".localized
		case .yatirim: return "Yatırım Geliri".localized
		case .faiz: return "Faiz Geliri".localized
		case .ikramiye: return "İkramiye/Prim".localized
		case .emekliMaasi: return "Emekli Maaşı".localized
		case .serbest: return "Serbest Meslek".localized
		case .digerGelir: return "Diğer Gelir".localized
			
		case .market: return "Market".localized
		case .ulasim: return "Ulaşım".localized
		case .faturalar: return "Faturalar".localized
		case .kiraGider: return "Kira Gideri".localized
		case .giyim: return "Giyim".localized
		case .eglence: return "Eğlence".localized
		case .saglik: return "Sağlık".localized
		case .egitim: return "Eğitim".localized
		case .restoran: return "Restoran".localized
		case .spor: return "Spor".localized
		case .teknoloji: return "Teknoloji".localized
		case .tatil: return "Tatil".localized
		case .bakim: return "Bakım".localized
		case .hediyelik: return "Hediyelik".localized
		case .ev: return "Ev".localized
		case .sigorta: return "Sigorta".localized
		case .aidat: return "Aidat".localized
		case .digerGider: return "Diğer Gider".localized
		}
	}
	
	
    
    var color: Color {
        switch self {
        // Gelir Kategorileri
        case .maas: return .mint
        case .kira: return .teal
        case .yatirim: return .green
        case .faiz: return .cyan
        case .ikramiye: return .indigo
        case .emekliMaasi: return .blue
        case .serbest: return .purple
        case .digerGelir: return .gray
            
        // Gider Kategorileri
        case .market: return .blue
        case .ulasim: return .orange
        case .faturalar: return .red
        case .kiraGider: return .brown
        case .giyim: return .purple
        case .eglence: return .pink
        case .saglik: return .green
        case .egitim: return .indigo
        case .restoran: return .orange
        case .spor: return .mint
        case .teknoloji: return .blue
        case .tatil: return .cyan
        case .bakim: return .pink
        case .hediyelik: return .red
        case .ev: return .brown
        case .sigorta: return .teal
        case .aidat: return .purple
        case .digerGider: return .gray
        }
    }
} 
