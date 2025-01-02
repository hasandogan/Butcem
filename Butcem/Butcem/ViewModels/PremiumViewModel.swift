import Foundation
import StoreKit

@MainActor
class PremiumViewModel: ObservableObject {
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let storeManager = StoreKitManager.shared
    
    var monthlyProduct: Product? { storeManager.monthlyProduct }
    var yearlyProduct: Product? { storeManager.yearlyProduct }
    var proProduct: Product? { storeManager.proProduct }
    
    func purchaseProduct(_ product: Product) {
        isLoading = true
        
        Task {
            do {
                try await storeManager.purchase(product)
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }
} 
