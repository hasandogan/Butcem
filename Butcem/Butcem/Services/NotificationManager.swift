import Foundation
import UserNotifications

@MainActor
class NotificationManager {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()
    private let defaults = UserDefaults.standard
    
    func scheduleBudgetWarning(for category: Category, spent: Double, limit: Double, type: BudgetStatus) {
        print("\n📱 Checking category limit: \(category.rawValue)")
        print("Spent: \(spent)")
        print("Limit: \(limit)")
        print("Status: \(type)")
        
        // Sadece limit aşıldığında bildirim gönder
        guard spent >= limit else {
            print("⏱️ Limit not exceeded yet")
            return
        }
        
        // Bu ay için bu kategoriye bildirim gönderilmiş mi kontrol et
        let currentMonth = Date().startOfMonth().timeIntervalSince1970
        let notificationKey = "budget_warning_\(category.rawValue)_\(currentMonth)"
        
        if defaults.bool(forKey: notificationKey) {
            print("🔄 Notification already sent for this category this month")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Bütçe Uyarısı: \(category.rawValue)"
        content.body = "'\(category.rawValue)' kategorisinde bütçe limitini aştınız! (\(spent.currencyFormat()))"
        content.sound = .default
        content.badge = 1
        
        let request = UNNotificationRequest(
            identifier: notificationKey,
            content: content,
            trigger: nil
        )
        
        center.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule notification: \(error.localizedDescription)")
            } else {
                print("✅ Notification scheduled for exceeded limit in \(category.rawValue)")
                // Bu ay için bildirimi işaretle
                self.defaults.set(true, forKey: notificationKey)
            }
        }
    }
    
    func scheduleGeneralBudgetWarning(spent: Double, total: Double, type: BudgetStatus) {
        // Sadece toplam bütçe aşıldığında bildirim gönder
        guard spent >= total else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Genel Bütçe Uyarısı"
        content.body = "Toplam bütçe limitini aştınız! (\(spent.currencyFormat()))"
        content.sound = .default
        
        let identifier = "general_budget_warning"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        center.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule general notification: \(error.localizedDescription)")
            } else {
                print("✅ General budget warning scheduled")
            }
        }
    }
    
    func resetMonthlyNotifications() {
        // Tüm bildirimleri temizle
        center.removeAllPendingNotificationRequests()
        
        // Önceki ay bildirimleri için UserDefaults'ı temizle
        let keys = defaults.dictionaryRepresentation().keys
        let previousMonth = Date().startOfMonth().addingTimeInterval(-86400).timeIntervalSince1970
        
        keys.filter { $0.hasPrefix("budget_warning_") && 
                     $0.components(separatedBy: "_").last.map { Double($0) ?? 0 } ?? 0 <= previousMonth }
            .forEach { defaults.removeObject(forKey: $0) }
        
        print("Monthly notifications have been reset")
    }
    
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        print("All notifications have been cancelled")
    }
}

