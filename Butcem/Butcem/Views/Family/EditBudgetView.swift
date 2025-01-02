import SwiftUI

struct EditBudgetView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var name: String
    @Binding var budget: String
    let onSave: (String, String) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Bütçe Bilgileri")) {
                    TextField("Bütçe Adı", text: $name)
                    TextField("Toplam Bütçe", text: $budget)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Bütçeyi Düzenle")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
                        onSave(name, budget)
                        dismiss()
                    }
                    .disabled(name.isEmpty || budget.isEmpty)
                }
            }
        }
    }
} 