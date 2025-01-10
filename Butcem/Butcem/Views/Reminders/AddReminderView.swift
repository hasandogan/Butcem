import SwiftUI

struct AddReminderView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ReminderViewModel
    
    @State private var title = ""
    @State private var amount = ""
	@State private var selectedCategory: Category = .digerGelir
    @State private var selectedType: TransactionType = .expense
    @State private var dueDate = Date()
    @State private var selectedFrequency: Reminder.ReminderFrequency = .once
    @State private var note = ""
    @State private var showingNotificationSettings = false
    
    private var isFormValid: Bool {
        !title.isEmpty && !amount.isEmpty && Double(amount) ?? 0 > 0
    }
    
    var body: some View {
        NavigationView {
            Form {
				Section(header: Text("Hatırlatıcı Detayları".localized)) {
					TextField("Başlık".localized, text: $title)
                    
					TextField("Tutar".localized, text: $amount)
                        .keyboardType(.decimalPad)
                    
					Picker("Tür".localized, selection: $selectedType) {
						Text("Gelir".localized).tag(TransactionType.income)
						Text("Gider".localized).tag(TransactionType.expense)
                    }
                    
					Picker("Kategori".localized, selection: $selectedCategory) {
                        ForEach(Category.allCases, id: \.self) { category in
                            Label(category.localizedName, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                }
                
				Section(header: Text("Zamanlama".localized)) {
                    DatePicker(
						"Tarih ve Saat".localized,
                        selection: $dueDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .environment(\.locale, Locale(identifier: "tr_TR"))
                    .environment(\.timeZone, TimeZone(identifier: "Europe/Istanbul")!)
                    
					Picker("Tekrar".localized, selection: $selectedFrequency) {
                        ForEach(Reminder.ReminderFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.rawValue).tag(frequency)
                        }
                    }
                }
                
				Section(header: Text("Not".localized)) {
					TextField("Not ekle".localized, text: $note)
                }
                
				if !UserDefaults.standard.bool(forKey: "isPremium") {
                    Section {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
							Text("Bu özellik Premium kullanıcılara özeldir".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
			.navigationTitle("Hatırlatıcı Ekle".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
					Button("İptal".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
					Button("Ekle".localized) {
                        addReminder()
                    }
                    .disabled(!isFormValid)
                }
            }
			.alert("Bildirim İzni Gerekli".localized, isPresented: $showingNotificationSettings) {
				Button("Ayarlara Git".localized) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
				Button("İptal".localized, role: .cancel) {}
            } message: {
				Text("Hatırlatıcıları kullanabilmek için bildirim iznine ihtiyacımız var.".localized)
            }
        }
    }
    
    private func addReminder() {
        guard let amountValue = Double(amount) else { return }
        
        let reminder = Reminder(
            userId: AuthManager.shared.currentUserId ?? "",
            title: title,
            amount: amountValue,
            category: selectedCategory,
            type: selectedType,
            dueDate: dueDate,
            frequency: selectedFrequency,
            isActive: true,
            note: note.isEmpty ? nil : note,
            createdAt: Date()
        )
        
        Task {
            await viewModel.addReminder(reminder)
            dismiss()
        }
    }
} 
