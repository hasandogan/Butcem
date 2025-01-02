import Foundation
import FirebaseFirestore

@MainActor
class FinancialGoalViewModel: ObservableObject {
    @Published private(set) var goals: [FinancialGoal] = []
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var showAlert = false
    
    private var listener: ListenerRegistration?
    
    init() {
        setupListener()
    }
    
    deinit {
        listener?.remove()
    }
    
    private func setupListener() {
        listener = FirebaseService.shared.addFinancialGoalListener { [weak self] goals in
            Task { @MainActor in
                self?.goals = goals.sorted { $0.deadline < $1.deadline }
            }
        }
    }
    
    // MARK: - Computed Properties
    var activeGoals: [FinancialGoal] {
        goals.filter { !$0.isCompleted }
    }
    
    var completedGoals: [FinancialGoal] {
        goals.filter { $0.isCompleted }
    }
    
    var totalSavingsTarget: Double {
        goals.reduce(0) { $0 + $1.targetAmount }
    }
    
    var totalCurrentSavings: Double {
        goals.reduce(0) { $0 + $1.currentAmount }
    }
    
    var overallProgress: Double {
        guard totalSavingsTarget > 0 else { return 0 }
        return (totalCurrentSavings / totalSavingsTarget) * 100
    }
    
    // MARK: - Helper Methods
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
    
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showAlert = true
    }
    
    func clearError() {
        errorMessage = nil
        showAlert = false
    }
    
    // MARK: - CRUD Operations
    func addGoal(_ goal: FinancialGoal) async {
        do {
            try await withProcessing {
                try await FirebaseService.shared.addFinancialGoal(goal)
            }
        } catch {
            handleError(error)
        }
    }
    
    func updateGoal(_ goal: FinancialGoal) async {
        do {
            try await withProcessing {
                try await FirebaseService.shared.updateFinancialGoal(goal)
            }
        } catch {
            handleError(error)
        }
    }
    
    func deleteGoal(_ goal: FinancialGoal) async {
        do {
            try await withProcessing {
                try await FirebaseService.shared.deleteFinancialGoal(goal)
            }
        } catch {
            handleError(error)
        }
    }
    
    func updateProgress(_ goal: FinancialGoal, amount: Double) async {
        do {
            try await withProcessing {
                try await FirebaseService.shared.updateGoalProgress(goal, amount: amount)
            }
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - Analysis Methods
    func getGoalsByCategory() -> [GoalCategory: [FinancialGoal]] {
        Dictionary(grouping: goals) { $0.category }
    }
    
    func getProgressForCategory(_ category: GoalCategory) -> Double {
        let categoryGoals = goals.filter { $0.category == category }
        let totalTarget = categoryGoals.reduce(0) { $0 + $1.targetAmount }
        let totalCurrent = categoryGoals.reduce(0) { $0 + $1.currentAmount }
        
        guard totalTarget > 0 else { return 0 }
        return (totalCurrent / totalTarget) * 100
    }
    
    func getMonthlyTargetAmount() -> Double {
        activeGoals.reduce(0) { $0 + $1.monthlyTargetAmount }
    }
    
    func getUpcomingDeadlines(within days: Int = 30) -> [FinancialGoal] {
        let futureDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        return activeGoals.filter { $0.deadline <= futureDate }
    }
} 