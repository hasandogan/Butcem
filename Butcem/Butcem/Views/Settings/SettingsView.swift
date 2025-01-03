import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var settingsViewModel = UserSettingsViewModel()
    @State private var showingBillingDayPicker = false
    
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
                
                Section(header: Text("Hesap Ayarları")) {
                    HStack {
                        Text("Hesap Kesim Günü")
                        Spacer()
                        Button("\(settingsViewModel.billingDay)") {
                            showingBillingDayPicker = true
                        }
                    }
                }
            }
            .navigationTitle("Ayarlar")
            .sheet(isPresented: $showingBillingDayPicker) {
                BillingDayPickerView(
                    selectedDay: settingsViewModel.billingDay
                ) { newDay in
                    Task {
                        await settingsViewModel.updateBillingDay(newDay)
                    }
                }
            }
        }
    }
}

struct BillingDayPickerView: View {
    @Environment(\.dismiss) var dismiss
    let selectedDay: Int
    let onSelect: (Int) -> Void
    
    var body: some View {
        NavigationView {
            List(1...31, id: \.self) { day in
                Button {
                    onSelect(day)
                    dismiss()
                } label: {
                    HStack {
                        Text("\(day)")
                        Spacer()
                        if day == selectedDay {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Hesap Kesim Günü")
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