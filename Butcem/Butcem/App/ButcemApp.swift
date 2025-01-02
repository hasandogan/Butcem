import SwiftUI
import FirebaseCore

@main
struct ButcemApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var showSplash = true
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(authViewModel)
                
                if showSplash {
                    SplashScreen()
                        .environmentObject(authViewModel)
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


