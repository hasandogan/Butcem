import SwiftUI

struct TransactionsView: View {
	@StateObject private var viewModel = TransactionsViewModel()
	@ObservedObject private var subscriptionManager = SubscriptionManager.shared
	@State private var showingFilter = false
	@State private var selectedType: TransactionType?
	@State private var selectedCategory: Category?
	
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
								Label("Sil", systemImage: "trash")
							}
						}
					}
				}
				.listStyle(.plain)
			}
		}
		.navigationTitle("İşlemler")
		.toolbar {
			ToolbarItem(placement: .navigationBarTrailing) {
				Menu {
					// Tüm işlemler
					Button {
						selectedType = nil
						selectedCategory = nil
						viewModel.filterTransactions(type: nil, category: nil)
					} label: {
						Label("Tümü", systemImage: "list.bullet")
					}
					
					Menu("İşlem Tipi") {
						ForEach(TransactionType.allCases, id: \.self) { type in
							Button {
								selectedType = type
								viewModel.filterTransactions(type: type, category: selectedCategory)
							} label: {
								Label(type.rawValue, systemImage: type == .income ? "plus.circle" : "minus.circle")
							}
						}
					}
					
					Menu("Kategori") {
						ForEach(Category.allCases, id: \.self) { category in
							Button {
								selectedCategory = category
								viewModel.filterTransactions(type: selectedType, category: category)
							} label: {
								Label(category.rawValue, systemImage: category.icon)
							}
						}
					}
				} label: {
					Label("Filtrele", systemImage: "line.3.horizontal.decrease.circle")
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
			Text("İşlem bulunamadı")
				.foregroundColor(.secondary)
		}
		.frame(maxWidth: .infinity)
		.padding()
		.background(Color(.systemBackground))
		.cornerRadius(12)
		.padding(.horizontal)
	}
}
