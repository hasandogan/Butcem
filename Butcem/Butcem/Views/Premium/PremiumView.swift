import SwiftUI

struct PremiumView: View {
	@Environment(\.dismiss) var dismiss
	@StateObject private var viewModel = PremiumViewModel()
	
	var body: some View {
		ScrollView {
			VStack(spacing: 24) {
				// Header
				headerSection
				
				// Features
				featuresSection
					.padding(.horizontal)
				
				// Plans
				plansSection
					.padding(.horizontal)
				
				// Links
				linksSection
					.padding(.top, 8)
			}
			.padding(.vertical)
		}
		.background(Color(.systemGroupedBackground))
		.overlay {
			if viewModel.isLoading {
				ZStack {
					Color.black.opacity(0.3)
						.ignoresSafeArea()
					ProgressView()
						.padding()
						.background(Color(.systemBackground))
						.cornerRadius(10)
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
		.toolbar {
			ToolbarItem(placement: .navigationBarTrailing) {
				Button {
					dismiss()
				} label: {
					Image(systemName: "xmark.circle.fill")
						.foregroundStyle(.gray)
						.font(.title3)
				}
			}
		}
	}
	
	private var headerSection: some View {
		VStack(spacing: 20) {
			ZStack {
				Circle()
					.fill(LinearGradient(
						colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					))
					.frame(width: 100, height: 100)
				
				Image(systemName: "star.circle.fill")
					.font(.system(size: 50))
					.foregroundStyle(.linearGradient(
						colors: [.yellow, .orange],
						startPoint: .top,
						endPoint: .bottom
					))
			}
			
			Text("Premium'a Yükseltin".localized)
				.font(.title)
				.fontWeight(.bold)
				.foregroundStyle(.linearGradient(
					colors: [.blue, .purple],
					startPoint: .leading,
					endPoint: .trailing
				))
			
			Text("Tüm özelliklere erişin ve finansal hedeflerinize daha hızlı ulaşın")
				.multilineTextAlignment(.center)
				.foregroundColor(.secondary)
				.padding(.horizontal)
		}
		.padding(20)
		.background(
			RoundedRectangle(cornerRadius: 20)
				.fill(Color(.systemBackground))
				.shadow(radius: 10, x: 0, y: 5)
		)
	}
	
	private var featuresSection: some View {
		VStack(spacing: 16) {
			FeatureRow(
				icon: "chart.bar.fill",
				title: "Gelişmiş Analitikler",
				description: "Detaylı finansal analizler ve öngörüler"
			)
				.frame(maxWidth: .infinity)
			
			FeatureRow(
				icon: "bell.fill",
				title: "Sınırsız Hatırlatıcı",
				description: "İstediğiniz kadar hatırlatıcı oluşturun"
			)
				.frame(maxWidth: .infinity)
			
			FeatureRow(
				icon: "person.2.fill",
				title: "Aile Bütçesi",
				description: "Ailenizle birlikte bütçe yönetimi"
			)
				.frame(maxWidth: .infinity)
			
			FeatureRow(
				icon: "arrow.up.right.circle.fill",
				title: "Gelişmiş İhracat",
				description: "Verilerinizi PDF ve Excel formatında dışa aktarın"
			)
				.frame(maxWidth: .infinity)
		}
		.padding()
		.background(Color(.systemBackground))
		.cornerRadius(12)
	}
	
	private var plansSection: some View {
		VStack(alignment: .leading, spacing: 20) {
			Text("Üyelik Planları")
				.font(.title2)
				.fontWeight(.bold)
				.padding(.horizontal)
			
			// Aylık Plan
			PlanCard(
				title: "Aylık Premium".localized,
				price: viewModel.monthlyProduct?.displayPrice ?? "29,99 ₺",
				period: "ay",
				features: [
					"Gelişmiş analitik".localized,
					"Bütçe planlama".localized,
					"Fatura hatırlatıcıları".localized,
					"Tekrarlayan işlemler".localized,
					"Çıktılar".localized
				],
				action: {
					if let product = viewModel.monthlyProduct {
						Task {
							try? await viewModel.purchaseProduct(product)
						}
					}
				}
			)
			
			// Yıllık Plan
			PlanCard(
				title: "Yıllık Premium".localized,
				price: viewModel.yearlyProduct?.displayPrice ?? "299,99 ₺",
				period: "yıl",
				features: [
					"Tüm aylık özellikleri".localized,
					"2 ay bedava".localized,
				],
				isPopular: true,
				action: {
					if let product = viewModel.yearlyProduct {
						Task {
							try? await viewModel.purchaseProduct(product)
						}
					}
				}
			)
			
			// Pro Plan
			PlanCard(
				title: "Pro",
				price: viewModel.proProduct?.displayPrice ?? "499,99 ₺",
				period: "yıllık".localized,
				features: [
					"Tüm Premium özellikleri".localized,
					"Aile/grup bütçesi".localized,
					"family-sharing ile bütün aileye ücretsiz erişim"
				],
				isPro: true,
				action: {
					if let product = viewModel.proProduct {
						Task {
							try? await viewModel.purchaseProduct(product)
						}
					}
				}
			)
		}
	}
	
	private var linksSection: some View {
		VStack(spacing: 12) {
			Link(destination: URL(string: "https://hasandgn.com/kullanici-sozlesmesi")!) {
				Text("Kullanıcı Sözleşmesi")
					.font(.footnote)
					.foregroundColor(.secondary)
			}
			
			Link(destination: URL(string: "https://hasandgn.com/gizlilik-politikasi")!) {
				Text("Gizlilik Politikası")
					.font(.footnote)
					.foregroundColor(.secondary)
			}
		}
		.padding(.horizontal)
	}
}

struct FeatureRow: View {
	let icon: String
	let title: String
	let description: String
	
	var body: some View {
		HStack(spacing: 16) {
			Image(systemName: icon)
				.font(.title2)
				.foregroundColor(.accentColor)
				.frame(width: 32)
			
			VStack(alignment: .leading, spacing: 4) {
				Text(title)
					.font(.headline)
				
				Text(description)
					.font(.subheadline)
					.foregroundColor(.secondary)
			}
			
			Spacer()
		}
		.padding()
		.background(Color(.secondarySystemBackground))
		.cornerRadius(12)
	}
}

struct PlanCard: View {
	let title: String
	let price: String
	let period: String
	let features: [String]
	var isPopular: Bool = false
	var isPro: Bool = false
	let action: () -> Void
	
	var body: some View {
		VStack(spacing: 20) {
			if isPopular {
				Text("En Popüler")
					.font(.caption)
					.fontWeight(.medium)
					.foregroundColor(.white)
					.padding(.horizontal, 12)
					.padding(.vertical, 6)
					.background(Color.orange)
					.cornerRadius(20)
			}
			
			Text(title)
				.font(.title2)
				.fontWeight(.bold)
			
			HStack(alignment: .firstTextBaseline, spacing: 0) {
				Text(price)
					.font(.title)
					.fontWeight(.bold)
				
				Text("/" + period)
					.foregroundColor(.secondary)
			}
			
			VStack(alignment: .leading, spacing: 12) {
				ForEach(features, id: \.self) { feature in
					HStack(spacing: 12) {
						Image(systemName: "checkmark.circle.fill")
							.foregroundColor(.green)
						Text(feature)
							.font(.subheadline)
					}
				}
			}
			.padding(.vertical)
			
			Button(action: action) {
				Text("Hemen Başla")
					.font(.headline)
					.frame(maxWidth: .infinity)
					.padding()
					.background(
						LinearGradient(
							colors: isPro ? [.purple, .blue] : [.blue, .cyan],
							startPoint: .leading,
							endPoint: .trailing
						)
					)
					.foregroundColor(.white)
					.cornerRadius(15)
			}
		}
		.padding(20)
		.background(
			RoundedRectangle(cornerRadius: 20)
				.fill(Color(.systemBackground))
				.shadow(
					color: isPopular ? .orange.opacity(0.2) : .gray.opacity(0.2),
					radius: 15,
					x: 0,
					y: 5
				)
		)
		.overlay(
			RoundedRectangle(cornerRadius: 20)
				.stroke(
					isPopular ? Color.orange.opacity(0.5) : 
					isPro ? Color.purple.opacity(0.5) : Color.clear,
					lineWidth: 2
				)
		)
		.scaleEffect(isPopular ? 1.02 : 1.0)
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

extension View {
	func premiumCardStyle() -> some View {
		self
			.padding(20)
			.background(
				RoundedRectangle(cornerRadius: 20)
					.fill(Color(.systemBackground))
					.shadow(radius: 10, x: 0, y: 5)
			)
	}
	
	func premiumSectionTitle() -> some View {
		self
			.font(.title2)
			.fontWeight(.bold)
			.padding(.horizontal)
	}
}

