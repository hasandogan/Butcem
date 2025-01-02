import SwiftUI
import FirebaseFirestore
import Combine

@MainActor
class TransactionViewModel: BaseViewModel {
    @Published private(set) var transactions: [Transaction] = []
    @Published private(set) var filteredTransactions: [Transaction] = []
    @Published var selectedPeriod: AnalysisPeriod = .monthly
    @Published var selectedType: TransactionType?
    @Published var selectedCategory: Category?
    @Published var searchText: String = ""
    @Published var isLoading = false
    @Published var showSuccess = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    private var transactionListener: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        setupListener()
        setupObservers()
        setupFilters()
    }
    
    deinit {
        transactionListener?.remove()
        NotificationCenter.default.removeObserver(self)
    }
    
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }
    
	internal override func withProcessing<T>(_ operation: () async throws -> T) async throws -> T {
        isLoading = true
        defer { isLoading = false }
        
        do {
            return try await operation()
        } catch {
            handleError(error)
            throw error
        }
    }
    
    func addTransaction(_ transaction: Transaction) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // İşlemi kaydet
            try await FirebaseService.shared.addTransaction(transaction)
            
            // Bütçe harcamalarını güncelle
            try await FirebaseService.shared.updateBudgetSpending(for: transaction)
            
            // İşlem başarılı
            showSuccess = true
        } catch {
            handleError(error)
        }
    }
    
    func deleteTransaction(_ transaction: Transaction) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // İşlemi sil
            try await FirebaseService.shared.deleteTransaction(transaction)
            
            // Bütçe harcamalarını güncelle (ters işlem)
            let reversedTransaction = transaction.copy(
                with: transaction.type == .income ? .expense : .income
            )
            try await FirebaseService.shared.updateBudgetSpending(for: reversedTransaction)
            
        } catch {
            handleError(error)
        }
    }
    
    private func setupListener() {
        transactionListener = FirebaseService.shared.addTransactionListener { [weak self] transactions in
            Task { @MainActor in
                self?.transactions = transactions
                TransactionStore.shared.update(with: transactions)
            }
        }
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTransactionsUpdate),
            name: .transactionsDidUpdate,
            object: nil
        )
    }
    
    @objc private func handleTransactionsUpdate() {
        Task { @MainActor in
            NotificationCenter.default.post(name: .budgetDidUpdate, object: nil)
        }
    }
    
    func clearError() {
        errorMessage = nil
        showError = false
    }
    
    func clearSuccess() {
        showSuccess = false
    }
    
    private func setupFilters() {
        // Combine kullanarak filtreleri birleştir
        Publishers.CombineLatest4($transactions, $selectedPeriod, $selectedType, $selectedCategory)
            .combineLatest($searchText)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] combined in
                let ((transactions, selectedPeriod, selectedType, selectedCategory), searchText) = combined
                self?.applyFilters(
                    transactions: transactions,
                    period: selectedPeriod,
                    type: selectedType,
                    category: selectedCategory,
                    searchText: searchText
                )
            }
            .store(in: &cancellables)
    }
    
    private func applyFilters(
        transactions: [Transaction],
        period: AnalysisPeriod,
        type: TransactionType?,
        category: Category?,
        searchText: String
    ) {
        var filtered = transactions
        
        // Tarih filtresi
        let startDate = Calendar.current.date(
            byAdding: period.dateRange,
            to: Date()
        ) ?? Date()
        
        filtered = filtered.filter { $0.date >= startDate }
        
        // İşlem tipi filtresi
        if let type = type {
            filtered = filtered.filter { $0.type == type }
        }
        
        // Kategori filtresi
        if let category = category {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Arama filtresi
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.note?.localizedCaseInsensitiveContains(searchText) ?? false ||
                $0.category.rawValue.localizedCaseInsensitiveContains(searchText) ||
                $0.amount.description.contains(searchText)
            }
        }
        
        // Tarihe göre sırala
        filtered.sort { $0.date > $1.date }
        
        filteredTransactions = filtered
    }
    
    // Filtreleri sıfırla
    func resetFilters() {
        selectedPeriod = .monthly
        selectedType = nil
        selectedCategory = nil
        searchText = ""
    }
    
    // Seçili filtrelere göre özet bilgiler
    var summary: TransactionSummary {
        let income = filteredTransactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
        
        let expense = filteredTransactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
        
        return TransactionSummary(
            income: income,
            expense: expense,
            balance: income - expense,
            count: filteredTransactions.count
        )
    }
    
    // Kategori bazlı özet
    var categorySummary: [CategorySummary] {
        Dictionary(grouping: filteredTransactions) { $0.category }
            .map { category, transactions in
                let total = transactions.reduce(0) { $0 + $1.amount }
                return CategorySummary(
                    category: category,
                    total: total,
                    count: transactions.count
                )
            }
            .sorted { $0.total > $1.total }
    }
}

// Özet bilgiler için yardımcı struct'lar
struct TransactionSummary {
    let income: Double
    let expense: Double
    let balance: Double
    let count: Int
}

struct CategorySummary {
    let category: Category
    let total: Double
    let count: Int
} 

