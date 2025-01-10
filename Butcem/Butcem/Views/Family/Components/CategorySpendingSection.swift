import SwiftUI

struct CategorySpendingSection: View {
    let limits: [CategoryBudget]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
			Text("Kategori Harcamaları".localized)
                .font(.headline)
            
            if limits.isEmpty {
				Text("Henüz kategori limiti belirlenmemiş".localized)
                    .foregroundColor(.secondary)
            } else {
                ForEach(limits) { limit in
                    CategorySpendingRow(
                        category: limit.category,
                        spent: limit.spent,
                        limit: limit.limit
                    )
                    
                    if limit.id != limits.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}
