import SwiftUI

struct TransactionsView: View {
    @StateObject private var viewModel = TransactionsViewModel()
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingFilter = false
    @State private var showingExport = false
    @State private var selectedType: TransactionType?
    @State private var selectedCategory: Category?
    
    var body: some View {
        NavigationView {
            List {
                if viewModel.filteredTransactions.isEmpty {
                    Text("İşlem bulunamadı")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(viewModel.filteredTransactions) { transaction in
                        TransactionRow(transaction: transaction) {
                            Task {
                                await viewModel.deleteTransaction(transaction)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Tüm İşlemler")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button {
                        showingExport.toggle()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        showingFilter.toggle()
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showingFilter) {
                FilterView(selectedType: $selectedType, selectedCategory: $selectedCategory)
                    .onChange(of: selectedType) { _ in
                        viewModel.filterTransactions(type: selectedType, category: selectedCategory)
                    }
                    .onChange(of: selectedCategory) { _ in
                        viewModel.filterTransactions(type: selectedType, category: selectedCategory)
                    }
            }
            .sheet(isPresented: $showingExport) {
                if subscriptionManager.canAccessPremiumFeatures {
                    ExportView()
                } else {
                    PremiumView()
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .alert("Hata", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("Tamam", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

struct FilterView: View {
	@Environment(\.dismiss) var dismiss
	@Binding var selectedType: TransactionType?
	@Binding var selectedCategory: Category?
	
	var body: some View {
		NavigationView {
			Form {
				Section(header: Text("İşlem Türü")) {
					Button("Tümü") {
						selectedType = nil
						dismiss()
					}
					Button("Gelirler") {
						selectedType = .income
						dismiss()
					}
					Button("Giderler") {
						selectedType = .expense
						dismiss()
					}
				}
				
				Section(header: Text("Kategori")) {
					Button("Tümü") {
						selectedCategory = nil
						dismiss()
					}
					
					if selectedType == .income {
						ForEach(Category.incomeCategories, id: \.self) { category in
							Button {
								selectedCategory = category
								dismiss()
							} label: {
								Label(category.rawValue, systemImage: category.icon)
							}
						}
					} else if selectedType == .expense {
						ForEach(Category.expenseCategories, id: \.self) { category in
							Button {
								selectedCategory = category
								dismiss()
							} label: {
								Label(category.rawValue, systemImage: category.icon)
							}
						}
					} else {
						ForEach(Category.allCases, id: \.self) { category in
							Button {
								selectedCategory = category
								dismiss()
							} label: {
								Label(category.rawValue, systemImage: category.icon)
							}
						}
					}
				}
			}
			.navigationTitle("Filtrele")
			.navigationBarItems(trailing: Button("Kapat") {
				dismiss()
			})
		}
	}
	
}
