import SwiftUI

struct InviteMemberView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var email: String
    let onInvite: (String) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Üye Davet Et")) {
                    TextField("E-posta", text: $email)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                }
                
                Button {
                    onInvite(email)
                    dismiss()
                } label: {
                    Text("Davet Gönder")
                        .frame(maxWidth: .infinity)
                }
                .disabled(email.isEmpty)
            }
            .navigationTitle("Üye Davet Et")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    InviteMemberView(email: .constant(""), onInvite: { _ in })
} 