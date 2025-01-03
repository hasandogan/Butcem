import SwiftUI

struct PremiumView: View {
	@Environment(\.dismiss) var dismiss
	@StateObject private var viewModel = PremiumViewModel()
	
	var body: some View {
		ScrollView {
			VStack(spacing: 30) {
				// Header
				VStack(spacing: 15) {
					Image(systemName: "star.circle.fill")
						.font(.system(size: 60))
						.foregroundColor(.yellow)
					
					Text("Premium'a Yükseltin")
						.font(.title)
						.fontWeight(.bold)
					
					Text("Tüm özelliklere erişin ve finansal hedeflerinize daha hızlı ulaşın")
						.multilineTextAlignment(.center)
						.foregroundColor(.secondary)
				}
				
				// Özellikler
				VStack(spacing: 20) {
					FeatureRow(icon: "chart.bar.fill", title: "Gelişmiş Analitik", description: "Detaylı grafik ve analizlerle finansal durumunuzu daha iyi anlayın")
					FeatureRow(icon: "target", title: "Bütçe Planlama", description: "Kategori bazlı limitler ve otomatik önerilerle bütçenizi kontrol altında tutun")
					FeatureRow(icon: "bell.fill", title: "Hatırlatıcılar", description: "Fatura ve ödemeleri asla kaçırmayın")
					FeatureRow(icon: "arrow.triangle.2.circlepath", title: "Tekrarlayan İşlemler", description: "Düzenli ödemelerinizi otomatik olarak takip edin")
					FeatureRow(icon: "square.and.arrow.up.circle.fill", title: "Çıktılar", description: "Harcamalarınızın pdf ve excel formatında çıktısın alabilirsiniz")
				}
				.padding()
				.background(Color(.systemBackground))
				.cornerRadius(12)
				.shadow(radius: 5)
				
				// Fiyatlandırma
				VStack(spacing: 15) {
					// Aylık Plan
					if let monthlyProduct = viewModel.monthlyProduct {
						PlanCard(
							title: "Aylık Premium",
							price: monthlyProduct.displayPrice,
							period: "ay",
							features: [
								"Gelişmiş analitik",
								"Bütçe planlama",
								"Fatura hatırlatıcıları",
								"Tekrarlayan işlemler",
								"Çıktılar"
							],
							action: {
								Task {
									do {
										try await viewModel.purchaseProduct(monthlyProduct)
										await SubscriptionManager.shared.refresh()
										dismiss()
									} catch {
										// Hata yönetimi
									}
								}
							}
						)
					}
					
					// Yıllık Plan
					if let yearlyProduct = viewModel.yearlyProduct {
						PlanCard(
							title: "Yıllık Premium",
							price: yearlyProduct.displayPrice,
							period: "yıl",
							features: [
								"Tüm aylık özellikleri",
								"2 ay bedava",
							],
							isPro: false,
							action: {
								Task {
									try? await viewModel.purchaseProduct(yearlyProduct)
								}
							}
						)
					}
					
					// Pro Plan
					if let proProduct = viewModel.proProduct {
						PlanCard(
							title: "Pro",
							price: proProduct.displayPrice,
							period: "yıllık",
							features: [
								"Tüm Premium özellikleri",
								"Aile/grup bütçesi",
							],
							isPro: true,
							action: {
								Task {
									try? await viewModel.purchaseProduct(proProduct)
								}
							}
						)
					}
				}
			}
			.padding()
		}
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			ToolbarItem(placement: .navigationBarTrailing) {
				Button("Kapat") {
					dismiss()
				}
			}
		}
		.alert("Hata", isPresented: $viewModel.showError) {
			Button("Tamam", role: .cancel) { }
		} message: {
			if let error = viewModel.errorMessage {
				Text(error)
			}
		}
		.overlay {
			if viewModel.isLoading {
				ProgressView()
					.padding()
					.background(Color(.systemBackground))
					.cornerRadius(8)
					.shadow(radius: 2)
			}
		}
	}
}

struct FeatureRow: View {
	let icon: String
	let title: String
	let description: String
	
	var body: some View {
		HStack(spacing: 15) {
			Image(systemName: icon)
				.font(.title2)
				.foregroundColor(.accentColor)
				.frame(width: 40)
			
			VStack(alignment: .leading, spacing: 5) {
				Text(title)
					.font(.headline)
				
				Text(description)
					.font(.subheadline)
					.foregroundColor(.secondary)
			}
		}
	}
}

struct PlanCard: View {
	let title: String
	let price: String
	let period: String
	let features: [String]
	var isPro: Bool = false
	let action: () -> Void
	
	var body: some View {
		VStack(spacing: 20) {
			Text(title)
				.font(.title2)
				.fontWeight(.bold)
			
			HStack(alignment: .firstTextBaseline) {
				Text(price)
					.font(.title)
					.fontWeight(.bold)
				
				Text("/" + period)
					.foregroundColor(.secondary)
			}
			
			VStack(alignment: .leading, spacing: 10) {
				ForEach(features, id: \.self) { feature in
					HStack {
						Image(systemName: "checkmark.circle.fill")
							.foregroundColor(.green)
						Text(feature)
					}
				}
			}
			
			Button(action: action) {
				Text("Hemen Başla")
					.font(.headline)
					.frame(maxWidth: .infinity)
					.padding()
					.background(isPro ? Color.accentColor : Color.blue)
					.foregroundColor(.white)
					.cornerRadius(12)
			}
		}
		.padding()
		.background(Color(.systemBackground))
		.cornerRadius(16)
		.shadow(radius: 5)
	}
}

struct PremiumFeatureRow: View {
	let feature: PremiumFeature
	
	var body: some View {
		HStack {
			Image(systemName: feature.icon)
				.foregroundColor(.yellow)
			Text(feature.description)
			Spacer()
		}
	}
}

enum PremiumFeature {
	case export
	case advancedAnalytics
	case notifications
	// ... diğer özellikler
	
	var icon: String {
		switch self {
		case .export: return "square.and.arrow.up"
		case .advancedAnalytics: return "chart.bar.xaxis"
		case .notifications: return "bell.fill"
		}
	}
	
	var description: String {
		switch self {
		case .export: return "İşlem geçmişini Excel ve PDF olarak dışa aktar"
		case .advancedAnalytics: return "Gelişmiş analiz ve raporlama"
		case .notifications: return "Özelleştirilmiş bildirimler"
		}
	}
}

