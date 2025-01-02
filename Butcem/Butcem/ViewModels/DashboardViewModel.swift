import FirebaseFirestore

@MainActor
class DashboardViewModel: BaseViewModel {
    // MARK: - Properties
    @Published private(set) var transactions: [Transaction] = []
    @Published var budget: Budget?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var categorySpending: [CategorySpending] = []
    
    private var transactionListener: ListenerRegistration?
    private var budgetListener: ListenerRegistration?
    
    // MARK: - Computed Properties
    var totalIncome: Double {
        TransactionStore.shared.currentMonthIncomes.reduce(0) { $0 + $1.amount }
    }
    
    var totalExpense: Double {
        TransactionStore.shared.currentMonthExpenses.reduce(0) { $0 + $1.amount }
    }
    
    var netAmount: Double {
        totalIncome - totalExpense
    }
    
    // Son işlemler
    var recentTransactions: [Transaction] {
        Array(TransactionStore.shared.transactions.prefix(5))
    }
    
    var monthlySpending: [CategorySpending] {
        let expenses = TransactionStore.shared.currentMonthExpenses
        var categoryAmounts: [Category: Double] = [:]
        
        // Toplam harcamayı hesapla
        let totalExpense = expenses.reduce(0) { $0 + $1.amount }
        
        // Kategori bazlı harcamaları hesapla
        expenses.forEach { transaction in
            categoryAmounts[transaction.category, default: 0] += transaction.amount
        }
        
        return categoryAmounts.map { category, amount in
            CategorySpending(
                category: category,
                amount: amount,
                totalAmount: totalExpense
            )
        }.sorted { $0.amount > $1.amount }
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupListeners()
        setupObservers()
        calculateCategorySpending()
    }
    
    deinit {
        transactionListener?.remove()
        budgetListener?.remove()
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupListeners() {
        // İşlem dinleyicisi
        transactionListener?.remove()
        transactionListener = FirebaseService.shared.addTransactionListener { [weak self] transactions in
            Task { @MainActor in
                TransactionStore.shared.update(with: transactions)
                self?.objectWillChange.send()
                self?.calculateCategorySpending()
            }
        }
        
        // Bütçe dinleyicisi
        budgetListener?.remove()
        budgetListener = FirebaseService.shared.addBudgetListener { [weak self] budget in
            Task { @MainActor in
                self?.budget = budget
                self?.objectWillChange.send()
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
        objectWillChange.send()
        calculateCategorySpending()
        updateBudgetStatus()
    }
    
    // MARK: - Public Methods
    func refreshData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // TransactionStore'u yenile
            await TransactionStore.shared.refresh()
            
            // Bütçeyi yenile
            if let budget = try? await FirebaseService.shared.getCurrentBudget() {
                self.budget = budget
            }
            
            // Kategori harcamalarını güncelle
            calculateCategorySpending()
            
            // Bütçe limitlerini kontrol et
			BudgetViewModel().checkBudgetLimits()
            
            print("Dashboard data refreshed successfully")
            print("Transaction count: \(TransactionStore.shared.transactions.count)")
            print("Current month transactions: \(TransactionStore.shared.currentMonthTransactions.count)")
            
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to refresh dashboard: \(error)")
        }
    }
    
    func deleteTransaction(_ transaction: Transaction) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await FirebaseService.shared.deleteTransaction(transaction)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    var upcomingRecurringTransactions: [RecurringTransaction] {
        let calendar = Calendar.current
        let thirtyDaysFromNow = calendar.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        
        return TransactionStore.shared.recurringTransactions
            .filter { transaction in
                guard let lastProcessed = transaction.lastProcessed else { return true }
                let nextDate = calendar.date(
                    byAdding: transaction.frequency.calendarComponent,
                    value: 1,
                    to: lastProcessed
                ) ?? Date()
                return nextDate <= thirtyDaysFromNow
            }
            .sorted { $0.lastProcessed ?? Date.distantPast < $1.lastProcessed ?? Date.distantPast }
    }
    
    private func calculateCategorySpending() {
        let expenses = TransactionStore.shared.currentMonthExpenses
        var categoryAmounts: [Category: Double] = [:]
        
        let totalExpense = expenses.reduce(0) { $0 + $1.amount }
        
        expenses.forEach { transaction in
            categoryAmounts[transaction.category, default: 0] += transaction.amount
        }
        
        categorySpending = categoryAmounts.map { category, amount in
            CategorySpending(
                category: category,
                amount: amount,
                totalAmount: totalExpense
            )
        }.sorted { $0.amount > $1.amount }
    }
    
    private func updateBudgetStatus() {
        guard let budget = budget else { return }
        
        // Bu ayın başlangıç tarihini al
        let startOfMonth = Date().startOfMonth()
        
        // Bu ayki işlemleri getir
        let currentMonthTransactions = transactions.filter { transaction in
            transaction.date >= startOfMonth && transaction.type == .expense
        }
        
        // Her kategori için harcamaları hesapla ve bütçeyi güncelle
        var updatedLimits = budget.categoryLimits
        
        for (index, limit) in updatedLimits.enumerated() {
            let spent = currentMonthTransactions
                .filter { $0.category == limit.category }
                .reduce(0) { $0 + $1.amount }
            
            updatedLimits[index].spent = spent
        }
        
        // Bütçeyi güncelle
        Task {
            let updatedBudget = Budget(
                id: budget.id,
                userId: budget.userId,
                amount: budget.amount,
                categoryLimits: updatedLimits,
                month: budget.month,
                createdAt: budget.createdAt,
                warningThreshold: budget.warningThreshold,
                dangerThreshold: budget.dangerThreshold,
                notificationsEnabled: budget.notificationsEnabled,
                spentAmount: budget.spentAmount
            )
            
            try? await FirebaseService.shared.updateBudget(updatedBudget)
            await MainActor.run {
                self.budget = updatedBudget
            }
        }
    }
}



