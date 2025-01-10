import SwiftUI

struct EditReminderView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ReminderViewModel
    let reminder: Reminder
    
    @State private var title: String
    @State private var amount: String
    @State private var selectedCategory: Category
    @State private var selectedType: TransactionType
    @State private var dueDate: Date
    @State private var note: String
    @State private var isActive: Bool
    
    init(viewModel: ReminderViewModel, reminder: Reminder) {
        self.viewModel = viewModel
        self.reminder = reminder
        
        _title = State(initialValue: reminder.title)
        _amount = State(initialValue: String(reminder.amount))
        _selectedCategory = State(initialValue: reminder.category)
        _selectedType = State(initialValue: reminder.type)
        _dueDate = State(initialValue: reminder.dueDate)
        _note = State(initialValue: reminder.note ?? "")
		_isActive = State(initialValue: reminder.isActive)
    }
    
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
                        ForEach(selectedType == .income ? Category.incomeCategories : Category.expenseCategories, id: \.self) { category in
                            Label(category.localizedName, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                }
                
				Section(header: Text("Tarih".localized)) {
					DatePicker("Vade".localized, selection: $dueDate, displayedComponents: .date)
                }
                
                Section(header: Text("Not")) {
					TextField("Not ekle".localized, text: $note)
                }
                
                Section {
					Toggle("Tamamlandı", isOn: $isActive)
                }
                
                Section {
                    Button(role: .destructive) {
                        Task {
                            try? await viewModel.deleteReminder(reminder)
                            dismiss()
                        }
                    } label: {
						Text("Hatırlatıcıyı Sil".localized)
                    }
                }
            }
			.navigationTitle("Düzenle".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
					Button("İptal".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
					Button("Kaydet".localized) {
                        updateReminder()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private func updateReminder() {
        guard let amountValue = Double(amount) else { return }
        
        let updatedReminder = Reminder(
            id: reminder.id,
            userId: reminder.userId,
            title: title,
            amount: amountValue,
            category: selectedCategory,
            type: selectedType,
            dueDate: dueDate,
			frequency: reminder.frequency,
			isActive: isActive,
			note: note.isEmpty ? nil : note,
            createdAt: reminder.createdAt
        )
        
        Task {
            do {
                try await viewModel.updateReminder(updatedReminder)
                dismiss()
            } catch {
                print("Hatırlatıcı güncellenirken hata: \(error.localizedDescription)")
            }
        }
    }
} 
