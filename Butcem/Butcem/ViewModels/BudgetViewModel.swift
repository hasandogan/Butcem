import Foundation
import FirebaseFirestore
import Combine
import SwiftUI

@MainActor
class BudgetViewModel: ObservableObject {
    @Published var budget: Budget?
    @Published var pastBudgets: [Budget] = []
    @Published var showAlert = false
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private var currentBudgetListener: ListenerRegistration?
    private var pastBudgetsListener: ListenerRegistration?
    
    init() {
        setupTransactionObserver()
        setupListeners()
        Task {
            await fetchInitialData()
        }
    }
    
    init(forPreview: Bool = false, budget: Budget? = nil, pastBudgets: [Budget] = []) {
        if forPreview {
            self.budget = budget
            self.pastBudgets = pastBudgets
        } else {
            Task {
                await fetchInitialData()
            }
        }
        setupTransactionObserver()
    }
    
    private func setupListeners() {
        // Mevcut ay dinleyicisi
        currentBudgetListener?.remove()
        currentBudgetListener = FirebaseService.shared.addBudgetListener { [weak self] budget in
            Task { @MainActor in
                if let budget = budget {
                    print("📥 Budget received from listener:")
                    print("Total spent: \(budget.spentAmount)")
                    print("Category limits: \(budget.categoryLimits.map { "\($0.category.rawValue): \($0.spent)/\($0.limit)" })")
                    
                    self?.budget = budget
                    
                    // Bütçe limitlerini kontrol et
                    if budget.spentAmount > 0 {
                        self?.checkBudgetLimits()
                    }
                }
            }
        }
        
        // Geçmiş aylar dinleyicisi
        pastBudgetsListener?.remove()
        pastBudgetsListener = FirebaseService.shared.addPastBudgetsListener { [weak self] budgets in
            Task { @MainActor in
                self?.pastBudgets = budgets
            }
        }
    }
    
     func checkBudgetLimits() {
        guard let budget = budget, budget.notificationsEnabled else {
            print("⚠️ Budget check skipped: budget is nil or notifications disabled")
            return 
        }
        
        print("\n🔍 Checking budget limits:")
        print("Total budget: \(budget.amount)")
        print("Total spent: \(budget.spentAmount)")
        print("Notifications enabled: \(budget.notificationsEnabled)")
        
        // Her kategori için kontrol
        for limit in budget.categoryLimits {
            print("\n📊 Checking category: \(limit.category.rawValue)")
            print("Limit: \(limit.limit)")
            print("Spent: \(limit.spent)")
            print("Status: \(limit.status)")
            
            if limit.spent >= limit.limit {
                print("🚨 Category limit exceeded!")
                NotificationManager.shared.scheduleBudgetWarning(
                    for: limit.category,
                    spent: limit.spent,
                    limit: limit.limit,
                    type: limit.status
                )
            } else if limit.spent >= (limit.limit * budget.warningThreshold) {
                print("⚠️ Category approaching limit!")
                NotificationManager.shared.scheduleBudgetWarning(
                    for: limit.category,
                    spent: limit.spent,
                    limit: limit.limit,
                    type: limit.status
                )
            }
        }
        
        // Genel bütçe kontrolü
        if budget.spentAmount >= budget.amount {
            print("\n🚨 Total budget exceeded!")
            NotificationManager.shared.scheduleGeneralBudgetWarning(
                spent: budget.spentAmount,
                total: budget.amount,
                type: budget.status
            )
        } else if budget.spentAmount >= (budget.amount * budget.warningThreshold) {
            print("\n⚠️ Approaching total budget limit!")
            NotificationManager.shared.scheduleGeneralBudgetWarning(
                spent: budget.spentAmount,
                total: budget.amount,
                type: budget.status
            )
        }
    }
    
    private func withProcessing<T>(_ operation: () async throws -> T) async throws -> T {
        isLoading = true
        defer { isLoading = false }
        
        do {
            return try await operation()
        } catch {
            handleError(error)
            throw error
        }
    }
    
    func setBudget(amount: Double, categoryLimits: [CategoryBudget]) async throws {
        try await withProcessing {
            try await FirebaseService.shared.setBudget(amount: amount, categoryLimits: categoryLimits)
        }
    }
    
    private func handleError(_ error: Error) {
        Task { @MainActor in
            self.errorMessage = error.localizedDescription
            self.showAlert = true
        }
    }
    
    func clearError() {
        errorMessage = nil
        showAlert = false
    }
    
