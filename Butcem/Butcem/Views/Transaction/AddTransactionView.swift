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
                Section(header: Text("Tutar")) {
                    TextField("0.00", value: $viewModel.amount, format: .currency(code: "TRY"))
                        .keyboardType(.decimalPad)
                }
                
                // Kategori
                Section(header: Text("Kategori")) {
                    Picker("Kategori", selection: $viewModel.category) {
                        ForEach(viewModel.availableCategories, id: \.self) { category in
                            Label(
                                category.rawValue,
                                systemImage: category.icon
                            )
                            .foregroundColor(category.color)
                            .tag(category)
                        }
                    }
                }
                
                // Tarih
                Section(header: Text("Tarih")) {
                    DatePicker(
                        "Tarih",
                        selection: $viewModel.date,
                        displayedComponents: [.date]
                    )
                }
                
                // Not
                Section(header: Text("Not")) {
                    TextField("Not ekle", text: $viewModel.note)
                }
            }
            .navigationTitle(initialType == .income ? "Gelir Ekle" : "Gider Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
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
