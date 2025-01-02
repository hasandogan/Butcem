import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: transaction.category.icon)
                .foregroundColor(transaction.type == .expense ? .red : .green)
            
            VStack(alignment: .leading) {
                Text(transaction.category.rawValue)
                if let note = transaction.note {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(transaction.formattedAmount)
                    .foregroundColor(transaction.type == .expense ? .red : .green)
                Text(transaction.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Sil", systemImage: "trash")
            }
        }
    }
} 
