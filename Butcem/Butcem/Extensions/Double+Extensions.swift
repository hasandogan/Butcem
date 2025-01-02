import Foundation

extension Double {
    func currencyFormat() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TRY"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: NSNumber(value: self)) ?? "₺0,00"
    }
    
    func percentFormat() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: NSNumber(value: self / 100)) ?? "%0,0"
    }
} 