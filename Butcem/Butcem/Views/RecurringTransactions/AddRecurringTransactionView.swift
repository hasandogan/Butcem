import SwiftUI

struct AddRecurringTransactionView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: RecurringTransactionViewModel
    
    @State private var title = ""
    @State private var amount = ""
    @State private var selectedCategory: Category = .digerGider
    @State private var selectedType: TransactionType = .expense
    @State private var selectedFrequency: RecurringFrequency = .monthly
    @State private var startDate = Date()
    @State private var hasEndDate = false
    @State private var endDate = Date()
    @State private var note = ""
    
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
            }
			.navigationTitle("Tekrarlanan İşlem Ekle".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
					Button("İptal".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
					Button("Kaydet".localized) {
                        saveTransaction()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private func saveTransaction() {
        guard let amountValue = Double(amount) else { return }
        
        let transaction = RecurringTransaction(
            userId: AuthManager.shared.currentUserId ?? "",
            title: title,
            amount: amountValue,
            category: selectedCategory,
            type: selectedType,
            frequency: selectedFrequency,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            lastProcessed: nil,
            note: note.isEmpty ? nil : note,
            createdAt: Date(),
            isActive: true
        )
        
        Task {
            do {
                try await viewModel.addRecurringTransaction(transaction)
                dismiss()
            } catch {
                print("Tekrarlanan işlem eklenirken hata: \(error.localizedDescription)")
            }
        }
    }
} 
