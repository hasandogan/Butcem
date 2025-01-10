import SwiftUI

struct BudgetSummaryCard: View {
    let budget: Budget
    
    private var spentAmount: Double {
        TransactionStore.shared.currentMonthExpenses.reduce(0) { $0 + $1.amount }
    }
    
    private var remainingAmount: Double {
        budget.amount - spentAmount
    }
    
    private var spentPercentage: Double {
        min((spentAmount / budget.amount) * 100, 100)
    }
    
    private var progressValue: Double {
        min(spentAmount, budget.amount)
    }
    
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
            
            ProgressView(value: progressValue, total: budget.amount)
                .tint(spentPercentage >= 90 ? .red : .blue)
            
            HStack {
                VStack(alignment: .leading) {
					Text("Harcanan".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(spentAmount.currencyFormat())
                        .foregroundColor(spentPercentage >= 90 ? .red : .primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Kalan")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(remainingAmount.currencyFormat())
                        .foregroundColor(remainingAmount <= 0 ? .red : .green)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
} 
