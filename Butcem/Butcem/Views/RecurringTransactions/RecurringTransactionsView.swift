import SwiftUI

struct RecurringTransactionsView: View {
    @StateObject private var viewModel = RecurringTransactionViewModel()
    @State private var showingAddSheet = false
    @State private var selectedTransaction: RecurringTransaction?
    @State private var selectedFilter: TransactionType = .all
    
    private var filteredTransactions: [RecurringTransaction] {
        switch selectedFilter {
        case .all:
            return viewModel.recurringTransactions
        case .income, .expense:
            return viewModel.recurringTransactions.filter { $0.type == selectedFilter }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Filtre Segmenti
				Picker("Filtre".localized, selection: $selectedFilter) {
					Text("Tümü".localized).tag(TransactionType.all)
					Text("Gelirler".localized).tag(TransactionType.income)
					Text("Giderler".localized).tag(TransactionType.expense)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // İşlem Kartları
                LazyVStack(spacing: 12) {
                    ForEach(filteredTransactions) { transaction in
                        RecurringTransactionCard(transaction: transaction)
                            .onTapGesture {
                                selectedTransaction = transaction
                            }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
		.navigationTitle("Tekrarlanan İşlemler".localized)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddRecurringTransactionView(viewModel: viewModel)
        }
        .sheet(item: $selectedTransaction) { transaction in
            EditRecurringTransactionView(viewModel: viewModel, transaction: transaction)
        }
    }
}

struct RecurringTransactionCard: View {
    let transaction: RecurringTransaction
    
    var body: some View {
        VStack(spacing: 12) {
            // Başlık ve Tutar
            HStack {
                Label(transaction.title, systemImage: transaction.category.icon)
                    .font(.headline)
                Spacer()
                Text(transaction.amount.currencyFormat())
                    .font(.headline)
                    .foregroundColor(transaction.type == .expense ? .red : .green)
            }
            
            Divider()
            
            // Detaylar
            HStack {
                // Kategori
                VStack(alignment: .leading) {
					Text("Kategori".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
					Text(transaction.category.localizedName)
                        .font(.subheadline)
                }
                
                Spacer()
                
                // Sıklık
                VStack(alignment: .trailing) {
					Text("Sıklık".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(transaction.frequency.description)
                        .font(.subheadline)
                }
            }
            
            // Son ve Sonraki İşlem
            HStack {
                // Son İşlem
                VStack(alignment: .leading) {
					Text("Son İşlem".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(transaction.lastProcessed?.formattedDate() ?? "-")
                        .font(.subheadline)
                }
                
                Spacer()
                
                // Sonraki İşlem
                VStack(alignment: .trailing) {
					Text("Sonraki".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let nextDate = transaction.nextProcessDate {
                        Text(nextDate.formattedDate())
                            .font(.subheadline)
                    } else {
                        Text("-")
                            .font(.subheadline)
                    }
                }
            }
            
            // Durum
            HStack {
				ReccuringStatusBadge(isActive: transaction.isActive)
                Spacer()
                if let note = transaction.note {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct ReccuringStatusBadge: View {
    let isActive: Bool
    
    var body: some View {
        Text(isActive ? "Aktif" : "Pasif")
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isActive ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
            .foregroundColor(isActive ? .green : .gray)
            .cornerRadius(8)
    }
}

