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
				Picker("Dönem".localized, selection: $selectedPeriod) {
                    ForEach(AnalysisPeriod.allCases, id: \.self) { period in
                        Text(period.description).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: selectedPeriod) { _ in
                    viewModel.updatePeriod(selectedPeriod)
                }
                
                // Trend Grafiği
                VStack(alignment: .leading, spacing: 12) {
					Text("Harcama Trendi".localized)
                        .font(.headline)
                    
                    Chart {
                        ForEach(viewModel.monthlyTrends) { trend in
                            LineMark(
                                x: .value("Ay", trend.month),
                                y: .value("Tutar", trend.amount)
                            )
                            .foregroundStyle(Color.accentColor)
                            
                            AreaMark(
                                x: .value("Ay", trend.month),
                                y: .value("Tutar", trend.amount)
                            )
                            .foregroundStyle(
                                .linearGradient(
                                    colors: [.accentColor.opacity(0.3), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                    }
                    .frame(height: 200)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
                
                // Kategori Dağılımı
				AnalyticsCategoryPieChart(data: viewModel.periodData)
                
                // Kategori Karşılaştırması
                if !viewModel.categoryComparisons.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
						Text("Kategori Karşılaştırması".localized)
                            .font(.headline)
                        
                        ForEach(viewModel.categoryComparisons) { comparison in
                            CategoryComparisonRow(comparison: comparison)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                }
            }
            .padding(.vertical)
        }
		.navigationTitle("Analiz".localized)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingPremium) {
            PremiumView()
        }
    }
}

struct CategoryComparisonRow: View {
    let comparison: CategoryComparison
    
    private var changePercentage: Double {
        guard comparison.previousAmount > 0 else { return 0 }
        return ((comparison.currentAmount - comparison.previousAmount) / comparison.previousAmount) * 100
    }
    
    var body: some View {
        HStack {
            Label(comparison.category.localizedName, systemImage: comparison.category.icon)
            Spacer()
            VStack(alignment: .trailing) {
                Text(comparison.currentAmount.currencyFormat())
                HStack {
                    Image(systemName: changePercentage >= 0 ? "arrow.up.right" : "arrow.down.right")
                    Text("\(abs(changePercentage), specifier: "%.1f")%")
                }
                .foregroundColor(changePercentage >= 0 ? .red : .green)
                .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AnalyticsCategoryPieChart: View {
    let data: [AnalyticstcsCategorySpending]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
			Text("Kategori Dağılımı".localized)
                .font(.headline)
            
            ForEach(data) { item in
                HStack {
                    Label(item.category.localizedName, systemImage: item.category.icon)
                    Spacer()
                    Text(item.amount.currencyFormat())
                    Text("(\(Int(item.percentage))%)")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
