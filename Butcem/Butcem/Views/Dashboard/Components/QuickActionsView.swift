import SwiftUI

struct QuickActionsView: View {
    @State private var showingAddIncome = false
    @State private var showingAddExpense = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Hızlı İşlemler")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                // Gelir Ekle Butonu
                QuickActionButton(
                    title: "Gelir Ekle",
                    icon: "plus.circle.fill",
                    color: .green,
                    action: { showingAddIncome = true }
                )
                
                // Gider Ekle Butonu
                QuickActionButton(
                    title: "Gider Ekle",
                    icon: "minus.circle.fill",
                    color: .red,
                    action: { showingAddExpense = true }
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        // Gelir Ekleme Sheet'i
        .sheet(isPresented: $showingAddIncome) {
            AddTransactionView(initialType: .income)
        }
        // Gider Ekleme Sheet'i
        .sheet(isPresented: $showingAddExpense) {
            AddTransactionView(initialType: .expense)
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: color.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
} 