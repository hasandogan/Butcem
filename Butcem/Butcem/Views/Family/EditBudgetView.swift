import SwiftUI

struct EditBudgetView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var name: String
    @Binding var budget: String
    let onSave: (String, String) -> Void
    
    var body: some View {
        NavigationView {
            Form {
				Section(header: Text("Bütçe Bilgileri".localized)) {
					TextField("Bütçe Adı".localized, text: $name)
					TextField("Toplam Bütçe".localized, text: $budget)
                        .keyboardType(.decimalPad)
                }
            }
			.navigationTitle("Bütçeyi Düzenle".localized)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
					Button("İptal".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
					Button("Kaydet".localized) {
                        onSave(name, budget)
                        dismiss()
                    }
                    .disabled(name.isEmpty || budget.isEmpty)
                }
            }
        }
    }
} 
