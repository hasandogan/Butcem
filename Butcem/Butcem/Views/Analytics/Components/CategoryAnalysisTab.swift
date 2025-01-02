import SwiftUI
import Charts

struct CategoryAnalysisTab: View {
    let categories: [CategoryAnalytics]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Kategori Pasta Grafiği
                Chart {
                    ForEach(categories) { category in
                        SectorMark(
                            angle: .value("Harcama", category.amount),
                            innerRadius: .ratio(0.618),
                            angularInset: 1.5
                        )
                        .cornerRadius(5)
                        .foregroundStyle(by: .value("Category", category.category.rawValue))
                    }
                }
                .frame(height: 200)
                
                // Kategori Listesi
                ForEach(categories) { category in
                    CategoryAnalyticsRow(category: category)
                }
            }
            .padding()
        }
    }
}

struct CategoryAnalyticsRow: View {
    let category: CategoryAnalytics
    
    var body: some View {
        HStack {
            Image(systemName: category.category.icon)
                .foregroundColor(.blue)
            Text(category.category.rawValue)
            Spacer()
            VStack(alignment: .trailing) {
                Text(category.amount.currencyFormat())
                Text(category.percentage.percentFormat())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.systemBackground)
        .cornerRadius(8)
    }
} 