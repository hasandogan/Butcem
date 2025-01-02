import StoreKit
import Combine

enum SubscriptionTier: String {
    case basic = "basic"
    case premium = "premium"
    case pro = "pro"
}

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
     let storeManager = StoreKitManager.shared
    
    @Published private(set) var currentTier: SubscriptionTier = .basic
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupObservers()
    }
    
    private func setupObservers() {
        // StoreKitManager'dan gelen değişiklikleri dinle
        storeManager.$purchasedProductIDs
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.currentTier = self?.storeManager.currentTier ?? .basic
                // Debug için log ekleyelim
                print("Subscription Updated - Current Tier: \(self?.currentTier ?? .basic)")
            }
            .store(in: &cancellables)
    }
    
    // Premium özelliklere erişim kontrolleri
    var canAccessAdvancedAnalytics: Bool {
        // Debug için log ekleyelim
        print("Current Tier: \(currentTier)")
        print("Purchased Products: \(storeManager.purchasedProductIDs)")
        return currentTier != .basic
    }
    
    var canAccessBudgetPlanning: Bool {
        currentTier != .basic
    }
    
    var canAccessAdvancedFeatures: Bool {
        currentTier != .basic
    }
    
    var canAccessCustomGoals: Bool {
        currentTier != .basic
    }
    
    var canAccessFamilyBudget: Bool {
        currentTier == .pro
    }
    
    var canAccessBankIntegration: Bool {
        currentTier == .pro
    }
    
    var canAccessPremiumFeatures: Bool {
        currentTier == .premium || currentTier == .pro
    }
    
    var canAccessProFeatures: Bool {
        currentTier == .pro
    }
    
    // StoreKit işlemleri için wrapper metodlar
    func purchaseProduct(_ product: Product) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await storeManager.purchase(product)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func refresh() async {
        await storeManager.updateSubscriptionStatus()
        currentTier = storeManager.currentTier
        print("Subscription Refreshed - Current Tier: \(currentTier)")
        print("Purchased Products: \(storeManager.purchasedProductIDs)")
    }
} 
