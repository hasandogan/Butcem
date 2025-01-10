import SwiftUI
import Charts

struct PastBudgetDetailView: View {
    let budget: Budget
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Genel Özet Kartı
                BudgetSummarySection(budget: budget)
                
                // Kategori Dağılımı
                CategoryDistributionSection(categoryLimits: budget.categoryLimits)
                
                // Kategori Detayları
                CategoryDetailsSection(categoryLimits: budget.categoryLimits)
            }
            .padding()
        }
        .navigationTitle(budget.monthName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Helper Views
private struct BudgetSummarySection: View {
    let budget: Budget
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
				Text("Toplam Bütçe".localized)
                    .font(.headline)
                Spacer()
                Text(budget.amount.currencyFormat())
                    .font(.title2)
                    .bold()
            }
            
            ProgressView(value: budget.spentPercentage, total: 100)
                .tint(budget.status.color)
            
            HStack {
                VStack(alignment: .leading) {
					Text("Harcanan".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(budget.spentAmount.currencyFormat())
                        .bold()
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Kalan")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(budget.remainingAmount.currencyFormat())
                        .bold()
                }
            }
            
            Text("%\(Int(budget.spentPercentage)) kullanıldı")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

private struct CategoryDistributionSection: View {
    let categoryLimits: [CategoryBudget]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
			Text("Kategori Dağılımı".localized)
                .font(.headline)
            
            Chart {
                ForEach(categoryLimits) { limit in
                    SectorMark(
                        angle: .value("Harcama", limit.spent),
                        innerRadius: .ratio(0.618),
                        angularInset: 1.5
                    )
                    .cornerRadius(5)
                    .foregroundStyle(by: .value("Kategori", limit.category.rawValue))
                }
            }
            .frame(height: 200)
            
            // Kategori Listesi
            ForEach(categoryLimits) { limit in
                HStack {
                    Circle()
                        .fill(limit.status.color)
                        .frame(width: 8, height: 8)
                    Text(limit.category.rawValue)
                    Spacer()
                    Text(limit.spent.currencyFormat())
                        .foregroundColor(.secondary)
                }
                .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

private struct CategoryDetailsSection: View {
    let categoryLimits: [CategoryBudget]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
			Text("Kategori Detayları".localized)
                .font(.headline)
            
            ForEach(categoryLimits) { limit in
                VStack(spacing: 8) {
                    HStack {
                        Label(limit.category.rawValue, systemImage: limit.category.icon)
                            .font(.subheadline)
                        Spacer()
                        Text(limit.spent.currencyFormat())
                            .bold()
                    }
                    
                    ProgressView(value: limit.spentPercentage, total: 100)
                        .tint(limit.status.color)
                    
                    HStack {
                        Text("Limit: \(limit.limit.currencyFormat())")
                        Spacer()
                        Text("%\(Int(limit.spentPercentage))")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
