import SwiftUI

struct BudgetReportView: View {
    @ObservedObject var viewModel: BudgetViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.getCategoryReport(), id: \.category) { report in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label(report.category.rawValue, systemImage: report.category.icon)
                            .foregroundColor(report.status.color)
                        Spacer()
                        Text(report.percentage.formatted(.percent))
                            .foregroundColor(report.status.color)
                    }
                    
                    ProgressView(value: report.spent, total: report.limit)
                        .tint(report.status.color)
                    
                    HStack {
                        Text("Harcanan: \(report.spent.currencyFormat())")
                        Spacer()
                        Text("Kalan: \(report.remaining.currencyFormat())")
                    }
                    .font(.caption)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Bütçe Raporu")
    }
} 
