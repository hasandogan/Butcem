import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction
    let onDelete: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Kategori İkonu
            Image(systemName: transaction.category.icon)
                .font(.title3)
                .foregroundColor(transaction.type == .expense ? .red : .green)
                .frame(width: 24, height: 24)
            
            // Orta Kısım
            VStack(alignment: .leading, spacing: 2) {
				Text(transaction.category.localizedName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if let note = transaction.note {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Sağ Kısım
            VStack(alignment: .trailing, spacing: 2) {
                Text(transaction.amount.currencyFormat())
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(transaction.type == .expense ? .red : .green)
                Text(transaction.formattedDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }
} 
