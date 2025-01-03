import SwiftUI

struct CreateFamilyBudgetView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = FamilyBudgetViewModel()
    
    @State private var budgetName = ""
    @State private var totalBudget = ""
    @State private var memberEmail = ""
    @State private var members: [String] = []
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Bütçe Bilgileri")) {
                    TextField("Bütçe Adı", text: $budgetName)
                    TextField("Toplam Bütçe", text: $totalBudget)
                        .keyboardType(.decimalPad)
                }
                
                Section(header: Text("Üyeler")) {
                    HStack {
                        TextField("E-posta", text: $memberEmail)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                        
                        Button {
                            if !memberEmail.isEmpty {
                                members.append(memberEmail)
                                memberEmail = ""
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                    
                    ForEach(members, id: \.self) { email in
                        Text(email)
                    }
                    .onDelete { indexSet in
                        members.remove(atOffsets: indexSet)
                    }
                }
            }
            .navigationTitle("Aile Bütçesi Oluştur")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Oluştur") {
                        createBudget()
                    }
                    .disabled(budgetName.isEmpty || totalBudget.isEmpty)
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .alert("Hata", isPresented: $showingError) {
                Button("Tamam", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func createBudget() {
        guard let amount = Double(totalBudget) else {
            errorMessage = "Geçerli bir bütçe tutarı girin"
            showingError = true
            return
        }
        
        Task {
            do {
                try await viewModel.createFamilyBudget(
                    name: budgetName,
                    members: members,
                    totalBudget: amount
                )
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}
