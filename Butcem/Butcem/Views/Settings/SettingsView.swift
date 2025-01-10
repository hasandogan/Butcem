import SwiftUI

struct SettingsView: View {
    @StateObject private var settingsViewModel = UserSettingsViewModel()
    @State private var showingBillingDayPicker = false
    @State private var showingDeleteAlert = false
    @State private var showingPremiumView = false
    @State private var isRestoringPurchases = false
    
    var body: some View {
        NavigationView {
            Form {
                // Abonelik Bilgileri
                Section(header: Text("Abonelik".localized)) {
                    VStack(alignment: .leading, spacing: 12) {
                        // Plan Bilgisi
                        HStack {
                            Image(systemName: settingsViewModel.isPremium ? "star.circle.fill" : "star.circle")
                                .foregroundColor(settingsViewModel.isPremium ? .yellow : .gray)
                                .font(.title2)
                            VStack(alignment: .leading) {
                                Text(settingsViewModel.subscriptionPlan)
                                    .font(.headline)
                                Text(settingsViewModel.isPremium ? "Aktif Abonelik" : "Ücretsiz Plan")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        
                        if settingsViewModel.isPremium {
                            Divider()
                            
                            // Fiyat Bilgisi
                            HStack {
                                Image(systemName: "creditcard")
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading) {
                                    Text(settingsViewModel.billingPeriodLabel)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    if settingsViewModel.subscriptionPrice > 0 {
                                        Text(settingsViewModel.subscriptionPrice.formatted(.currency(code: "TRY")))
                                            .font(.subheadline)
                                    } else {
                                        Text("Ücretsiz")
                                            .font(.subheadline)
                                    }
                                }
                            }
                            
                            // Başlangıç Tarihi
                            HStack {
                                Image(systemName: "calendar.badge.plus")
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading) {
                                    Text("Başlangıç Tarihi")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(settingsViewModel.subscriptionStartDate?.formatted(date: .long, time: .omitted) ?? "")
                                        .font(.subheadline)
                                }
                            }
                            
                            // Yenileme/Bitiş Tarihi
                            if let endDate = settingsViewModel.subscriptionEndDate {
                                HStack {
                                    Image(systemName: "calendar.badge.clock")
                                        .foregroundColor(.blue)
                                    VStack(alignment: .leading) {
                                        Text("Yenileme Tarihi")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Text(endDate.formatted(date: .long, time: .omitted))
                                            .font(.subheadline)
                                    }
                                }
                            }
                        }
                        
                        // Premium'a Yükselt Butonu (sadece ücretsiz planda)
                        if !settingsViewModel.isPremium {
                            Button {
                                showingPremiumView = true
                            } label: {
                                HStack {
                                    Image(systemName: "star.circle.fill")
                                        .foregroundColor(.yellow)
                                    Text("Premium'a Yükselt")
                                        .bold()
                                }
                            }
                            .tint(.blue)
                            .padding(.top, 8)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Uygulama".localized)) {
                    Link("Gizlilik Politikası".localized, destination: URL(string: "https://hasandgn.com/kullanici-sozlesmesi")!)
                    Link("Kullanım Koşulları".localized, destination: URL(string: "https://hasandgn.com/gizlilik-politikasi")!)
                    
                    Button {
                        Task {
                            isRestoringPurchases = true
                            try? await StoreKitService.shared.restorePurchases()
                            isRestoringPurchases = false
                        }
                    } label: {
                        if isRestoringPurchases {
                            HStack {
                                Text("Satın Alımlar Geri Yükleniyor...")
                                Spacer()
                                ProgressView()
                            }
                        } else {
                            Text("Satın Alımları Geri Yükle")
                        }
                    }
                    .disabled(isRestoringPurchases)
                    
                    Text("version 1.0.0".localized)
                }
                
                Section(header: Text("Hesap Ayarları".localized)) {
                    HStack {
                        Text("Hesap Kesim Günü".localized)
                        Spacer()
                        Button("\(settingsViewModel.billingDay)") {
                            showingBillingDayPicker = true
                        }
                    }
                }
            }
            .navigationTitle("Ayarlar".localized)
            .sheet(isPresented: $showingBillingDayPicker) {
                BillingDayPickerView(
                    selectedDay: settingsViewModel.billingDay
                ) { newDay in
                    Task {
                        await settingsViewModel.updateBillingDay(newDay)
                    }
                }
            }
            .sheet(isPresented: $showingPremiumView) {
                PremiumView()
            }
            .alert("Hata".localized, isPresented: $settingsViewModel.showError) {
                Button("Tamam".localized, role: .cancel) { }
            } message: {
                if let error = settingsViewModel.errorMessage {
                    Text(error)
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
			.navigationTitle("Hesap Kesim Günü".localized)
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


