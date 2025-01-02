import SwiftUI

struct QuickActionsView: View {
    @State private var showingAddTransaction = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Hızlı İşlemler")
                .font(.headline)
            
            HStack(spacing: 20) {
                Button {
                    showingAddTransaction = true
                } label: {
                    VStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 24))
                        Text("Gelir Ekle")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }
                
                Button {
                    showingAddTransaction = true
                } label: {
                    VStack {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 24))
                        Text("Gider Ekle")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionView()
        }
    }
} 