    func deleteBudget() async {
        guard let budget = budget else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await FirebaseService.shared.deleteBudget(budget)
            self.budget = nil
        } catch {
            handleError(error)
        }
    }
    
    func updateBudget(amount: Double, categoryLimits: [CategoryBudget]) async {
        guard let budget = budget else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await FirebaseService.shared.updateBudget(budget, amount: amount, categoryLimits: categoryLimits)
        } catch {
            handleError(error)
        }
    }
    
    // Kategori bazlı harcama raporu
    func getCategoryReport() -> [CategoryReport] {
        guard let budget = budget else { return [] }
        
        return budget.categoryLimits.map { limit in
            CategoryReport(
                category: limit.category,
                limit: limit.limit,
                spent: limit.spent,
                remaining: limit.remainingAmount,
                percentage: limit.spentPercentage
            )
        }.sorted { $0.percentage > $1.percentage }
    }
    
    func refreshData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            if let budget = try await FirebaseService.shared.getCurrentBudget() {
                self.budget = budget
                checkBudgetLimits()
            }
        } catch {
            handleError(error)
        }
    }
    
    private func checkMonthChange() {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let savedMonth = UserDefaults.standard.integer(forKey: "lastCheckedMonth")
        
        if currentMonth != savedMonth {
            Task {
                do {
                    // Bildirimleri resetle
                    NotificationManager.shared.resetMonthlyNotifications()
                    
                    // Yeni ay için bütçe oluştur
                    try await FirebaseService.shared.checkAndResetMonthlyBudget()
                    
                    // Son kontrol edilen ayı güncelle
                    UserDefaults.standard.set(currentMonth, forKey: "lastCheckedMonth")
                } catch {
                    handleError(error)
                }
            }
        }
    }
    
    // MARK: - Analysis Methods
    private func getMostSpentCategory(from budgets: [Budget]) -> (Category, Double)? {
        let categoryTotals = Dictionary(grouping: budgets.flatMap { budget in
            budget.categoryLimits.map { ($0.category, $0.spent) }
        }) { $0.0 }
        .mapValues { values in
            values.reduce(0) { $0 + $1.1 }
        }
        
        return categoryTotals.max { $0.value < $1.value }
    }
    
    private func calculateSpendingTrend(from budgets: [Budget]) -> Double {
        guard budgets.count >= 2 else { return 0 }
        
        let sortedBudgets = budgets.sorted { $0.month < $1.month }
        let previousSpending = sortedBudgets.dropLast().last?.spentAmount ?? 0
        let currentSpending = sortedBudgets.last?.spentAmount ?? 0
        
        guard previousSpending > 0 else { return 0 }
        
        // Yüzdelik değişim hesapla
        let change = ((currentSpending - previousSpending) / previousSpending) * 100
        return change
    }
    
    // Geçmiş bütçelerin analizini yap
    func getBudgetTrends() -> BudgetTrends {
        let allBudgets = [budget].compactMap { $0 } + pastBudgets
        
        return BudgetTrends(
            averageSpending: allBudgets.map(\.spentAmount).reduce(0, +) / Double(max(allBudgets.count, 1)),
            mostSpentCategory: getMostSpentCategory(from: allBudgets),
            spendingTrend: calculateSpendingTrend(from: allBudgets),
            monthlyComparison: allBudgets.map { ($0.monthName, $0.spentAmount) }
        )
    }
    
    private func updateCategorySpending() async {
        guard let budget = budget else { return }
        
        // Bu ayın başlangıç tarihini al
        let startOfMonth = Date().startOfMonth()
        
        // Bu ayki işlemleri getir
        let currentMonthTransactions = TransactionStore.shared.transactions.filter { transaction in
            transaction.date >= startOfMonth && transaction.type == .expense
        }
        
        print("Current month transactions found: \(currentMonthTransactions.count)")
        
        // Her kategori için harcamaları hesapla
        var updatedLimits = budget.categoryLimits
        
        for (index, limit) in updatedLimits.enumerated() {
            let spent = currentMonthTransactions
                .filter { $0.category == limit.category }
                .reduce(0) { $0 + $1.amount }
            
            updatedLimits[index].spent = spent
            print("Category \(limit.category.rawValue) spent updated: \(spent)")
        }
        
        // Bütçeyi güncelle
        do {
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
                spentAmount: updatedLimits.reduce(0) { $0 + $1.spent }
            )
            
            try await FirebaseService.shared.updateBudget(updatedBudget)
            await MainActor.run {
                self.budget = updatedBudget
            }
        } catch {
            print("Failed to update budget: \(error)")
        }
    }
    
    // TransactionStore'dan değişiklikleri dinle
    private func setupTransactionObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTransactionUpdate),
            name: .transactionsDidUpdate,
            object: nil
        )
    }
    
    @objc private func handleTransactionUpdate() {
        Task {
            await updateCategorySpending()
        }
    }
    
    private func fetchInitialData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Önce mevcut ayın bütçesini getir
            if let currentBudget = try await FirebaseService.shared.getCurrentBudget() {
                await MainActor.run {
                    self.budget = currentBudget
                    print("Initial budget loaded: \(currentBudget.spentAmount)")
                    print("Category limits: \(currentBudget.categoryLimits.map { "\($0.category.rawValue): \($0.spent)/\($0.limit)" }.joined(separator: ", "))")
                }
            }
            
            // Sonra geçmiş bütçeleri getir
            let pastBudgets = try await FirebaseService.shared.getPastBudgets()
            await MainActor.run {
                self.pastBudgets = pastBudgets
            }
            
            // Bütçe limitlerini kontrol et
            await MainActor.run {
                checkBudgetLimits()
            }
            
            // Harcamaları güncelle
            await updateCategorySpending()
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showAlert = true
            }
        }
    }
}

struct CategoryReport {
    let category: Category
    let limit: Double
    let spent: Double
    let remaining: Double
    let percentage: Double
    
    var status: BudgetStatus {
        switch percentage {
        case 0..<50: return .safe
        case 50..<75: return .quarterWarning
        case 75..<85: return .halfWarning
        case 85..<100: return .criticalWarning
        default: return .danger
        }
    }
}

// Trend analizi için yardımcı struct
struct BudgetTrends {
    let averageSpending: Double
    let mostSpentCategory: (Category, Double)?
    let spendingTrend: Double // Pozitif değer artış, negatif değer azalış trendidir
    let monthlyComparison: [(month: String, amount: Double)]
    
    var trendDescription: String {
        if spendingTrend > 0 {
            return "Harcamalarınız geçen aya göre %\(abs(Int(spendingTrend))) arttı"
        } else if spendingTrend < 0 {
            return "Harcamalarınız geçen aya göre %\(abs(Int(spendingTrend))) azaldı"
        } else {
            return "Harcamalarınız geçen ayla aynı seviyede"
        }
    }
}
