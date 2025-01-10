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
        
		let userId = AuthManager.shared.currentUserId
        
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
            let settings = try await FirebaseService.shared.getUserSettings() ?? UserSettings(userId: AuthManager.shared.currentUserId)
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
} 
