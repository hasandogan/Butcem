import SwiftUI

struct AddMemberView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var email: String
    let onAdd: (String) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Üye Ekle")) {
                    TextField("E-posta", text: $email)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                }
            }
            .navigationTitle("Üye Ekle")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Ekle") {
                        onAdd(email)
                        email = ""
                        dismiss()
                    }
                    .disabled(email.isEmpty)
                }
            }
        }
    }
} 