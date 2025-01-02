import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Hesap")) {
                    if let user = authViewModel.user {
                        Text(user.displayName ?? "Kullanıcı")
                        Text(user.email ?? "")
                    }
                    
                    Button(role: .destructive) {
                        authViewModel.signOut()
                    } label: {
                        Text("Çıkış Yap")
                    }
                }
                
                Section(header: Text("Uygulama")) {
                    Link("Gizlilik Politikası", destination: URL(string: "https://your-privacy-policy.com")!)
                    Link("Kullanım Koşulları", destination: URL(string: "https://your-terms.com")!)
                    Text("Versiyon 1.0.0")
                }
            }
            .navigationTitle("Ayarlar")
        }
    }
} 