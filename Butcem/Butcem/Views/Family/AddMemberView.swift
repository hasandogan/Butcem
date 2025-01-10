import SwiftUI

struct AddMemberView: View {
    @Environment(\.dismiss) var dismiss
    @State private var sharingCode = ""
    @ObservedObject var viewModel: FamilyBudgetViewModel
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Paylaşım Kodu", text: $sharingCode)
                        .autocapitalization(.none)
                }
                
                Section {
                    Button("Üye Ekle") {
                        addMember()
                    }
                    .disabled(sharingCode.isEmpty)
                }
            }
            .navigationTitle("Üye Ekle")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func addMember() {
        Task {
            do {
                try await viewModel.addMember(withCode: sharingCode)
                dismiss()
            } catch {
                print("Failed to add member: \(error)")
            }
        }
    }
}
