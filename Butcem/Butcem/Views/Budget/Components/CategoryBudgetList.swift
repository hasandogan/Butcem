import SwiftUI

struct CategoryBudgetList: View {
    let limits: [CategoryBudget]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
			Text("Kategori Limitleri".localized)
                .font(.headline)
            
            if limits.isEmpty {
				Text("Henüz kategori limiti belirlenmemiş".localized)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(limits) { limit in
                    CategoryBudgetRow(limit: limit)
                    
                    if limit.id != limits.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color.systemBackground)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct CategoryBudgetRow: View {
    let limit: CategoryBudget
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Label(limit.category.rawValue, systemImage: limit.category.icon)
                Spacer()
                VStack(alignment: .trailing) {
                    Text(limit.spent.currencyFormat())
                        .foregroundColor(limit.isOverBudget ? .red : .primary)
                    Text("/ \(limit.limit.currencyFormat())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            ProgressView(value: limit.spent, total: limit.limit)
                .tint(limit.isOverBudget ? .red : .blue)
        }
    }
} 
