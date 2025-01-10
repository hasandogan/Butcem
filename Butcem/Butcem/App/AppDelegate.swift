import UIKit
import FirebaseStorage
import FirebaseCore
import FirebaseFirestore
import FirebaseMessaging
import UserNotifications
import BackgroundTasks
import StoreKit

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
	func application(_ application: UIApplication,
					didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
		FirebaseApp.configure()
		
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
		
		// Tekrarlanan işlemleri kontrol et
		Task {
			do {
				try await FirebaseService.shared.processRecurringTransactions()
				print("✅ Recurring transactions checked on app launch")
			} catch {
				print("❌ Failed to process recurring transactions: \(error.localizedDescription)")
			}
		}
		
		// StoreKit başlangıç kontrolü
		Task {
			// Önce mevcut abonelikleri kontrol et
			let subscriptionInfo = await StoreKitService.shared.checkSubscriptionStatus()
			print("📱 Initial subscription check: \(subscriptionInfo.planName)")
			
			// Transaction listener'ı başlat
			await StoreKitService.shared.listenForTransactionUpdates()
		}
		
		return true
	}
	
	private func registerBackgroundTasks() {
		print("📝 Starting background tasks registration...")
		
		// Tekrarlanan işlemler task'i
		do {
			BGTaskScheduler.shared.register(
				forTaskWithIdentifier: "com.butcem.app.recurring-transaction-processing",
				using: nil // .main yerine nil kullan
			) { task in
				print("🔄 Recurring transaction task triggered")
				self.handleRecurringTransactions(task: task as! BGProcessingTask)
			}
			print("✅ Successfully registered recurring transaction task")
		} catch {
			print("❌ Failed to register recurring transaction task: \(error)")
		}
		
		// İlk planlamayı yap
		DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
			self?.scheduleBackgroundProcessing()
		}
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
		scheduleBackgroundProcessing()
	}
	
	// Uygulama sonlandırıldığında
	func applicationWillTerminate(_ application: UIApplication) {
		scheduleBackgroundProcessing()
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
		completionHandler([.badge, .list])
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
	
	func handleRecurringTransactions(task: BGProcessingTask) {
		print("🔄 Starting recurring transactions handler...")
		
		// Background task'in minimum süresini ayarla
		task.expirationHandler = {
			print("❌ Task expired before completion")
			task.setTaskCompleted(success: false)
		}
		
		// Tekrarlanan işlemleri işle
		Task {
			do {
				print("📝 Processing recurring transactions...")
				try await FirebaseService.shared.processRecurringTransactions()
				print("✅ Successfully processed recurring transactions")
				scheduleBackgroundProcessing()
				task.setTaskCompleted(success: true)
			} catch {
				print("❌ Background işlem hatası: \(error.localizedDescription)")
				print("Error details: \(error)")
				task.setTaskCompleted(success: false)
			}
		}
	}
	
	// Tüm background task'leri planlayan fonksiyon
	func scheduleBackgroundProcessing() {
		print("📝 Scheduling background tasks...")
		
		// Önceki task'leri iptal et
		BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: "com.butcem.app.recurring-transaction-processing")
		print("🗑️ Cancelled previous tasks")
		
		let queue = DispatchQueue.global(qos: .background)
		queue.async {
			let processingRequest = BGProcessingTaskRequest(identifier: "com.butcem.app.recurring-transaction-processing")
			processingRequest.requiresNetworkConnectivity = true
			processingRequest.requiresExternalPower = false
			processingRequest.earliestBeginDate = Date(timeIntervalSinceNow: 60) // 1 dakika sonra başlat
			
			do {
				try BGTaskScheduler.shared.submit(processingRequest)
				print("✅ Successfully scheduled recurring transaction task")
				print("🕒 Next run scheduled for: \(processingRequest.earliestBeginDate ?? Date())")
			} catch {
				print("❌ Failed to schedule background task: \(error.localizedDescription)")
				print("Error domain: \((error as NSError).domain)")
				print("Error code: \((error as NSError).code)")
				print("Full error: \(error)")
			}
		}
	}
	
	private func updateCustomerProductStatus() async {
		for await result in StoreKit.Transaction.currentEntitlements {
			if case .verified(let transaction) = result {
				await transaction.finish()
			}
		}
	}
}
