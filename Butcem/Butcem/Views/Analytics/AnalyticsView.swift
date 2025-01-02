import SwiftUI
import Charts

struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedPeriod: AnalysisPeriod = .monthly
    @State private var showingPremium = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Dönem Seçici
                Picker("Dönem", selection: $selectedPeriod) {
                    ForEach(AnalysisPeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: selectedPeriod) { _ in
                    viewModel.updatePeriod(selectedPeriod)
                }
                
                // Gelişmiş Analiz Butonu
                NavigationLink {
                    if subscriptionManager.canAccessAdvancedAnalytics {
                        AdvancedAnalyticsView()
                    } else {
                        PremiumView()
                    }
                } label: {
                    HStack {
                        Image(systemName: "chart.xyaxis.line")
                        Text("Gelişmiş Analiz")
                        Spacer()
                        if !subscriptionManager.canAccessAdvancedAnalytics {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                        } else {
                            Image(systemName: "chevron.right")
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                }
                .padding(.horizontal)
                
                // Grafikler
                ZStack {
                    VStack(spacing: 16) {
                        IncomeExpenseChart(data: viewModel.periodData)
                        CategoryPieChart(data: viewModel.categoryData)
                        TrendChart(data: viewModel.trendData)
                        SavingsRateCard(rate: viewModel.savingsRate)
                    }
                    
                    if subscriptionManager.currentTier == .basic {
                        // Bulanık overlay
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .overlay {
                                VStack(spacing: 12) {
                                    Image(systemName: "crown.fill")
                                        .font(.largeTitle)
                                        .foregroundColor(.yellow)
                                    
                                    Text("Premium Özellik")
                                        .font(.headline)
                                    
                                    Text("Detaylı analiz ve raporlara erişmek için Premium'a yükseltin")
                                        .font(.subheadline)
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.secondary)
                                    
                                    Button("Premium'a Yükselt") {
										showingPremium = true
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .padding(.top)
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .shadow(radius: 5)
                                .padding()
                            }
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Analiz")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingPremium) {
            PremiumView()
        }
        .navigationDestination(isPresented: $viewModel.showAdvancedAnalytics) {
            AdvancedAnalyticsView()
        }
    }
}
