import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class TransactionsViewModel: ObservableObject {
    @Published private(set) var transactions: [Transaction] = []
	@Published var filteredTransactions: [Transaction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
	@Published var updateTrigger = false

    
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
        transactionListener?.remove()
        
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        transactionListener = FirebaseService.shared.addTransactionListener { [weak self] transactions in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.transactions = transactions
                self.filterTransactions()
                print("Updated transactions: \(self.transactions.count)")
                print("First transaction: \(self.transactions.first?.category.rawValue ?? "none")")
            }
        }
    }
    
	func filterTransactions(type: TransactionType? = nil, category: Category? = nil) {
        filteredTransactions = transactions.filter { transaction in
            if let type = type, transaction.type != type {
                return false
            }
            if let category = category, transaction.category != category {
                return false
            }
            return true
        }
        
        // Tarihe göre sıralama yapma çünkü zaten listener'da sıralı geliyor
        updateTrigger.toggle()
        print("Update trigger toggled: \(updateTrigger)")
        print("Filtered transactions count: \(filteredTransactions.count)")
    }
	
    
    func refreshData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Önce kullanıcı ayarlarını al
            let settings = try await FirebaseService.shared.getUserSettings() ?? UserSettings(userId: Auth.auth().currentUser?.uid ?? "")
            let billingPeriod = settings.currentBillingPeriod
            
            // Tüm işlemleri getir ve hesap kesim dönemine göre filtrele
            let refreshedTransactions = try await FirebaseService.shared.getTransactions()
            await MainActor.run {
                self.transactions = refreshedTransactions.filter { transaction in
                    // Hesap kesim dönemine göre filtrele
                    transaction.date >= billingPeriod.startDate && 
                    transaction.date <= billingPeriod.endDate
                }.sorted { $0.date > $1.date }
                
                self.filterTransactions()
                print("Data refreshed: \(self.transactions.count) transactions")
                print("Billing period: \(billingPeriod.startDate.formatted()) - \(billingPeriod.endDate.formatted())")
            }
        } catch {
            errorMessage = error.localizedDescription
            print("Error refreshing data: \(error)")
        }
    }
    
    func deleteTransaction(_ transaction: Transaction) async throws {
        try await FirebaseService.shared.deleteTransaction(transaction)
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
