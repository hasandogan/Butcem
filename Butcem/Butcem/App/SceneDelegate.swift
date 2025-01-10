import SwiftUI
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        Task {
            do {
                try await FirebaseService.shared.processRecurringTransactions()
                print("✅ Recurring transactions checked on scene activation")
            } catch {
                print("❌ Failed to process recurring transactions: \(error.localizedDescription)")
            }
        }
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.scheduleBackgroundProcessing()
        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.scheduleBackgroundProcessing()
        }
    }
} 
