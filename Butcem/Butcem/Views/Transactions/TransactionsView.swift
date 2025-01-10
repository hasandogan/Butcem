import SwiftUI

struct TransactionsView: View {
	@StateObject private var viewModel = TransactionsViewModel()
	@ObservedObject private var subscriptionManager = SubscriptionManager.shared
	@State private var showingFilter = false
	@State private var selectedType: TransactionType?
	@State private var selectedCategory: Category?
	@State private var showingScanner = false

	var sortedTransactions: [Transaction] {
		viewModel.filteredTransactions.sorted { $0.date > $1.date }
	}
	
	var body: some View {
		Group {
			if sortedTransactions.isEmpty {
				EmptyTransactionsView()
			} else {
				List {
					ForEach(sortedTransactions) { transaction in
						TransactionRow(transaction: transaction) { 
							Task {
								try? await viewModel.deleteTransaction(transaction)
							}
						}
						.swipeActions(edge: .trailing) {
							Button(role: .destructive) {
								Task {
									try? await viewModel.deleteTransaction(transaction)
								}
							} label: {
								Label("Sil".localized, systemImage: "trash")
							}
						}
					}
				}
				.listStyle(.plain)
			}
		}
		.navigationTitle("İşlemler".localized)
		.toolbar {
			ToolbarItem(placement: .navigationBarTrailing) {
				Menu {
					// Tüm işlemler
					Button {
						selectedType = nil
						selectedCategory = nil
						viewModel.filterTransactions(type: nil, category: nil)
					} label: {
						Label("Tümü".localized, systemImage: "list.bullet")
					}
					
					Menu("İşlem Tipi".localized) {
						ForEach(TransactionType.allCases, id: \.self) { type in
							Button {
								selectedType = type
								viewModel.filterTransactions(type: type, category: selectedCategory)
							} label: {
								Label(type.localizedName, systemImage: type == .income ? "plus.circle" : "minus.circle")
							}
						}
					}
					
					Menu("Kategori".localized) {
						ForEach(Category.allCases, id: \.self) { category in
							Button {
								selectedCategory = category
								viewModel.filterTransactions(type: selectedType, category: category)
							} label: {
								Label(category.localizedName, systemImage: category.icon)
							}
						}
					}
				} label: {
					Label("Filtrele".localized, systemImage: "line.3.horizontal.decrease.circle")
				}
			}
		}
		.refreshable {
			await viewModel.refreshData()
		}
	}
}

// Boş Durum Görünümü
struct EmptyTransactionsView: View {
	var body: some View {
		VStack(spacing: 12) {
			Image(systemName: "tray")
				.font(.system(size: 40))
				.foregroundColor(.secondary)
			Text("İşlem bulunamadı".localized)
				.foregroundColor(.secondary)
		}
		.frame(maxWidth: .infinity)
		.padding()
		.background(Color(.systemBackground))
		.cornerRadius(12)
		.padding(.horizontal)
	}
}
