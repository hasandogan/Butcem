import SwiftUI

struct CategoryDetailsList: View {
    let categories: [CategorySpending]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
			Text("Kategori Detayları".localized)
                .font(.headline)
            
            ForEach(categories, id: \.category) { spending in
                VStack(spacing: 8) {
                    HStack {
                        Label(spending.category.rawValue, systemImage: spending.category.icon)
                            .font(.subheadline)
                        Spacer()
                        Text(spending.amount.currencyFormat())
                            .bold()
                    }
                    
                    ProgressView(value: spending.percentage, total: 100)
                        .tint(spending.category.color)
                    
                    HStack {
                        Text("Toplam Harcamanın %\(Int(spending.percentage))'i")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
} 
