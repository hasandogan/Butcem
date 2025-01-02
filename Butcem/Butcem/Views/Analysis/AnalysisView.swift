import SwiftUI
import Charts

struct AnalysisView: View {
    @StateObject private var viewModel = AnalysisViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Dönem Seçici
                PeriodPicker(selectedPeriod: $viewModel.selectedPeriod)
                
                // Özet Kart
                SummaryCard(summary: viewModel.summary)
                
                // Kategori Bazlı Harcama Grafiği
                CategorySpendingChart(spending: viewModel.categorySpending)
                
                // Aylık Trend Grafiği
                MonthlyTrendChart(trends: viewModel.monthlyTrends)
                
                // Kategori Detayları
                CategoryDetailsList(categories: viewModel.categorySpending)
            }
            .padding()
        }
        .navigationTitle("Analiz")
        .onAppear {
            viewModel.fetchData()
        }
    }
}

