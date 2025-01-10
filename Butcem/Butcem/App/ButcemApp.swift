import SwiftUI
import FirebaseCore
import FirebaseStorage

@main
struct ButcemApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var showSplash = true
	let notificationManager = NotificationManager.shared

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                
                if showSplash {
                    SplashScreen()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation {
                        showSplash = false
                    }
                }
            }
        }
    }
} 



