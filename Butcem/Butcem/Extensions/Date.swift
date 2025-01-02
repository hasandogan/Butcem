import Foundation

extension Date {
    func startOfMonth() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }
    
    func endOfMonth() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: calendar.date(from: components) ?? self)
        return endOfMonth ?? self
    }
    
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: self)
    }
    
    func monthString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: self)
    }
    
    func monthYearString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: self)
    }
    
    func startOfDay() -> Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    func adding(_ component: Calendar.Component, value: Int) -> Date {
        return Calendar.current.date(byAdding: component, value: value, to: self) ?? self
    }
    
    func isSameMonth(as date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(self, equalTo: date, toGranularity: .month)
    }
}
