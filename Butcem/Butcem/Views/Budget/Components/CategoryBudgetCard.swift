import SwiftUI

struct CategoryBudgetCard: View {
    let categoryBudget: CategoryBudget
    
    private var progressValue: Double {
        min(categoryBudget.spent, categoryBudget.limit)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Label(categoryBudget.category.rawValue, systemImage: categoryBudget.category.icon)
                    .font(.headline)
                    .foregroundColor(categoryBudget.isOverBudget ? .red : .primary)
                Spacer()
                Text(categoryBudget.limit.currencyFormat())
                    .font(.subheadline)
            }
            
            ProgressView(value: progressValue, total: categoryBudget.limit)
                .tint(categoryBudget.isOverBudget ? .red : .blue)
            
            HStack {
                Text("Harcanan: \(categoryBudget.spent.currencyFormat())")
                    .font(.caption)
                    .foregroundColor(categoryBudget.isOverBudget ? .red : .secondary)
                
                Spacer()
                
                Text("Kalan: \(categoryBudget.remainingAmount.currencyFormat())")
                    .font(.caption)
                    .foregroundColor(categoryBudget.remainingAmount <= 0 ? .red : .green)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
} 
