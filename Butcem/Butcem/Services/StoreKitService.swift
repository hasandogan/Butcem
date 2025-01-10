import StoreKit
import Foundation

@MainActor
class StoreKitService {
    static let shared = StoreKitService()
    private var cachedProducts: [Product]?
    private init() {}
    
    func checkSubscriptionStatus() async -> SubscriptionInfo {
        do {
            // Önce ürünleri yükle
            if cachedProducts == nil {
                cachedProducts = try await loadProducts()
            }
            
            for await result in StoreKit.Transaction.currentEntitlements {
                guard case .verified(let transaction) = result else {
                    continue
                }
                
                // Abonelik aktif mi kontrol et
                guard transaction.revocationDate == nil,
                      !transaction.isUpgraded else {
                    continue
                }
                
                // Aboneliğin süresi dolmuş mu kontrol et
                if let expirationDate = transaction.expirationDate,
                   expirationDate < .now {
                    continue
                }
                
                print("✅ Active subscription found: \(transaction.productID)")
                print("📅 Expiration date: \(transaction.expirationDate?.description ?? "none")")
                
                // Ürün bilgisini ve fiyatı bul
                let product = cachedProducts?.first(where: { $0.id == transaction.productID })
                let price = (product?.price as NSDecimalNumber?)?.doubleValue ?? 0.0
                
                print("💰 Product price: \(price)")
                
                // Abonelik türünü belirle
                let (planName, billingPeriod): (String, SubscriptionInfo.BillingPeriod)
                switch transaction.productID {
                case "Butce.month":
                    planName = "Aylık Premium"
                    billingPeriod = .monthly
                case "butce.year":
                    planName = "Yıllık Premium"
                    billingPeriod = .yearly
                case "butce.pro":
                    planName = "Pro Plan"
                    billingPeriod = .lifetime
                default:
                    continue
                }
                
                return SubscriptionInfo(
                    isActive: true,
                    planName: planName,
                    endDate: transaction.expirationDate,
                    startDate: transaction.purchaseDate,
                    price: price,
                    billingPeriod: billingPeriod
                )
            }
            
            print("ℹ️ No active subscription found")
            return .free
            
        } catch {
            print("❌ Error checking subscription status: \(error.localizedDescription)")
            return .free
        }
    }
    
    // Ürünleri yükle
    func loadProducts() async throws -> [Product] {
        let productIdentifiers = ["Butce.month", "butce.year", "butce.pro"]
        let products = try await Product.products(for: productIdentifiers)
        
        // Debug için fiyatları yazdır
        for product in products {
            print("📦 Product: \(product.id)")
            print("💰 Price: \((product.price as NSDecimalNumber).doubleValue)")
            print("📝 Description: \(product.description)")
        }
        
        return products
    }
    
    // Satın alma işlemi
    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                await transaction.finish()
                return transaction
            case .unverified:
                return nil
            }
        case .userCancelled, .pending:
            return nil
        @unknown default:
            return nil
        }
    }
    
    // Restore işlemi
    func restorePurchases() async throws {
        try await AppStore.sync()
    }
    
    // Abonelik durumunu dinle
    func listenForTransactionUpdates() async {
		for await verificationResult in StoreKit.Transaction.updates {
            guard case .verified(let transaction) = verificationResult else {
                continue
            }
            
            // İşlemi tamamla
            await transaction.finish()
            
            // Abonelik durumunu güncelle
            Task { @MainActor in
                _ = await checkSubscriptionStatus()
            }
        }
    }
    
    // Anlık durum kontrolü
    func verifySubscriptionImmediately() async -> SubscriptionInfo {
        // Mevcut transaction'ları temizle
        for await result in StoreKit.Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                await transaction.finish()
            }
        }
        
        // Yeni durumu kontrol et
        return await checkSubscriptionStatus()
    }
} 
