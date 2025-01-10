import Foundation

extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
    
    func localizedFormat(_ arguments: CVarArg...) -> String {
        String(format: NSLocalizedString(self, comment: ""), arguments)
    }
    
    func extractAmount() -> Double? {
        // Sayıları ve nokta/virgülü bul
        let pattern = #"(\d+[.,]\d{2})"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: self, range: NSRange(startIndex..., in: self)) else {
            return nil
        }
        
        // Eşleşen metni al
        let amountString = (self as NSString).substring(with: match.range(at: 1))
        
        // Virgülü noktaya çevir (Türkçe formatından)
        let normalizedString = amountString.replacingOccurrences(of: ",", with: ".")
        
        // Double'a çevir
        return Double(normalizedString)
    }
    
    func toDate() -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "tr_TR")
        
        // Olası tarih formatları
        let dateFormats = [
            "dd.MM.yyyy",
            "dd/MM/yyyy",
            "dd-MM-yyyy",
            "yyyy-MM-dd"
        ]
        
        for format in dateFormats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: self) {
                return date
            }
        }
        
        return nil
    }
} 
