import SwiftUI

struct CreateFamilyBudgetView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = FamilyBudgetViewModel()
    
    @State private var name = ""
    @State private var totalBudget = ""
    @State private var isCreating = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccessAlert = false
    @State private var createdBudgetCode = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Bütçe Bilgileri")) {
                    TextField("Bütçe Adı", text: $name)
                    
                    TextField("Toplam Bütçe", text: $totalBudget)
                        .keyboardType(.decimalPad)
                }
                
                Section {
                    Button(action: createBudget) {
                        if isCreating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Bütçe Oluştur")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(name.isEmpty || totalBudget.isEmpty || isCreating)
                }
                
                if !createdBudgetCode.isEmpty {
                    Section(header: Text("Paylaşım Kodu")) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Bu kodu aile üyeleriyle paylaşın:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text(createdBudgetCode)
                                    .font(.title2)
                                    .bold()
                                    .foregroundColor(.blue)
                                
                                Spacer()
                                
                                Button {
                                    UIPasteboard.general.string = createdBudgetCode
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                }
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                }
            }
            .navigationTitle("Yeni Aile Bütçesi")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
            }
            .alert("Hata", isPresented: $showingError) {
                Button("Tamam", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Bütçe Oluşturuldu", isPresented: $showingSuccessAlert) {
                Button("Tamam") {
                    dismiss()
                }
            } message: {
                Text("Aile bütçeniz başarıyla oluşturuldu. Paylaşım kodunu kullanarak aile üyelerini ekleyebilirsiniz.")
            }
        }
    }
    
    private func createBudget() {
        guard let budgetAmount = Double(totalBudget) else {
            errorMessage = "Geçerli bir bütçe tutarı giriniz"
            showingError = true
            return
        }
        
        isCreating = true
        
        Task {
            do {
                try await viewModel.createFamilyBudget(
                    name: name,
                    totalBudget: budgetAmount
                )
                
                await MainActor.run {
                    if let code = viewModel.currentBudget?.sharingCode {
                        createdBudgetCode = code
                    }
                    showingSuccessAlert = true
                    isCreating = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isCreating = false
                }
            }
        }
    }
}

#Preview {
    CreateFamilyBudgetView()
}
