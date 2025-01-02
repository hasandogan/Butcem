import SwiftUI

struct SummaryCard: View {
    let summary: AnalysisSummary
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Gelir")
                        .foregroundColor(.secondary)
                    Text(summary.income.currencyFormat())
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Gider")
                        .foregroundColor(.secondary)
                    Text(summary.expense.currencyFormat())
                        .foregroundColor(.red)
                }
            }
            
            Divider()
            
            HStack {
                Text("Net")
                Spacer()
                Text(summary.balance.currencyFormat())
                    .foregroundColor(summary.balance >= 0 ? .green : .red)
            }
            .font(.headline)
            
            Text("\(summary.transactionCount) işlem")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
} 
