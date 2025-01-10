import SwiftUI
import FirebaseAuth
import StoreKit

@MainActor
class UserSettingsViewModel: ObservableObject {
    @Published private(set) var billingDay: Int = UserDefaults.standard.integer(forKey: "billingDay")
    @Published private(set) var isPremium: Bool = false
    @Published private(set) var subscriptionPlan: String = "Ücretsiz"
    @Published private(set) var subscriptionEndDate: Date?
    @Published private(set) var subscriptionStartDate: Date?
    @Published private(set) var subscriptionPrice: Double = 0.0
    @Published var errorMessage: String?
    @Published var showError = false
    @Published private(set) var billingPeriod: SubscriptionInfo.BillingPeriod = .monthly
    
    private var periodicUpdateTask: Task<Void, Never>?
    private var transactionListener: Task<Void, Never>?
    
    init() {
        // İlk kontrolü hemen yap
        Task {
            await loadSubscriptionInfo()
        }
        setupPeriodicUpdates()
        setupTransactionListener()
    }
    
    private func setupPeriodicUpdates() {
        periodicUpdateTask?.cancel()
        
        periodicUpdateTask = Task {
            while !Task.isCancelled {
                await loadSubscriptionInfo()
                try? await Task.sleep(nanoseconds: 30 * NSEC_PER_SEC) // 30 saniye
            }
        }
    }
    
    private func setupTransactionListener() {
        transactionListener?.cancel()
        
        transactionListener = Task {
            for await _ in StoreKit.Transaction.updates {
                // Transaction değişikliğinde hemen kontrol et
                await loadSubscriptionInfo()
            }
        }
    }
    
    private func loadSubscriptionInfo() async {
        let subscriptionInfo = await StoreKitService.shared.checkSubscriptionStatus()
        
        await MainActor.run {
            withAnimation {
                self.isPremium = subscriptionInfo.isActive
                self.subscriptionPlan = subscriptionInfo.planName
                self.subscriptionEndDate = subscriptionInfo.endDate
                self.subscriptionStartDate = subscriptionInfo.startDate
                self.subscriptionPrice = subscriptionInfo.price
                self.billingPeriod = subscriptionInfo.billingPeriod
            }
        }
    }
    
    func updateBillingDay(_ day: Int) async {
        guard (1...31).contains(day) else {
            errorMessage = "Geçersiz gün".localized
            showError = true
            return
        }
        
        do {
            let settings = UserSettings(
                userId: AuthManager.shared.currentUserId,
                billingDay: day,
                createdAt: Date()
            )
            try await FirebaseService.shared.saveUserSettings(settings)
            await MainActor.run {
                self.billingDay = day
                UserDefaults.standard.set(day, forKey: "billingDay")
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    var billingPeriodLabel: String {
        billingPeriod.label
    }
    
    deinit {
        periodicUpdateTask?.cancel()
        transactionListener?.cancel()
    }
} 
