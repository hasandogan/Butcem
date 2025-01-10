import SwiftUI
import Charts

struct AdvancedAnalyticsView: View {
    @StateObject private var viewModel = AdvancedAnalyticsViewModel()
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingPremium = false
    
    var body: some View {
        ScrollView {
            if subscriptionManager.canAccessAdvancedAnalytics {
                VStack(spacing: 20) {
                    // Trend Analizi
                    TrendAnalysisCard(viewModel: viewModel)
                    
                    // Kategori Karşılaştırması
                    CategoryComparisonCard(viewModel: viewModel)
                    
                    // Aylık Tahmin
                    MonthlyPredictionCard(viewModel: viewModel)
                    
                    // Tasarruf Analizi
                    SavingsAnalysisCard(viewModel: viewModel)
                }
                .padding()
            } else {
                VStack(spacing: 20) {
					Text("Bu özellik Premium üyelere özeldir".localized)
                        .font(.headline)
                    
					Button("Premium'a Yükselt".localized) {
                        showingPremium = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingPremium) {
            PremiumView()
        }
		.navigationTitle("Gelişmiş Analiz".localized)
    }
}

// MARK: - Alt Görünümler
struct TrendAnalysisCard: View {
    @ObservedObject var viewModel: AdvancedAnalyticsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
			Text("Harcama Trendi".localized)
                .font(.headline)
            
            Chart(viewModel.monthlyTrends) { trend in
                LineMark(
					x: .value("Ay".localized, trend.month),
					y: .value("Tutar".localized, trend.amount)
                )
                .foregroundStyle(Color.accentColor)
                
                AreaMark(
					x: .value("Ay".localized, trend.month),
					y: .value("Tutar".localized, trend.amount)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [.accentColor.opacity(0.3), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .frame(height: 200)
            
            // Trend Özeti
            HStack {
                TrendStatView(
					title: "Aylık Ortalama".localized,
                    value: viewModel.averageSpending,
                    trend: viewModel.spendingTrend
                )
                
                Divider()
                
                TrendStatView(
					title: "En Yüksek Ay".localized,
                    value: viewModel.highestSpending,
                    subtitle: viewModel.highestSpendingMonth
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

struct CategoryComparisonCard: View {
    @ObservedObject var viewModel: AdvancedAnalyticsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
			Text("Kategori Karşılaştırması".localized)
                .font(.headline)
            
            Chart(viewModel.categoryComparisons) { comparison in
                BarMark(
					x: .value("Kategori".localized, comparison.category.rawValue),
					y: .value("Tutar".localized, comparison.currentAmount)
                )
                .foregroundStyle(Color.accentColor)
                
                BarMark(
					x: .value("Kategori".localized, comparison.category.rawValue),
					y: .value("Tutar".localized, comparison.previousAmount)
                )
                .foregroundStyle(Color.gray.opacity(0.3))
            }
            .frame(height: 200)
            
            // Değişim Özeti
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(viewModel.categoryComparisons) { comparison in
                        CategoryChangeView(comparison: comparison)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

struct MonthlyPredictionCard: View {
    @ObservedObject var viewModel: AdvancedAnalyticsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
			Text("Gelecek Ay Tahmini".localized)
                .font(.headline)
            
            HStack(spacing: 20) {
                PredictionStatView(
					title: "Tahmini Harcama".localized,
                    value: viewModel.predictedSpending,
                    trend: viewModel.predictedTrend
                )
                
                PredictionStatView(
					title: "Tahmini Tasarruf".localized,
                    value: viewModel.predictedSaving,
                    trend: viewModel.savingTrend
                )
            }
            
            // Kategori bazlı tahminler
            VStack(spacing: 10) {
                ForEach(viewModel.categoryPredictions) { prediction in
                    CategoryPredictionRow(prediction: prediction)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

struct SavingsAnalysisCard: View {
    @ObservedObject var viewModel: AdvancedAnalyticsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
			Text("Tasarruf Analizi".localized)
                .font(.headline)
            
            // Tasarruf Hedefi İlerleme
            VStack(alignment: .leading, spacing: 8) {
                HStack {
					Text("Aylık Tasarruf Hedefi".localized)
                        .font(.subheadline)
                    Spacer()
                    Text(viewModel.savingsGoal.currencyFormat())
                        .font(.headline)
                }
                
                ProgressView(value: viewModel.savingsProgress, total: 1.0)
                    .tint(viewModel.savingsProgress >= 1.0 ? .green : .blue)
                
                Text("\(Int(viewModel.savingsProgress * 100))% tamamlandı")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Tasarruf Önerileri
            VStack(alignment: .leading, spacing: 10) {
				Text("Tasarruf Önerileri".localized)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                ForEach(viewModel.savingsSuggestions, id: \.self) { suggestion in
                    HStack(spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        Text(suggestion)
                            .font(.subheadline)
                    }
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

struct CategoryPredictionRow: View {
    let prediction: CategoryPrediction
    
    var body: some View {
        HStack {
            // Kategori İkonu ve İsmi
            HStack(spacing: 12) {
                Image(systemName: prediction.category.icon)
                    .foregroundColor(.accentColor)
                    .frame(width: 24)
                
				Text(prediction.category.localizedName)
                    .font(.subheadline)
            }
            
            Spacer()
            
            // Tahmin ve Güven Oranı
            VStack(alignment: .trailing, spacing: 4) {
                Text(prediction.predictedAmount.currencyFormat())
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                // Güven Oranı Göstergesi
                HStack(spacing: 4) {
					Text("Güven:".localized)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(prediction.confidence * 100))%")
                        .font(.caption2)
                        .foregroundColor(confidenceColor)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var confidenceColor: Color {
        switch prediction.confidence {
        case 0.8...:
            return .green
        case 0.6..<0.8:
            return .orange
        default:
            return .red
        }
    }
}

// MARK: - Yardımcı Görünümler
struct TrendStatView: View {
    let title: String
    let value: Double
    var trend: Double? = nil
    var subtitle: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline) {
				Text(value.currencyFormat())
                    .font(.headline)
                
                if let trend = trend {
                    Image(systemName: trend > 0 ? "arrow.up.right" : "arrow.down.right")
                        .foregroundColor(trend > 0 ? .red : .green)
                }
            }
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct CategoryChangeView: View {
    let comparison: CategoryComparison
    
    var changePercentage: Double {
        ((comparison.currentAmount - comparison.previousAmount) / comparison.previousAmount) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
			Text(comparison.category.localizedName)
                .font(.subheadline)
            
            HStack {
                Image(systemName: changePercentage > 0 ? "arrow.up.right" : "arrow.down.right")
                Text("\(abs(changePercentage), specifier: "%.1f")%")
            }
            .font(.caption)
            .foregroundColor(changePercentage > 0 ? .red : .green)
        }
    }
}

struct PredictionStatView: View {
    let title: String
    let value: Double
    let trend: Double?
    let subtitle: String?
    
    init(
        title: String,
        value: Double,
        trend: Double? = nil,
        subtitle: String? = nil
    ) {
        self.title = title
        self.value = value
        self.trend = trend
        self.subtitle = subtitle
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline) {
                Text(value.currencyFormat())
                    .font(.headline)
                
                if let trend = trend {
                    Image(systemName: trend > 0 ? "arrow.up.right" : "arrow.down.right")
                        .foregroundColor(trend > 0 ? .red : .green)
                }
            }
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        AdvancedAnalyticsView()
    }
} 
