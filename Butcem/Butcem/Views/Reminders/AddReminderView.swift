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
                Section(header: Text("Hatırlatıcı Detayları")) {
                    TextField("Başlık", text: $title)
                    
                    TextField("Tutar", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    Picker("Tür", selection: $selectedType) {
                        Text("Gelir").tag(TransactionType.income)
                        Text("Gider").tag(TransactionType.expense)
                    }
                    
                    Picker("Kategori", selection: $selectedCategory) {
                        ForEach(Category.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                }
                
                Section(header: Text("Zamanlama")) {
                    DatePicker(
                        "Tarih ve Saat",
                        selection: $dueDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .environment(\.locale, Locale(identifier: "tr_TR"))
                    .environment(\.timeZone, TimeZone(identifier: "Europe/Istanbul")!)
                    
                    Picker("Tekrar", selection: $selectedFrequency) {
                        ForEach(Reminder.ReminderFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.rawValue).tag(frequency)
                        }
                    }
                }
                
                Section(header: Text("Not")) {
                    TextField("Not ekle", text: $note)
                }
                
                if !UserDefaults.standard.bool(forKey: "isPremium") {
                    Section {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("Bu özellik Premium kullanıcılara özeldir")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Hatırlatıcı Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Ekle") {
                        addReminder()
                    }
                    .disabled(!isFormValid)
                }
            }
            .alert("Bildirim İzni Gerekli", isPresented: $showingNotificationSettings) {
                Button("Ayarlara Git") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("İptal", role: .cancel) {}
            } message: {
                Text("Hatırlatıcıları kullanabilmek için bildirim iznine ihtiyacımız var.")
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
