import SwiftUI
import Charts

struct AnalysisView: View {
	@StateObject private var viewModel = AnalysisViewModel()
	
	var body: some View {
		ScrollView {
			LazyVStack(spacing: 20) {
				// Aylık Özet Kartı
				if let monthlyAnalysis = viewModel.monthlyAnalysis {
					MonthlyAnalysisCard(analysis: monthlyAnalysis)
				}
				
				// Trend Analizi
				if let trendAnalysis = viewModel.trendAnalysis {
					AdvTrendAnalysisCard(analysis: trendAnalysis)
				}
				
				// Kategori Analizi
				if !viewModel.categoryAnalysis.isEmpty {
					CategoryAnalysisCard(analyses: viewModel.categoryAnalysis)
				}
				
				// Tasarruf Analizi
				if let savingsAnalysis = viewModel.savingsAnalysis {
					advSavingsAnalysisCard(analysis: savingsAnalysis)
				}
				
				// Tahmin Analizi
				if !viewModel.predictionAnalysis.isEmpty {
					PredictionAnalysisCard(predictions: viewModel.predictionAnalysis)
				}
			}
			.padding()
		}
		.navigationTitle("Gelişmiş Analiz")
		.task {
			await viewModel.loadAnalysisData()
		}
		.refreshable {
			await viewModel.loadAnalysisData()
		}
	}
}

// MARK: - Alt Görünümler
struct MonthlyAnalysisCard: View {
	let analysis: MonthlyAnalysis
	
	var body: some View {
		VStack(alignment: .leading, spacing: 16) {
			Text("Aylık Özet")
				.font(.headline)
			
			HStack {
				StatisticView(
					title: "Gelir".localized,
					value: analysis.totalIncome.currencyFormat(),
					icon: "arrow.up.circle.fill",
					color: .green
				)
				
				Divider()
				
				StatisticView(
					title: "Gider".localized,
					value: analysis.totalExpense.currencyFormat(),
					icon: "arrow.down.circle.fill",
					color: .red
				)
			}
			
			Divider()
			
			HStack {
				StatisticView(
					title: "Net".localized,
					value: analysis.netAmount.currencyFormat(),
					icon: "equal.circle.fill",
					color: .blue
				)
				
				Divider()
				
				StatisticView(
					title: "Tasarruf Oranı".localized,
					value: String(format: "%.1f%%", analysis.savingsRate),
					icon: "percent",
					color: .purple
				)
			}
		}
		.padding()
		.background(Color(.systemBackground))
		.cornerRadius(12)
		.shadow(radius: 2)
	}
}

struct AdvTrendAnalysisCard: View {
	let analysis: TrendAnalysis
	
	var body: some View {
		VStack(alignment: .leading, spacing: 16) {
			Text("Trend Analizi")
				.font(.headline)
			
			Chart {
				ForEach(analysis.monthlyTrends, id: \.month) { trend in
					LineMark(
						x: .value("Ay", trend.month),
						y: .value("Gelir", trend.income)
					)
					.foregroundStyle(.green)
					
					LineMark(
						x: .value("Ay", trend.month),
						y: .value("Gider", trend.expense)
					)
					.foregroundStyle(.red)
					
					LineMark(
						x: .value("Ay", trend.month),
						y: .value("Tasarruf", trend.savings)
					)
					.foregroundStyle(.blue)
				}
			}
			.frame(height: 200)
			
			HStack {
				LegendItem(color: .green, text: "Gelir")
				LegendItem(color: .red, text: "Gider")
				LegendItem(color: .blue, text: "Tasarruf")
			}
			
			VStack(spacing: 8) {
				AverageRow(title: "Ortalama Gelir".localized, value: analysis.averageIncome)
				AverageRow(title: "Ortalama Gider".localized, value: analysis.averageExpense)
				AverageRow(title: "Ortalama Tasarruf".localized, value: analysis.averageSavings)
			}
		}
		.padding()
		.background(Color(.systemBackground))
		.cornerRadius(12)
		.shadow(radius: 2)
	}
}

struct CategoryAnalysisCard: View {
	let analyses: [CategoryAnalysis]
	
	var body: some View {
		VStack(alignment: .leading, spacing: 16) {
			Text("Kategori Analizi".localized)
				.font(.headline)
			
			ForEach(analyses, id: \.category) { analysis in
				CategoryAnalysisRow(analysis: analysis)
			}
		}
		.padding()
		.background(Color(.systemBackground))
		.cornerRadius(12)
		.shadow(radius: 2)
	}
}

struct advSavingsAnalysisCard: View {
	let analysis: SavingsAnalysis
	
