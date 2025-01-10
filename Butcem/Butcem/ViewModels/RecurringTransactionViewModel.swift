import Foundation
import FirebaseFirestore

@MainActor
class RecurringTransactionViewModel: ObservableObject {
    @Published private(set) var recurringTransactions: [RecurringTransaction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var listener: ListenerRegistration?
    
    init() {
        setupListener()
    }
    
    private func setupListener() {
         let userId = AuthManager.shared.currentUserId
        
        listener = FirebaseService.shared.addRecurringTransactionListener(userId: userId) { [weak self] transactions in
            self?.recurringTransactions = transactions
        }
    }
    
    func addRecurringTransaction(_ transaction: RecurringTransaction) async throws {
        isLoading = true
        defer { isLoading = false }
        
        try await FirebaseService.shared.addRecurringTransaction(transaction)
    }
    
    func updateRecurringTransaction(_ transaction: RecurringTransaction) async throws {
        isLoading = true
        defer { isLoading = false }
        
        try await FirebaseService.shared.updateRecurringTransaction(transaction)
    }
    
    func deleteRecurringTransaction(_ transaction: RecurringTransaction) async throws {
        isLoading = true
        defer { isLoading = false }
        
        try await FirebaseService.shared.deleteRecurringTransaction(transaction)
    }
    
    func processRecurringTransactions() async {
        for transaction in recurringTransactions where transaction.isActive {
            if let nextDate = transaction.nextProcessDate,
               nextDate <= Date(),
               let lastProcessed = transaction.lastProcessed {
                
                // Yeni işlem oluştur
                let newTransaction = Transaction(
                    userId: transaction.userId,
                    amount: transaction.amount,
                    category: transaction.category,
                    type: transaction.type,
                    date: nextDate,
                    note: "Otomatik oluşturuldu: \(transaction.title)",
                    createdAt: Date()
                )
                
                do {
                    try await FirebaseService.shared.addTransaction(newTransaction)
                    
                    // Son işlem tarihini güncelle
                    var updatedRecurring = transaction
                    updatedRecurring.lastProcessed = nextDate
                    try await FirebaseService.shared.updateRecurringTransaction(updatedRecurring)
                } catch {
                    print("Tekrarlanan işlem oluşturulurken hata: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func checkAndProcessTransactions() async {
        let now = Date()
        
        for transaction in recurringTransactions where transaction.isActive {
            if let nextDate = transaction.nextProcessDate,
               nextDate <= now {
                do {
                    // Yeni işlem oluştur
                    let newTransaction = Transaction(
                        userId: transaction.userId,
                        amount: transaction.amount,
                        category: transaction.category,
                        type: transaction.type,
                        date: nextDate,
                        note: "Otomatik oluşturuldu: \(transaction.title)",
                        createdAt: Date()
                    )
                    
                    // İşlemi ekle
                    try await FirebaseService.shared.addTransaction(newTransaction)
                    
                    // Son işlem tarihini güncelle
                    var updatedTransaction = transaction
                    updatedTransaction.lastProcessed = nextDate
                    try await FirebaseService.shared.updateRecurringTransaction(updatedTransaction)
                    
                    // Bildirim planla
                    NotificationManager.shared.scheduleRecurringTransactionNotification(for: updatedTransaction)
                    
                    print("✅ Tekrarlanan işlem otomatik olarak oluşturuldu: \(transaction.title)")
                } catch {
                    print("❌ Tekrarlanan işlem oluşturulurken hata: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Uygulama açıldığında ve belirli aralıklarla kontrol et
    func startPeriodicCheck() {
        // İlk kontrol
        Task {
            await checkAndProcessTransactions()
        }
        
        // Periyodik kontrol için timer kur (örneğin her saat)
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.checkAndProcessTransactions()
            }
        }
    }
} 
