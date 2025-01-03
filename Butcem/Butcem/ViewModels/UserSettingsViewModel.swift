import SwiftUI
import FirebaseAuth

@MainActor
class UserSettingsViewModel: ObservableObject {
    @Published var billingDay: Int = 1
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        Task {
            await loadSettings()
        }
    }
    
    func loadSettings() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            if let settings = try await FirebaseService.shared.getUserSettings() {
                billingDay = settings.billingDay
            } else {
                // Varsayılan ayarları kaydet
                let settings = UserSettings(
                    userId: Auth.auth().currentUser?.uid ?? "",
                    billingDay: 1,
                    createdAt: Date()
                )
                try await FirebaseService.shared.saveUserSettings(settings)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func updateBillingDay(_ day: Int) async {
        guard (1...31).contains(day) else {
            errorMessage = "Geçersiz gün"
            return
        }
        
        do {
            let settings = UserSettings(
                userId: Auth.auth().currentUser?.uid ?? "",
                billingDay: day,
                createdAt: Date()
            )
            try await FirebaseService.shared.saveUserSettings(settings)
            await MainActor.run {
                self.billingDay = day
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
} 