	var body: some View {
		VStack(alignment: .leading, spacing: 16) {
			Text("Tasarruf Analizi")
				.font(.headline)
			
			Chart {
				ForEach(analysis.monthlySavingsHistory, id: \.month) { data in
					BarMark(
						x: .value("Ay", data.month),
						y: .value("Tasarruf", data.amount)
					)
					.foregroundStyle(data.amount >= 0 ? .green : .red)
				}
			}
			.frame(height: 200)
			
			VStack(spacing: 8) {
				StatRow(title: "Toplam Tasarruf".localized, value: analysis.totalSavings)
				StatRow(title: "Aylık Ortalama".localized, value: analysis.averageMonthlySavings)
				StatRow(title: "Yıllık Projeksiyon".localized, value: analysis.projectedAnnualSavings)
			}
		}
		.padding()
		.background(Color(.systemBackground))
		.cornerRadius(12)
		.shadow(radius: 2)
	}
}

struct PredictionAnalysisCard: View {
	let predictions: [PredictionAnalysis]
	
	var body: some View {
		VStack(alignment: .leading, spacing: 16) {
			Text("Gelecek Ay Tahminleri".localized)
				.font(.headline)
			
			ForEach(predictions, id: \.category) { prediction in
				PredictionRow(prediction: prediction)
			}
		}
		.padding()
		.background(Color(.systemBackground))
		.cornerRadius(12)
		.shadow(radius: 2)
	}
}

// MARK: - Yardımcı Görünümler
struct StatisticView: View {
	let title: String
	let value: String
	let icon: String
	let color: Color
	
	var body: some View {
		VStack(spacing: 8) {
			Image(systemName: icon)
				.foregroundColor(color)
				.font(.title2)
			
			Text(title)
				.font(.caption)
				.foregroundColor(.secondary)
			
			Text(value)
				.font(.headline)
				.foregroundColor(color)
		}
	}
}

struct CategoryAnalysisRow: View {
	let analysis: CategoryAnalysis
	
	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			HStack {
				Label(analysis.category.localizedName, systemImage: analysis.category.icon)
				Spacer()
				TrendBadge(trend: analysis.trend)
			}
			
			HStack {
				Text(analysis.totalAmount.currencyFormat())
					.font(.headline)
				Spacer()
				Text("\(analysis.transactionCount) işlem".localized)
					.font(.caption)
					.foregroundColor(.secondary)
			}
		}
		.padding(.vertical, 4)
	}
}

struct PredictionRow: View {
	let prediction: PredictionAnalysis
	
	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			HStack {
				Label(prediction.category.localizedName, systemImage: prediction.category.icon)
				Spacer()
				ConfidenceBadge(confidence: prediction.confidence)
			}
			
			HStack {
				VStack(alignment: .leading) {
					Text("Tahmin")
						.font(.caption)
					Text(prediction.predictedAmount.currencyFormat())
						.font(.headline)
				}
				
				Spacer()
				
				VStack(alignment: .trailing) {
					Text("Ortalama")
						.font(.caption)
					Text(prediction.historicalAverage.currencyFormat())
						.font(.subheadline)
				}
			}
		}
		.padding(.vertical, 4)
	}
}

struct TrendBadge: View {
	let trend: TrendDirection
	
	var body: some View {
		HStack {
			Image(systemName: trend == .increasing ? "arrow.up.right" :
					trend == .decreasing ? "arrow.down.right" : "arrow.right")
			Text(trend == .increasing ? "Artıyor" :
					trend == .decreasing ? "Azalıyor" : "Sabit")
		}
		.font(.caption)
		.padding(.horizontal, 8)
		.padding(.vertical, 4)
		.background(
			trend == .increasing ? Color.red.opacity(0.2) :
				trend == .decreasing ? Color.green.opacity(0.2) :
				Color.gray.opacity(0.2)
		)
		.foregroundColor(
			trend == .increasing ? .red :
				trend == .decreasing ? .green :
				.gray
		)
		.cornerRadius(8)
	}
}

struct ConfidenceBadge: View {
	let confidence: Double
	
	var body: some View {
		Text(String(format: "%.0f%% Güven", confidence * 100))
			.font(.caption)
			.padding(.horizontal, 8)
			.padding(.vertical, 4)
			.background(
				confidence > 0.7 ? Color.green.opacity(0.2) :
					confidence > 0.4 ? Color.yellow.opacity(0.2) :
					Color.red.opacity(0.2)
			)
			.foregroundColor(
				confidence > 0.7 ? .green :
					confidence > 0.4 ? .orange :
					.red
			)
			.cornerRadius(8)
	}
}

struct AverageRow: View {
	let title: String
	let value: Double
	
	var body: some View {
		HStack {
			Text(title)
				.foregroundColor(.secondary)
			Spacer()
			Text(value.currencyFormat())
				.fontWeight(.medium)
		}
		.font(.subheadline)
	}
}

struct LegendItem: View {
	let color: Color
	let text: String
	
	var body: some View {
		HStack(spacing: 4) {
			Circle()
				.fill(color)
				.frame(width: 8, height: 8)
			Text(text)
				.font(.caption)
				.foregroundColor(.secondary)
		}
	}
}

struct StatRow: View {
	let title: String
	let value: Double
	
	var body: some View {
		HStack {
			Text(title)
				.foregroundColor(.secondary)
			Spacer()
			Text(value.currencyFormat())
				.fontWeight(.medium)
		}
		.font(.subheadline)
	}
}
