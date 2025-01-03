import SwiftUI

struct AddFamilyTransactionView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = FamilyBudgetViewModel()
    let budget: FamilyBudget
    
    @State private var amount = ""
    @State private var selectedCategory: FamilyBudgetCategory = .diger
    @State private var note = ""
    
    var body: some View {
        NavigationView {
            TransactionFormContent(
                amount: $amount,
                selectedCategory: $selectedCategory,
                note: $note,
                onAdd: addTransaction
            )
            .navigationTitle("Harcama Ekle")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    CancelButton(dismiss: dismiss)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    AddButton(isDisabled: amount.isEmpty) {
                        addTransaction()
                    }
                }
            }
        }
    }
    
    private func addTransaction() {
        guard let amount = Double(amount) else { return }
        
        let familyTransaction = FamilyTransaction(
            userId: AuthManager.shared.currentUserId ?? "",
            amount: amount,
            memberName: AuthManager.shared.currentUserName ?? "",
            memberEmail: AuthManager.shared.currentEmail ?? "",
            category: selectedCategory,
            date: Date(),
            note: note.isEmpty ? nil : note,
            createdAt: Date()
        )
        
        let personalTransaction = Transaction(
            userId: AuthManager.shared.currentUserId ?? "",
            amount: amount,
            category: selectedCategory.toPersonalCategory(),
            type: .expense,
            date: Date(),
            note: note.isEmpty ? nil : "\(budget.name): \(note ?? "")",
            createdAt: Date()
        )
        
        Task {
            do {
                try await viewModel.addFamilyTransaction(familyTransaction, toBudget: budget)
                try await FirebaseService.shared.addTransaction(personalTransaction)
                dismiss()
            } catch {
                print("Transaction error: \(error)")
            }
        }
    }
}

// MARK: - Alt Bileşenler
private struct TransactionFormContent: View {
    @Binding var amount: String
    @Binding var selectedCategory: FamilyBudgetCategory
    @Binding var note: String
    let onAdd: () -> Void
    
    var body: some View {
        Form {
            Section(header: Text("Harcama Detayları")) {
                TextField("Tutar", text: $amount)
                    .keyboardType(.decimalPad)
                
                CategoryPicker(selectedCategory: $selectedCategory)
                
                TextField("Not", text: $note)
            }
        }
    }
}

private struct CategoryPicker: View {
    @Binding var selectedCategory: FamilyBudgetCategory
    
    var body: some View {
        Picker("Kategori", selection: $selectedCategory) {
            ForEach(FamilyBudgetCategory.allCases, id: \.self) { category in
                Label(category.rawValue, systemImage: category.icon)
                    .foregroundColor(category.color)
                    .tag(category)
            }
        }
    }
}

private struct CancelButton: View {
    let dismiss: DismissAction
    
    var body: some View {
        Button("İptal") {
            dismiss()
        }
    }
}

private struct AddButton: View {
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button("Ekle", action: action)
            .disabled(isDisabled)
    }
} 
