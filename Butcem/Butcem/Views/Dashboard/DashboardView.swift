import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                FinancialSummaryCard(
                    totalIncome: viewModel.totalIncome,
                    totalExpense: viewModel.totalExpense,
                    netAmount: viewModel.netAmount
                )
                
                if let budget = viewModel.budget {
                    BudgetSummaryCard(budget: budget)
                }
                
                QuickActionsView()
                SpendingChart(viewModel: viewModel)
                RecentTransactionsCard(viewModel: viewModel)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Ana Sayfa")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.refreshData()
        }
        .alert("Hata", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("Tamam") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
}