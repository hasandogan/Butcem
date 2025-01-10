import Foundation

extension Int {
    func daysString() -> String {
        let format = self == 1 ? "remaining_days_format_singular" : "remaining_days_format"
        return String(format: format.localized, self)
    }
} 