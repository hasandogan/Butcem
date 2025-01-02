import StoreKit

enum StoreError: Error {
    case failedVerification
    case noProductsFound
    case purchaseFailed
    case userCancelled
    
    var localizedDescription: String {
        switch self {
        case .failedVerification:
            return "Satın alma doğrulanamadı"
        case .noProductsFound:
            return "Ürünler yüklenemedi"
        case .purchaseFailed:
            return "Satın alma başarısız oldu"
        case .userCancelled:
            return "Satın alma iptal edildi"
        }
    }
}

@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()
    
    private let productIds = ["Butce.month", "butce.year", "butce.pro"]
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs = Set<String>()
    @Published var errorMessage: String?
    
    private var transactionListener: Task<Void, Error>?
    
    init() {
        startTransactionListener()
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    func loadProducts() async {
        do {
            products = try await Product.products(for: productIds)
        } catch {
            print("Failed to load products: \(error)")
            errorMessage = "Ürünler yüklenemedi"
        }
    }
    
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                await transaction.finish()
                await updateSubscriptionStatus()
            case .unverified:
                throw StoreError.failedVerification
            }
        case .userCancelled:
            throw StoreError.userCancelled
        case .pending:
            print("Purchase pending")
        @unknown default:
            throw StoreError.purchaseFailed
        }
    }
    
    private func startTransactionListener() {
        transactionListener = Task.detached {
			for await verification in StoreKit.Transaction.updates {
				if case .verified(let transaction) = verification {
                    await self.updateSubscriptionStatus()
					await transaction.finish()
                }
            }
        }
    }
    
     func updateSubscriptionStatus() async {
		for await result in StoreKit.Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                await MainActor.run {
                    if transaction.revocationDate == nil {
                        purchasedProductIDs.insert(transaction.productID)
                    } else {
                        purchasedProductIDs.remove(transaction.productID)
                    }
                }
            }
        }
    }
    
    var monthlyProduct: Product? {
        products.first { $0.id == "Butce.month" }
    }
    
    var yearlyProduct: Product? {
        products.first { $0.id == "butce.year" }
    }
    
    var proProduct: Product? {
        products.first { $0.id == "butce.pro" }
    }
    
    var hasActiveSubscription: Bool {
        !purchasedProductIDs.isEmpty
    }
    
    var currentTier: SubscriptionTier {
        if purchasedProductIDs.contains("butce.pro") {
            return .pro
        } else if purchasedProductIDs.contains("Butce.month") || 
                  purchasedProductIDs.contains("butce.year") {
            return .premium
        }
        return .basic
    }
} 
