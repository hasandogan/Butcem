import Foundation
import FirebaseFirestore

@MainActor
class TransactionsViewModel: ObservableObject {
    @Published private(set) var transactions: [Transaction] = []
    @Published private(set) var filteredTransactions: [Transaction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var transactionListener: ListenerRegistration?
    
    init() {
        setupFirebaseListener()
        filterTransactions()
    }
    
    deinit {
        transactionListener?.remove()
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupFirebaseListener() {
        transactionListener = FirebaseService.shared.addTransactionListener { [weak self] transactions in
            Task { @MainActor in
                self?.transactions = transactions.filter { transaction in
                    Calendar.current.isDate(transaction.date, equalTo: Date(), toGranularity: .month)
                }.sorted { $0.date > $1.date }
                
                self?.filterTransactions()
                print("Firebase listener updated: \(transactions.count) transactions")
            }
        }
    }
    
    func filterTransactions(type: TransactionType? = nil, category: Category? = nil) {
        filteredTransactions = transactions.filter { transaction in
            var matches = true
            
            if let type = type {
                matches = matches && transaction.type == type
            }
            
            if let category = category {
                matches = matches && transaction.category == category
            }
            
            return matches
        }
        
        print("Filtered transactions: \(filteredTransactions.count)")
        print("Total transactions: \(transactions.count)")
    }
    
    func refreshData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let refreshedTransactions = try await FirebaseService.shared.getTransactions()
            await MainActor.run {
                self.transactions = refreshedTransactions.filter { transaction in
                    Calendar.current.isDate(transaction.date, equalTo: Date(), toGranularity: .month)
                }.sorted { $0.date > $1.date }
                
                self.filterTransactions()
                print("Data refreshed: \(self.transactions.count) transactions")
            }
        } catch {
            errorMessage = error.localizedDescription
            print("Error refreshing data: \(error)")
        }
    }
    
    func deleteTransaction(_ transaction: Transaction) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await FirebaseService.shared.deleteTransaction(transaction)
            // Firebase listener otomatik olarak güncelleyecek
            print("Transaction deleted successfully")
        } catch {
            errorMessage = error.localizedDescription
            print("Error deleting transaction: \(error)")
        }
    }
    
    func exportTransactions(format: ExportFormat, 
                          dateRange: ExportView.DateRange,
                          startDate: Date,
                          endDate: Date) -> URL? {
        guard SubscriptionManager.shared.canAccessPremiumFeatures else {
            errorMessage = "Bu özellik sadece Premium üyelere açıktır"
            return nil
        }
        
        // Tarihe göre filtreleme
        let filteredTransactions = transactions.filter { transaction in
            switch dateRange {
            case .allTime:
                return true
            case .thisMonth, .lastMonth, .custom:
                return transaction.date >= startDate && transaction.date <= endDate
            }
        }
        
        print("Exporting \(filteredTransactions.count) transactions in \(format) format")
        let url = ExportManager.shared.exportTransactions(filteredTransactions, format: format)
        
        if let url = url {
            print("Export successful: \(url.path)")
        } else {
            print("Export failed")
            errorMessage = "Dışa aktarma işlemi başarısız oldu"
        }
        
        return url
    }
} 
