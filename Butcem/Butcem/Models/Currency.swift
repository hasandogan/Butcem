import Foundation

enum Currency {
    static var current: String {
        let languageCode = Bundle.main.preferredLocalizations.first ?? "en"
        return languageCode == "tr" ? "TRY" : "USD"
    }
    
    static var symbol: String {
        let languageCode = Bundle.main.preferredLocalizations.first ?? "en"
        return languageCode == "tr" ? "₺" : "$"
    }
    
    static var locale: Locale {
        let languageCode = Bundle.main.preferredLocalizations.first ?? "en"
        return Locale(identifier: languageCode == "tr" ? "tr_TR" : "en_US")
    }
} 
