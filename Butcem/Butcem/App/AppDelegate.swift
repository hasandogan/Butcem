import UIKit
import FirebaseCore
import FirebaseFirestore
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        let db = Firestore.firestore()
        db.settings = settings
        
        // Bildirim ayarları
        let center = UNUserNotificationCenter.current()
        center.delegate = self // Delegate'i ayarla
        
        // Bildirim izinlerini iste
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("✅ Notification permission granted")
                // İzin verildiyse ana thread'de bildirim ayarlarını yap
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            } else if let error = error {
                print("❌ Notification permission error: \(error.localizedDescription)")
            } else {
                print("❌ Notification permission denied")
            }
        }
        
        return true
    }
    
    // Uygulama açıkken bildirimleri göster
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
} 
