import SwiftUI

struct BudgetView: View {
    @StateObject private var viewModel: BudgetViewModel
    @State private var showingSetBudget = false
    @State private var showingDeleteAlert = false
    
    init() {
        _viewModel = StateObject(wrappedValue: BudgetViewModel())
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.isLoading {
                    ProgressView()
                } else if let budget = viewModel.budget {
                    // Bütçe Özeti
                    BudgetSummaryCard(budget: budget)
                    
                    // Kategori Bazlı Bütçeler
                    ForEach(budget.categoryLimits) { limit in
                        CategoryBudgetCard(categoryBudget: limit)
                    }
                } else {
                    // Bütçe Henüz Belirlenmemiş
                    VStack(spacing: 16) {
                        Image(systemName: "chart.pie")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("Henüz bütçe belirlenmemiş")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Button {
                            showingSetBudget = true
                        } label: {
                            Text("Bütçe Belirle")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.accentColor)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                }
            }
            .padding()
        }
        .navigationTitle("Bütçe")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.budget != nil {
                    Menu {
                        NavigationLink {
                            BudgetHistoryView(viewModel: viewModel)
                        } label: {
                            Label("Geçmiş Bütçeler", systemImage: "clock.arrow.circlepath")
                        }
                        
                        Button {
                            showingSetBudget = true
                        } label: {
                            Label("Düzenle", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("Sil", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingSetBudget) {
            SetBudgetView(viewModel: viewModel)
        }
        .alert("Bütçeyi Sil", isPresented: $showingDeleteAlert) {
            Button("İptal", role: .cancel) {}
            Button("Sil", role: .destructive) {
                Task {
                    await viewModel.deleteBudget()
                }
            }
        } message: {
            Text("Bu bütçeyi silmek istediğinizden emin misiniz?")
        }
        .alert("Hata", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("Tamam") {
                viewModel.clearError()
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .onAppear {
            Task {
                await viewModel.refreshData()
            }
        }
    }
}

