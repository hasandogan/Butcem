import SwiftUI

struct PremiumFeatureModifier: ViewModifier {
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingPremiumAlert = false
    let feature: SubscriptionTier
    
    func body(content: Content) -> some View {
        content
            .disabled(subscriptionManager.currentTier == .basic)
            .overlay {
                if subscriptionManager.currentTier == .basic {
                    Color.black.opacity(0.1)
                        .onTapGesture {
                            showingPremiumAlert = true
                        }
                }
            }
            .alert("Premium Özellik", isPresented: $showingPremiumAlert) {
                Button("Yükselt") {
                    // Premium sayfasına yönlendir
                }
                Button("İptal", role: .cancel) {}
            } message: {
                Text("Bu özellik Premium üyelere özeldir. Hemen yükseltin!")
            }
    }
}

extension View {
    func premiumFeature(_ tier: SubscriptionTier = .premium) -> some View {
        modifier(PremiumFeatureModifier(feature: tier))
    }
} 