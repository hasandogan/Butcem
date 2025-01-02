import SwiftUI

struct FamilyBudgetView: View {
    @StateObject private var viewModel = FamilyBudgetViewModel()
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingAddMemberSheet = false
    @State private var showingCreateBudget = false
    @State private var newMemberEmail = ""
    @State private var editingName = ""
    @State private var editingBudget = ""
    @State private var showingAddTransaction = false
    
    var body: some View {
        Group {
            if let budget = viewModel.currentBudget {
                ScrollView {
                    VStack(spacing: 20) {
                        // Bütçe özeti
						FamilyBudgetSummarySection(budget: budget)
                        
                        // Üyeler listesi
                        MembersSection(members: budget.members)
                        
                        // Kategori harcamaları
                        CategorySpendingSection(limits: budget.categoryLimits)
                        
                        // Harcama ekle butonu
                        if viewModel.isAdmin {
                            Button {
                                // Harcama ekleme sayfasını aç
                                showingAddTransaction = true
                            } label: {
                                Label("Harcama Ekle", systemImage: "plus.circle.fill")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.accentColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
					
                            AdminControlsSection(
                                onEdit: {
                                    editingName = budget.name
                                    editingBudget = String(budget.totalBudget)
                                    showingEditSheet = true
                                },
                                onAddMember: { showingAddMemberSheet = true },
                                onDelete: { showingDeleteAlert = true }
                            )
                        }
                    }
                    .padding()
                }
                .navigationTitle(budget.name)
                .sheet(isPresented: $showingAddTransaction) {
                    AddFamilyTransactionView(budget: budget)
                }
                .sheet(isPresented: $showingEditSheet) {
                    EditBudgetView(
                        name: $editingName,
                        budget: $editingBudget,
                        onSave: { name, amount in
                            Task {
                                if let amount = Double(amount) {
                                    try await viewModel.updateBudget(
                                        name: name,
                                        totalBudget: amount
                                    )
                                }
                            }
                        }
                    )
                }
                .sheet(isPresented: $showingAddMemberSheet) {
                    AddMemberView(email: $newMemberEmail) { email in
                        Task {
                            try await viewModel.addMember(email)
                        }
                    }
                }
                .alert("Bütçeyi Sil", isPresented: $showingDeleteAlert) {
                    Button("İptal", role: .cancel) { }
                    Button("Sil", role: .destructive) {
                        Task {
                            try await viewModel.deleteBudget()
                        }
                    }
                } message: {
                    Text("Bu bütçeyi silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.")
                }
            } else {
                CreateBudgetPromptView(showingCreateBudget: $showingCreateBudget)
            }
        }
        .sheet(isPresented: $showingCreateBudget) {
            CreateFamilyBudgetView()
        }
    }
}

// Alt bileşenler
struct FamilyBudgetSummarySection: View {
    let budget: FamilyBudget
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Toplam Bütçe")
                .font(.headline)
            Text(budget.totalBudget.currencyFormat())
                .font(.title2)
            
            ProgressView(value: budget.spentAmount, total: budget.totalBudget)
                .tint(budget.spentAmount > budget.totalBudget ? .red : .blue)
            
            Text("Harcanan: \(budget.spentAmount.currencyFormat())")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct MembersSection: View {
    let members: [FamilyBudget.FamilyMember]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Üyeler")
                .font(.headline)
            
            ForEach(members) { member in
                MemberRow(member: member)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct AdminControlsSection: View {
    let onEdit: () -> Void
    let onAddMember: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: onEdit) {
                Label("Bütçeyi Düzenle", systemImage: "pencil")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            Button(action: onAddMember) {
                Label("Üye Ekle", systemImage: "person.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            Button(role: .destructive, action: onDelete) {
                Label("Bütçeyi Sil", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct CreateBudgetPromptView: View {
    @Binding var showingCreateBudget: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("Aile Bütçesi Oluştur")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Ailenizle birlikte harcamalarınızı takip edin")
                .foregroundColor(.secondary)
            
            Button {
                showingCreateBudget = true
            } label: {
                Text("Bütçe Oluştur")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
    }
} 
