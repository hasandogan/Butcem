import Foundation
import FirebaseAuth

@MainActor
class AddTransactionViewModel: ObservableObject {
    @Published var amount: Double = 0
    @Published var category: Category
    @Published var date = Date()
    @Published var note: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    let type: TransactionType
    
    init(type: TransactionType) {
        self.type = type
        self.category = type == .income ? .maas : .market
    }
    
    var availableCategories: [Category] {
        type == .income ? Category.incomeCategories : Category.expenseCategories
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
				userId: AuthManager.shared.currentUserId ?? "",
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
