import SwiftUI
import FirebaseFirestore

@MainActor
class ReminderViewModel: ObservableObject {
    @Published private(set) var reminders: [Reminder] = []
    @Published var errorMessage: String?
    private var listener: ListenerRegistration?
    
    init() {
        setupListener()
    }
    
    deinit {
        listener?.remove()
    }
    
    private func setupListener() {
        guard let userId = AuthManager.shared.currentUserId else { return }
        
        listener = FirebaseService.shared.db.collection("reminders")
            .whereField("userId", isEqualTo: userId)
            .whereField("isActive", isEqualTo: true)
            .order(by: "dueDate")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self.reminders = documents.compactMap { document in
                    try? document.data(as: Reminder.self)
                }
            }
    }
    
    func loadReminders() async {
        do {
            reminders = try await FirebaseService.shared.getReminders()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func addReminder(_ reminder: Reminder) async {
        do {
            try await FirebaseService.shared.scheduleReminder(reminder)
            // Debug için Firebase bildirimlerini kontrol et
            await FirebaseService.shared.checkFirebaseNotifications()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func updateReminder(_ reminder: Reminder) async {
        do {
            try await FirebaseService.shared.updateReminder(reminder)
            await loadReminders()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func deleteReminder(_ reminder: Reminder) async {
        do {
            try await FirebaseService.shared.deleteReminder(reminder)
            await loadReminders()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func scheduleNotifications() {
        // Premium kontrolü
        guard UserDefaults.standard.bool(forKey: "isPremium") else { return }
        
        // Önce tüm bildirimleri temizle
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        for reminder in reminders {
            // Sadece aktif ve gelecek tarihli hatırlatıcılar için bildirim planla
            guard reminder.isActive && reminder.dueDate > Date() else { continue }
            
            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.body = "\(reminder.amount.currencyFormat()) tutarında \(reminder.type == .income ? "gelir" : "gider") hatırlatıcısı"
            content.sound = .default
            content.badge = 1
            
            // Hatırlatıcı zamanından 1 saat önce bildir
            let notificationDate = Calendar.current.date(byAdding: .hour, value: -1, to: reminder.dueDate) ?? reminder.dueDate
            let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate)
            
            // Tekrar sıklığına göre trigger oluştur
            let trigger: UNNotificationTrigger
            switch reminder.frequency {
            case .once:
                trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
            case .daily:
                let components = DateComponents(hour: triggerDate.hour, minute: triggerDate.minute)
                trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            case .weekly:
                var components = DateComponents(hour: triggerDate.hour, minute: triggerDate.minute)
                components.weekday = Calendar.current.component(.weekday, from: reminder.dueDate)
                trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            case .monthly:
                var components = DateComponents(hour: triggerDate.hour, minute: triggerDate.minute)
                components.day = Calendar.current.component(.day, from: reminder.dueDate)
                trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            case .yearly:
                var components = DateComponents(hour: triggerDate.hour, minute: triggerDate.minute)
                components.day = Calendar.current.component(.day, from: reminder.dueDate)
                components.month = Calendar.current.component(.month, from: reminder.dueDate)
                trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            }
            
            let request = UNNotificationRequest(
                identifier: "reminder_\(reminder.documentId)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Bildirim planlama hatası: \(error.localizedDescription)")
                }
            }
        }
    }
} 
