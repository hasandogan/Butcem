import SwiftUI

struct MainTabView: View {
	@StateObject private var authManager = AuthManager.shared
	@ObservedObject private var subscriptionManager = SubscriptionManager.shared
	
	var body: some View {
		TabView {
			NavigationView {
				DashboardView()
			}
			.navigationViewStyle(StackNavigationViewStyle())
			.tabItem {
				Label("Ana Sayfa".localized, systemImage: "house.fill")
			}
			
			NavigationView {
				TransactionsView()
			}
			.navigationViewStyle(StackNavigationViewStyle())
			.tabItem {
				Label("İşlemler".localized, systemImage: "list.bullet")
			}
			
			NavigationView {
				BudgetView()
			}
			.navigationViewStyle(StackNavigationViewStyle())
			.tabItem {
				Label("Bütçe".localized, systemImage: "chart.pie.fill")
			}
			
			NavigationView {
				FinancialGoalsView()
			}
			.navigationViewStyle(StackNavigationViewStyle())
			.tabItem {
				Label("Hedefler".localized, systemImage: "target")
			}
			
			NavigationView {
				if subscriptionManager.canAccessPremiumFeatures {
					RecurringTransactionsView()
				} else {
					PremiumView()
				}
			}
			.navigationViewStyle(StackNavigationViewStyle())
			.tabItem {
				Label("Tekrarlayan İşlemler".localized, systemImage: "arrow.2.squarepath")
			}
			
			NavigationView {
				if subscriptionManager.canAccessProFeatures {
					FamilyBudgetView()
				} else {
					ProFeatureLockedView(feature: .familyBudget)
				}
			}
			.navigationViewStyle(StackNavigationViewStyle())
			.tabItem {
				Label("Aile Bütçesi".localized, systemImage: "person.3.fill")
			}
			
			NavigationView {
				if subscriptionManager.canAccessPremiumFeatures {
				RemindersView()
				} else {
					PremiumView()
				}
			}
			.navigationViewStyle(StackNavigationViewStyle())
			.tabItem {
				Label("Hatırlatıcı".localized, systemImage: "bell.fill")
			}
			
			NavigationView {
				if subscriptionManager.canAccessPremiumFeatures {
					AnalyticsView()
				} else {
					PremiumView()
				}
			}
			.navigationViewStyle(StackNavigationViewStyle())
			.tabItem {
				Label("Analiz".localized, systemImage: "chart.bar.fill")
			}
			
			NavigationView {
				if subscriptionManager.canAccessPremiumFeatures {
					AnalysisView()
				} else {
					PremiumView()
				}
			}
			.navigationViewStyle(StackNavigationViewStyle())
			.tabItem {
				Label("Gelişmiş Analiz".localized, systemImage: "chart.bar.fill")
			}
			
			
			NavigationView {
				if subscriptionManager.canAccessPremiumFeatures {
					ExportView()
				} else {
					PremiumView()
				}
			}
			.navigationViewStyle(StackNavigationViewStyle())
			.tabItem {
				Label("Çıktılar".localized, systemImage: "square.and.arrow.up.circle.fill")
			}
			NavigationView {
				SettingsView()
			}
			.navigationViewStyle(StackNavigationViewStyle())
			.tabItem {
				Label("Ayarlar".localized, systemImage: "gearshape.fill")
			}
		}
	}
}

struct ProFeatureLockedView: View {
	@State private var showingPremium = false
	let feature: ProFeature
	
	enum ProFeature {
		case familyBudget
		
		var title: String {
			switch self {
			case .familyBudget: return "Aile Bütçesi"
			}
		}
		
		var description: String {
			switch self {
			case .familyBudget: return "Ailenizle birlikte harcamalarınızı takip edin ve ortak bütçe oluşturun"
			}
		}
		
		var icon: String {
			switch self {
			case .familyBudget: return "person.3.fill"
			}
		}
	}
	
	var body: some View {
		VStack(spacing: 20) {
			Image(systemName: feature.icon)
				.font(.system(size: 60))
				.foregroundColor(.gray)
			
			Text(feature.title)
				.font(.title2)
				.fontWeight(.bold)
			
			Text(feature.description)
				.multilineTextAlignment(.center)
				.foregroundColor(.secondary)
				.padding(.horizontal)
			
			Button {
				showingPremium = true
			} label: {
				HStack {
					Image(systemName: "crown.fill")
						.foregroundColor(.yellow)
					Text("Pro'ya Yükselt")
				}
				.font(.headline)
				.frame(maxWidth: .infinity)
				.padding()
				.background(Color.accentColor)
				.foregroundColor(.white)
				.cornerRadius(12)
			}
			.padding(.horizontal)
		}
		.padding()
		.sheet(isPresented: $showingPremium) {
			PremiumView()
		}
	}
}
