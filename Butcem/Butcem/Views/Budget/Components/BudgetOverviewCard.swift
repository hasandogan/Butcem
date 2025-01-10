import SwiftUI

struct BudgetOverviewCard: View {
    let budget: Budget
    
    var body: some View {
        VStack(spacing: 16) {
            // Başlık
            HStack {
				Text("Aylık Bütçe".localized)
                    .font(.headline)
                Spacer()
                Text(budget.month.monthYearString())
                    .foregroundColor(.secondary)
            }
            
            // Bütçe Durumu
            VStack(spacing: 8) {
                HStack {
					Text("Toplam Bütçe:".localized)
                    Spacer()
                    Text(budget.amount.currencyFormat())
                        .bold()
                }
                
                HStack {
					Text("Harcanan:".localized)
                    Spacer()
                    Text(budget.spentAmount.currencyFormat())
                        .foregroundColor(.red)
                }
                
                HStack {
					Text("Kalan:".localized)
                    Spacer()
                    Text(budget.remainingAmount.currencyFormat())
                        .foregroundColor(.green)
                }
            }
            
            // İlerleme Çubuğu
            ProgressView(value: budget.spentAmount, total: budget.amount)
                .tint(budget.spentPercentage >= 90 ? .red : .blue)
                .padding(.vertical, 4)
            
			Text("\(budget.spentPercentage.percentFormat()) kullanıldı")
                .font(.caption)
                .foregroundColor(budget.spentPercentage >= 90 ? .red : .secondary)
        }
        .padding()
        .background(Color.systemBackground)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
} 
