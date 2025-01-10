import SwiftUI

struct AddTransactionView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: AddTransactionViewModel
    let initialType: TransactionType
    
    init(initialType: TransactionType) {
        self.initialType = initialType
        _viewModel = StateObject(wrappedValue: AddTransactionViewModel(type: initialType))
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Tutar
				Section(header: Text("Tutar".localized)) {
                    TextField("0.00", value: $viewModel.amount, format: .currency(code: "TRY"))
                        .keyboardType(.decimalPad)
                }
                
                // Kategori
				Section(header: Text("Kategori".localized)) {
					Picker("Kategori".localized, selection: $viewModel.category) {
                        ForEach(viewModel.availableCategories, id: \.self) { category in
                            Label(
                                category.localizedName,
                                systemImage: category.icon
                            )
                            .foregroundColor(category.color)
                            .tag(category)
                        }
                    }
                }
                
                // Tarih
				Section(header: Text("Tarih".localized)) {
                    DatePicker(
						"Tarih".localized,
                        selection: $viewModel.date,
                        displayedComponents: [.date]
                    )
                }
                
                // Not
				Section(header: Text("Not".localized)) {
					TextField("Not ekle".localized, text: $viewModel.note)
                }
            }
			.navigationTitle(initialType == .income ? "Gelir Ekle".localized : "Gider Ekle".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
					Button("İptal".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
					Button("Kaydet".localized) {
                        Task {
                            if await viewModel.saveTransaction() {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.isValid)
                }
            }
        }
    }
} 
