import Foundation
import UserNotifications
import FirebaseMessaging
import FirebaseFirestore
import UIKit

@MainActor
class NotificationManager: NSObject, MessagingDelegate, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()
    private let messaging = Messaging.messaging()
    
    override private init() {
        super.init()
        setupMessaging()
        requestNotificationPermissions()
    }
    
    private func setupMessaging() {
        messaging.delegate = self
        center.delegate = self
        
        // FCM token'ı al ve kaydet
        messaging.token { [weak self] token, error in
            if let error = error {
                print("Error fetching FCM token: \(error)")
                return
            }
            if let token = token {
                self?.saveFCMToken(token)
            }
        }
        
        // Bildirim izni iste
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Bildirim izni verildi")
            } else if let error = error {
                print("Bildirim izni hatası: \(error)")
            }
        }
    }
    
     func saveFCMToken(_ token: String) {
        guard let userId = AuthManager.shared.currentUserId else { return }
        
        Task {
            do {
                try await FirebaseService.shared.db.collection("users")
                    .document(userId)
                    .setData(["fcmToken": token], merge: true)
                print("FCM token saved successfully")
            } catch {
                print("Error saving FCM token: \(error)")
            }
        }
    }
    
    private func requestNotificationPermissions() {
        Task {
            do {
                let settings = await center.notificationSettings()
                
                switch settings.authorizationStatus {
                case .notDetermined:
                    let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
                    if granted {
                        print("✅ Bildirim izni alındı")
                        await MainActor.run {
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                    } else {
                        print("❌ Bildirim izni reddedildi")
                    }
                    
                case .denied:
                    print("❌ Bildirim izni reddedilmiş. Lütfen Ayarlar'dan izin verin.")
                    // Kullanıcıya ayarlara gitme seçeneği sunabilirsiniz
                    
                case .authorized, .provisional, .ephemeral:
                    print("✅ Bildirim izni mevcut")
                    await MainActor.run {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                    
                @unknown default:
                    break
                }
            } catch {
                print("❌ Bildirim izni hatası: \(error.localizedDescription)")
            }
        }
    }
    
    // Yerel bildirim planlama
    func scheduleReminder(_ reminder: Reminder) async {
        do {
            let settings = await center.notificationSettings()
            guard settings.authorizationStatus == .authorized else {
                print("❌ Bildirim izni yok! Ayarlardan izin vermeniz gerekiyor.")
                return
            }
            
            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.body = "\(reminder.amount.currencyFormat()) tutarındaki \(reminder.type == .income ? "gelir" : "gider") hatırlatıcısı"
            content.sound = .default
            
            // Tarih işlemleri
            var calendar = Calendar.current
            calendar.timeZone = TimeZone(identifier: "Europe/Istanbul")!
            
            // Şu anki tarihi al
            let now = Date()
            
            // Seçilen saat ve dakikayı al
            let reminderComponents = calendar.dateComponents([.hour, .minute], from: reminder.dueDate)
            
            // Bugünün tarihiyle birleştir
            var targetComponents = calendar.dateComponents([.year, .month, .day], from: now)
            targetComponents.hour = reminderComponents.hour
            targetComponents.minute = reminderComponents.minute
            
            // Eğer seçilen saat bugün için geçmişse, yarına planla
            if let targetDate = calendar.date(from: targetComponents),
               targetDate < now {
                targetComponents = calendar.dateComponents([.year, .month, .day], from: calendar.date(byAdding: .day, value: 1, to: now)!)
                targetComponents.hour = reminderComponents.hour
                targetComponents.minute = reminderComponents.minute
            }
            
            print("📅 Planlanan Bildirim Detayları:")
            print("Şu anki Tarih: \(now)")
            print("Seçilen Saat: \(reminderComponents.hour ?? 0):\(reminderComponents.minute ?? 0)")
            print("Hedef Bileşenler:")
            print("- Yıl: \(targetComponents.year ?? 0)")
            print("- Ay: \(targetComponents.month ?? 0)")
            print("- Gün: \(targetComponents.day ?? 0)")
            print("- Saat: \(targetComponents.hour ?? 0)")
            print("- Dakika: \(targetComponents.minute ?? 0)")
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: targetComponents, repeats: false)
            
            // Tetiklenme tarihini kontrol et
            if let triggerDate = calendar.date(from: targetComponents) {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                formatter.timeZone = calendar.timeZone
                print("Tetiklenecek Tarih: \(formatter.string(from: triggerDate))")
            }
            
            let request = UNNotificationRequest(
                identifier: "reminder_\(reminder.documentId)",
                content: content,
                trigger: trigger
            )
            
            // Önceki bildirimleri temizle
            await center.removeAllPendingNotificationRequests()
            
            try await center.add(request)
            print("✅ Hatırlatıcı başarıyla planlandı")
            await checkPendingNotifications()
            
        } catch {
            print("❌ Hatırlatıcı planlanırken hata: \(error.localizedDescription)")
        }
    }
    
    // Hatırlatıcı bildirimini iptal et
    func cancelReminder(_ reminderId: String) {
        center.removePendingNotificationRequests(withIdentifiers: ["reminder_\(reminderId)"])
    }
    
    // Tüm hatırlatıcı bildirimlerini iptal et
    func cancelAllReminders() {
        center.getPendingNotificationRequests { requests in
            let reminderIds = requests
                .filter { $0.identifier.hasPrefix("reminder_") }
                .map { $0.identifier }
            self.center.removePendingNotificationRequests(withIdentifiers: reminderIds)
        }
    }
    
    // FCM token güncellendiğinde
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let token = fcmToken {
            saveFCMToken(token)
        }
    }
    
    // Bildirim geldiğinde
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
    
    // Bildirime tıklandığında
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
    
    // Bütçe uyarısı için bildirim planlama
    func scheduleBudgetWarning(category: Category, spent: Double, limit: Double) {
        let content = UNMutableNotificationContent()
        content.title = "Bütçe Uyarısı"
        content.body = "\(category.rawValue) kategorisinde bütçe limitine yaklaşıyorsunuz. Harcama: \(spent.currencyFormat()), Limit: \(limit.currencyFormat())"
        content.sound = .default
        
        // Hemen bildirim gönder
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "budget_warning_\(category.rawValue)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Bütçe uyarısı bildirimi hatası: \(error)")
            }
        }
    }
    
    // Bütçe aşımı bildirimi
    func scheduleBudgetOverspent(category: Category, spent: Double, limit: Double) {
        let content = UNMutableNotificationContent()
        content.title = "Bütçe Aşımı!"
        content.body = "\(category.rawValue) kategorisinde bütçe limitini aştınız! Harcama: \(spent.currencyFormat()), Limit: \(limit.currencyFormat())"
        content.sound = .default
        
        // Hemen bildirim gönder
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "budget_overspent_\(category.rawValue)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Bütçe aşımı bildirimi hatası: \(error)")
            }
        }
    }
    
    // Bütçe bildirimlerini iptal et
    func cancelBudgetNotifications(for category: Category) {
        let identifiers = [
            "budget_warning_\(category.rawValue)",
            "budget_overspent_\(category.rawValue)"
        ]
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    // Genel bütçe uyarısı
    func scheduleGeneralBudgetWarning(spent: Double, limit: Double, percentage: Double) {
        let content = UNMutableNotificationContent()
        content.title = "Genel Bütçe Uyarısı"
        content.body = "Toplam bütçenizin %\(Int(percentage))'ine ulaştınız. Harcama: \(spent.currencyFormat()), Limit: \(limit.currencyFormat())"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "general_budget_warning",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Genel bütçe uyarısı bildirimi hatası: \(error)")
            }
        }
    }
    
    // Aylık bildirimleri sıfırla
    func resetMonthlyNotifications() {
        center.getPendingNotificationRequests { requests in
            let budgetNotifications = requests.filter { 
                $0.identifier.hasPrefix("budget_warning_") ||
                $0.identifier.hasPrefix("budget_overspent_") ||
                $0.identifier == "general_budget_warning"
            }.map { $0.identifier }
            
            self.center.removePendingNotificationRequests(withIdentifiers: budgetNotifications)
        }
    }
    
    // Bütçe kontrolü için yardımcı metod
    func checkBudgetLimits(category: Category, spent: Double, limit: Double, warningThreshold: Double = 0.8) {
        if spent >= limit {
            scheduleBudgetOverspent(category: category, spent: spent, limit: limit)
        } else if spent >= (limit * warningThreshold) {
            scheduleBudgetWarning(category: category, spent: spent, limit: limit)
        }
    }
    
    // Yardımcı debug fonksiyonu ekleyelim
    func checkPendingNotifications() async {
        let requests = await center.pendingNotificationRequests()
        print("\n🔔 Bekleyen Bildirimler (\(requests.count)):")
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "Europe/Istanbul")
        
        for request in requests {
            if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                print("-------------------")
                print("ID: \(request.identifier)")
                print("Başlık: \(request.content.title)")
                print("Mesaj: \(request.content.body)")
                
                if let triggerDate = Calendar.current.date(from: trigger.dateComponents) {
                    print("Tetiklenme Tarihi: \(formatter.string(from: triggerDate))")
                }
            }
        }
        print("-------------------\n")
    }
    
    func checkNotificationSettings() async {
        let settings = await center.notificationSettings()
        
        print("📱 Bildirim Ayarları Durumu:")
        print("Yetkilendirme: \(settings.authorizationStatus.rawValue)")
        print("Bildirim İzni: \(settings.notificationCenterSetting.rawValue)")
        print("Ses İzni: \(settings.soundSetting.rawValue)")
        print("Rozet İzni: \(settings.badgeSetting.rawValue)")
        print("Kilit Ekranı İzni: \(settings.lockScreenSetting.rawValue)")
        print("Uyarı İzni: \(settings.alertSetting.rawValue)")
    }
    
    func handleScheduledNotifications() {
        guard let userId = AuthManager.shared.currentUserId else { return }
        
        // Firestore listener'ı ekle
        FirebaseService.shared.db.collection("notifications")
            .whereField("userId", isEqualTo: userId)
            .whereField("status", isEqualTo: "scheduled")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self,
                      let documents = snapshot?.documents else { return }
                
                for document in documents {
                    guard let scheduledFor = document.data()["scheduledFor"] as? Timestamp,
                          let title = document.data()["title"] as? String,
                          let body = document.data()["body"] as? String else { continue }
                    
                    let scheduledDate = scheduledFor.dateValue()
                    let now = Date()
                    
                    // Debug için yazdır
                    print("🔔 Bildirim Kontrolü:")
                    print("Planlanan: \(scheduledDate)")
                    print("Şu an: \(now)")
                    print("Fark (saniye): \(scheduledDate.timeIntervalSince(now))")
                    
                    // Eğer bildirim zamanı geldiyse veya 60 saniye içindeyse
                    if scheduledDate <= now || scheduledDate.timeIntervalSince(now) <= 60 {
                        // Bildirimi hemen gönder
                        self.sendNotification(title: title, body: body, identifier: document.documentID)
                        
                        // Durumu güncelle
                        Task {
                            try? await document.reference.updateData([
                                "status": "sent",
                                "sentAt": Timestamp(date: Date())
                            ])
                        }
                    }
                }
            }
    }
    
    private func sendNotification(title: String, body: String, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        
        // Hemen gönder
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("❌ Bildirim gönderme hatası: \(error)")
            } else {
                print("✅ Bildirim başarıyla gönderildi: \(title)")
            }
        }
    }
}


