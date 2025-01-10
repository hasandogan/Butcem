import SwiftUI

struct EditRecurringTransactionView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: RecurringTransactionViewModel
    let transaction: RecurringTransaction
    
    @State private var title: String
    @State private var amount: String
    @State private var selectedCategory: Category
    @State private var selectedType: TransactionType
    @State private var selectedFrequency: RecurringFrequency
    @State private var startDate: Date
    @State private var hasEndDate: Bool
    @State private var endDate: Date
    @State private var note: String
    @State private var isActive: Bool
    
    init(viewModel: RecurringTransactionViewModel, transaction: RecurringTransaction) {
        self.viewModel = viewModel
        self.transaction = transaction
        
        _title = State(initialValue: transaction.title)
        _amount = State(initialValue: String(transaction.amount))
        _selectedCategory = State(initialValue: transaction.category)
        _selectedType = State(initialValue: transaction.type)
        _selectedFrequency = State(initialValue: transaction.frequency)
        _startDate = State(initialValue: transaction.startDate)
        _hasEndDate = State(initialValue: transaction.endDate != nil)
        _endDate = State(initialValue: transaction.endDate ?? Date())
        _note = State(initialValue: transaction.note ?? "")
        _isActive = State(initialValue: transaction.isActive)
    }
    
    private var isFormValid: Bool {
        !title.isEmpty && !amount.isEmpty && Double(amount) ?? 0 > 0
    }
    
    var body: some View {
        NavigationView {
            Form {
				Section(header: Text("İşlem Detayları".localized)) {
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
                
				Section(header: Text("Tekrarlama".localized)) {
					Picker("Sıklık".localized, selection: $selectedFrequency) {
                        ForEach(RecurringFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.rawValue).tag(frequency)
                        }
                    }
                    
					DatePicker("Başlangıç".localized, selection: $startDate, displayedComponents: .date)
                    
					Toggle("Bitiş Tarihi".localized, isOn: $hasEndDate)
                    
                    if hasEndDate {
						DatePicker("Bitiş".localized, selection: $endDate, displayedComponents: .date)
                    }
                }
                
				Section(header: Text("Not".localized)) {
					TextField("Not ekle".localized, text: $note)
                }
                
                Section {
					Toggle("Aktif".localized, isOn: $isActive)
                }
                
                Section {
                    Button(role: .destructive) {
                        deleteTransaction()
                    } label: {
						Text("Sil".localized)
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
                        updateTransaction()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private func updateTransaction() {
        guard let amountValue = Double(amount) else { return }
        
        let updatedTransaction = RecurringTransaction(
            id: transaction.id,
            userId: transaction.userId,
            title: title,
            amount: amountValue,
            category: selectedCategory,
            type: selectedType,
            frequency: selectedFrequency,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            lastProcessed: transaction.lastProcessed,
            note: note.isEmpty ? nil : note,
            createdAt: transaction.createdAt,
            isActive: isActive
        )
        
        Task {
            do {
                try await viewModel.updateRecurringTransaction(updatedTransaction)
                dismiss()
            } catch {
                print("Tekrarlanan işlem güncellenirken hata: \(error.localizedDescription)")
            }
        }
    }
    
    private func deleteTransaction() {
        Task {
            do {
                try await viewModel.deleteRecurringTransaction(transaction)
                dismiss()
            } catch {
                print("Tekrarlanan işlem silinirken hata: \(error.localizedDescription)")
            }
        }
    }
} 
