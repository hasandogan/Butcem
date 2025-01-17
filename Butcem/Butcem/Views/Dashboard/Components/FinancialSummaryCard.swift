import SwiftUI

struct FinancialSummaryCard: View {
    let totalIncome: Double
    let totalExpense: Double
    let netAmount: Double
    
    var body: some View {
        VStack(spacing: 16) {
			Text("Aylık Özet".localized)
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
					Text("Gelir".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(totalIncome.currencyFormat())
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
					Text("Gider".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(totalExpense.currencyFormat())
                        .foregroundColor(.red)
                }
            }
            
            Divider()
            
            HStack {
				Text("Net Durum".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(netAmount.currencyFormat())
                    .foregroundColor(netAmount >= 0 ? .green : .red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
} 
