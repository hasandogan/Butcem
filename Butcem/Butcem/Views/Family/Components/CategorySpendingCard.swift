import SwiftUI

struct FamilyCategorySpendingCard: View {
    let limits: [FamilyCategoryBudget]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Kategori Harcamaları")
                    .font(.headline)
                Spacer()
                Text("Toplam: \(totalSpent.currencyFormat())")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if limits.isEmpty {
                Text("Henüz harcama yapılmamış")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(limits.sorted { $0.spent > $1.spent }) { limit in
                    VStack(spacing: 8) {
                        HStack {
							Label(limit.category.localizedName, systemImage: limit.category.icon)
                                .foregroundColor(limit.category.color)
                            Spacer()
                            Text(limit.spent.currencyFormat())
                                .bold()
                        }
                        
                        ProgressView(value: limit.spent, total: limit.limit)
                            .tint(limit.spent > limit.limit ? .red : limit.category.color)
                        
                        HStack {
                            Text("Limit: \(limit.limit.currencyFormat())")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("%\(Int(limit.spentPercentage))")
                                .font(.caption)
                                .foregroundColor(limit.spent > limit.limit ? .red : .secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    
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
    
    private var totalSpent: Double {
        limits.reduce(0) { $0 + $1.spent }
    }
} 
