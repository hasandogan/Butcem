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
    case diger = "Diğer Gelir"
    
    // Gider Kategorileri
    case market = "Market"
    case ulasim = "Ulaşım"
    case faturalar = "Faturalar"
    case kiraGider = "Kira"
    case giyim = "Giyim"
    case eglence = "Eğlence"
    case saglik = "Sağlık"
    case egitim = "Eğitim"
    case restoran = "Restoran/Cafe"
    case spor = "Spor"
    case teknoloji = "Teknoloji"
    case tatil = "Tatil"
    case bakim = "Bakım/Kozmetik"
    case hediyelik = "Hediyeler"
    case ev = "Ev Eşyaları"
    case sigorta = "Sigorta"
    case aidat = "Aidat"
    case digerGider = "Diğer Gider"
    
    static var incomeCategories: [Category] {
        [.maas, .kira, .yatirim, .faiz, .ikramiye, .emekliMaasi, .serbest, .diger]
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
        case .diger: return "plus.circle"
            
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
        case .diger: return .gray
            
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