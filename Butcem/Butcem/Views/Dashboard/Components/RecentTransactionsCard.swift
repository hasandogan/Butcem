import SwiftUI

struct RecentTransactionsCard: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Son İşlemler")
                .font(.headline)
            
            if viewModel.recentTransactions.isEmpty {
                Text("Henüz işlem bulunmuyor")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ForEach(viewModel.recentTransactions) { transaction in
                    TransactionRow(transaction: transaction) {
                        Task {
                            await viewModel.deleteTransaction(transaction)
                        }
                    }
                    
                    if transaction.id != viewModel.recentTransactions.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
