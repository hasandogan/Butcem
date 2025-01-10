import SwiftUI

struct InviteMemberView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var email: String
    let onInvite: (String) -> Void
    
    var body: some View {
        NavigationView {
            Form {
				Section(header: Text("Üye Davet Et".localized)) {
                    TextField("E-posta", text: $email)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                }
                
                Button {
                    onInvite(email)
                    dismiss()
                } label: {
					Text("Davet Gönder".localized)
                        .frame(maxWidth: .infinity)
                }
                .disabled(email.isEmpty)
            }
			.navigationTitle("Üye Davet Et".localized)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
					Button("Kapat".localized) {
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
