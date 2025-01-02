import SwiftUI

struct BudgetHistoryView: View {
    @ObservedObject var viewModel: BudgetViewModel
    
    var body: some View {
        List {
            // Trend Analizi
            Section("Trend Analizi") {
                let trends = viewModel.getBudgetTrends()
                
                HStack {
                    Text("Ortalama Harcama")
                    Spacer()
                    Text(trends.averageSpending.currencyFormat())
                }
                
                if let (category, amount) = trends.mostSpentCategory {
                    HStack {
                        Text("En Çok Harcanan Kategori")
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(category.rawValue)
                            Text(amount.currencyFormat())
                                .font(.caption)
                        }
                    }
                }
            }
            
            // Geçmiş Bütçeler
            Section("Geçmiş Bütçeler") {
                ForEach(viewModel.pastBudgets) { budget in
                    NavigationLink {
                        PastBudgetDetailView(budget: budget)
                    } label: {
                        BudgetHistoryRow(budget: budget)
                    }
                }
            }
        }
        .navigationTitle("Bütçe Geçmişi")
    }
}

struct BudgetHistoryRow: View {
    let budget: Budget
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(budget.monthName)
                    .font(.headline)
                Spacer()
                Text(budget.spentAmount.currencyFormat())
                    .bold()
            }
            
            ProgressView(value: budget.spentPercentage, total: 100)
                .tint(budget.status.color)
            
            HStack {
                Text("Bütçe: \(budget.amount.currencyFormat())")
                    .font(.caption)
                Spacer()
                Text("%\(Int(budget.spentPercentage))")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
        }
    }
} 
