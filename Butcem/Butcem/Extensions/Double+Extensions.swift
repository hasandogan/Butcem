import Foundation

extension Double {
    func currencyFormat() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        // Dil ayarına göre para birimi belirleme
        let languageCode = Bundle.main.preferredLocalizations.first ?? "en"
        
        if languageCode == "tr" {
            formatter.currencyCode = "TRY"
            formatter.locale = Locale(identifier: "tr_TR")
            formatter.currencySymbol = "₺"
        } else {
            formatter.currencyCode = "USD"
            formatter.locale = Locale(identifier: "en_US")
            formatter.currencySymbol = "$"
        }
        
        return formatter.string(from: NSNumber(value: self)) ?? ""
    }
    
    func percentFormat() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        
        let languageCode = Bundle.main.preferredLocalizations.first ?? "en"
        formatter.locale = Locale(identifier: languageCode == "tr" ? "tr_TR" : "en_US")
        
        return formatter.string(from: NSNumber(value: self / 100)) ?? ""
    }
    
    func formatAsCurrency() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        let languageCode = Bundle.main.preferredLocalizations.first ?? "en"
        
        if languageCode == "tr" {
            formatter.currencyCode = "TRY"
            formatter.locale = Locale(identifier: "tr_TR")
            formatter.currencySymbol = "₺"
            return formatter.string(from: NSNumber(value: self)) ?? String(format: "%.2f ₺", self)
        } else {
            formatter.currencyCode = "USD"
            formatter.locale = Locale(identifier: "en_US")
            formatter.currencySymbol = "$"
            return formatter.string(from: NSNumber(value: self)) ?? String(format: "$%.2f", self)
        }
    }
} 
