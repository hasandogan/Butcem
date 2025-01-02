import Foundation
import FirebaseAuth

@MainActor
class AddTransactionViewModel: ObservableObject {
    @Published var type: TransactionType = .expense
    @Published var amount: Double = 0
    @Published var category: Category = .diger
    @Published var date = Date()
    @Published var note: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    var availableCategories: [Category] {
        switch type {
        case .income:
            return Category.incomeCategories
        case .expense:
            return Category.expenseCategories
        }
    }
    
    var isValid: Bool {
        amount > 0
    }
    
    func saveTransaction() async -> Bool {
        guard isValid else { return false }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let transaction = Transaction(
                userId: AuthManager.shared.user?.uid ?? "",
                amount: amount,
                category: category,
                type: type,
                date: date,
				note: note.isEmpty ? nil : note,
				createdAt: Date()

            )
            
            try await FirebaseService.shared.addTransaction(transaction)
            return true
            
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
} 
