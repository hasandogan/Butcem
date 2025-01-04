import UIKit
import FirebaseCore
import FirebaseFirestore
import FirebaseMessaging
import UserNotifications
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Background task'leri kaydet
        registerBackgroundTasks()
        
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        let db = Firestore.firestore()
        db.settings = settings
        
        // Firebase Messaging ayarları
        Messaging.messaging().delegate = self
        
        // Bildirim ayarları
        UNUserNotificationCenter.current().delegate = self
        
        // Bildirim izinlerini iste
        Task {
            do {
                let granted = try await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .badge, .sound])
                
                if granted {
                    print("✅ Bildirim izni verildi")
                    await MainActor.run {
                        application.registerForRemoteNotifications()
                    }
                } else {
                    print("❌ Bildirim izni reddedildi")
                }
            } catch {
                print("❌ Bildirim izni hatası: \(error.localizedDescription)")
            }
        }
        
        // Bildirim yöneticisini başlat
        NotificationManager.shared.handleScheduledNotifications()
        
        return true
    }
    
    private func registerBackgroundTasks() {
        // Bildirim kontrol task'ini kaydet
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.butcem.app.notification.refresh",
            using: nil
        ) { task in
            self.handleNotificationRefresh(task: task as! BGAppRefreshTask)
        }
        
        // İşlem task'ini kaydet
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.butcem.app.notification.processing",
            using: nil
        ) { task in
            self.handleNotificationProcessing(task: task as! BGProcessingTask)
        }
        
        scheduleBackgroundTasks()
    }
    
    private func scheduleBackgroundTasks() {
        // Bildirim kontrol task'ini planla
        let refreshRequest = BGAppRefreshTaskRequest(identifier: "com.butcem.app.notification.refresh")
        refreshRequest.earliestBeginDate = Date(timeIntervalSinceNow: 60) // 1 dakika
        
        // İşlem task'ini planla
        let processingRequest = BGProcessingTaskRequest(identifier: "com.butcem.app.notification.processing")
        processingRequest.earliestBeginDate = Date(timeIntervalSinceNow: 60) // 1 dakika
        processingRequest.requiresNetworkConnectivity = true
        
        do {
            try BGTaskScheduler.shared.submit(refreshRequest)
            try BGTaskScheduler.shared.submit(processingRequest)
            print("✅ Background task'ler planlandı")
            
            // Debug için planlanan task'leri göster
            print("🕒 Planlanan task'ler:")
            print("Refresh: \(refreshRequest.earliestBeginDate ?? Date())")
            print("Processing: \(processingRequest.earliestBeginDate ?? Date())")
        } catch {
            print("❌ Background task planlama hatası: \(error)")
        }
    }
    
    private func handleNotificationRefresh(task: BGAppRefreshTask) {
        // Task'i yeniden planla
        scheduleBackgroundTasks()
        
        // Bildirimleri kontrol et
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        NotificationManager.shared.handleScheduledNotifications()
        task.setTaskCompleted(success: true)
    }
    
    private func handleNotificationProcessing(task: BGProcessingTask) {
        // Task'i yeniden planla
        scheduleBackgroundTasks()
        
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        NotificationManager.shared.handleScheduledNotifications()
        task.setTaskCompleted(success: true)
    }
    
    // Uygulama arka plana geçtiğinde
    func applicationDidEnterBackground(_ application: UIApplication) {
        scheduleBackgroundTasks()
    }
    
    // Uygulama sonlandırıldığında
    func applicationWillTerminate(_ application: UIApplication) {
        scheduleBackgroundTasks()
    }
    
    // Firebase Messaging için gerekli metodlar
    func application(_ application: UIApplication,
                    didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("📱 Remote notification received")
        completionHandler(.newData)
    }
    
    func application(_ application: UIApplication,
                    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        print("✅ APNs token set: \(deviceToken)")
    }
    
    func application(_ application: UIApplication,
                    didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error)")
    }
    
    // MessagingDelegate metodu
    func messaging(_ messaging: Messaging,
                  didReceiveRegistrationToken fcmToken: String?) {
        if let token = fcmToken {
            print("✅ FCM token: \(token)")
            NotificationManager.shared.saveFCMToken(token)
        }
    }
    
    // Uygulama açıkken bildirimleri göster
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("🔔 Bildirim alındı (uygulama açıkken)")
        completionHandler([.banner, .sound, .badge, .list])
    }
    
    // Bildirime tıklandığında
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("👆 Bildirime tıklandı")
        let identifier = response.notification.request.identifier
        print("Bildirim ID: \(identifier)")
        completionHandler()
    }
} 
