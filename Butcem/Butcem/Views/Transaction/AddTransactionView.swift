import SwiftUI

struct AddTransactionView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = AddTransactionViewModel()
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("İşlem Tipi", selection: $viewModel.type) {
                        ForEach([TransactionType.income, .expense], id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section {
                    HStack {
                        Text("₺")
                            .foregroundColor(.secondary)
                        TextField("0", value: $viewModel.amount, format: .number)
                            .keyboardType(.decimalPad)
                    }
                    
                    Picker("Kategori", selection: $viewModel.category) {
                        ForEach(viewModel.availableCategories, id: \.self) { category in
                            Label(
                                category.rawValue,
                                systemImage: category.icon
                            ).tag(category)
                        }
                    }
                    
                    DatePicker("Tarih", selection: $viewModel.date, displayedComponents: .date)
                    
                    TextField("Not", text: $viewModel.note)
                }
                
                Section {
                    Button(action: saveTransaction) {
                        HStack {
                            Spacer()
                            if viewModel.isLoading {
                                ProgressView()
                            } else {
                                Text("Kaydet")
                            }
                            Spacer()
                        }
                    }
                    .disabled(viewModel.isLoading || !viewModel.isValid)
                }
            }
            .navigationTitle("İşlem Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
            }
            .alert("Hata", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("Tamam", role: .cancel) {}
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    private func saveTransaction() {
        Task {
            if await viewModel.saveTransaction() {
                dismiss()
            }
        }
    }
} 
