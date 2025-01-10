import SwiftUI

struct QuickActionsView: View {
    @State private var showingAddIncome = false
    @State private var showingAddExpense = false
    @State private var showingScanner = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Hızlı İşlemler".localized)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                // Gelir Ekle Butonu
                QuickActionButton(
                    title: "Gelir Ekle".localized,
                    icon: "plus.circle.fill",
                    color: .green,
                    action: { showingAddIncome = true }
                )
                // TO DO V2 KONSEPT
                // Gider Ekle Menu
             //   Menu {
			//	Button {
              //          showingAddExpense = true
                //    } label: {
                  //      Label("Manuel Gider", systemImage: "plus")
                   // }
                    
                   // Button {
                    //    showingScanner = true
                    //} label: {
                     //   Label("Fatura Tara", systemImage: "doc.text.viewfinder")
                    //}
                //} label: {
                    QuickActionButton(
                        title: "Gider Ekle".localized,
                        icon: "minus.circle.fill",
                        color: .red,
                        action: {showingAddExpense = true}
                    )
                //}
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .sheet(isPresented: $showingAddIncome) {
            AddTransactionView(initialType: .income)
        }
        .sheet(isPresented: $showingAddExpense) {
            AddTransactionView(initialType: .expense)
        }
        .sheet(isPresented: $showingScanner) {
            ReceiptScannerView()
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
