import Foundation

enum Constants {
    static let appName = "Bütçem"
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    
    enum UserDefaultsKeys {
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let selectedCurrency = "selectedCurrency"
        static let notificationsEnabled = "notificationsEnabled"
    }
    
    enum NotificationNames {
        static let transactionAdded = "transactionAdded"
        static let budgetUpdated = "budgetUpdated"
        static let goalCompleted = "goalCompleted"
    }
    
    enum DateFormats {
        static let displayDate = "dd MMM yyyy"
        static let apiDate = "yyyy-MM-dd'T'HH:mm:ssZ"
        static let monthYear = "MMMM yyyy"
    }
} 