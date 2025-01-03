import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class FamilyBudgetViewModel: ObservableObject {
    @Published private(set) var familyBudgets: [FamilyBudget] = []
    @Published private(set) var currentBudget: FamilyBudget?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var transactions: [FamilyTransaction] = []
    
    private var budgetListener: ListenerRegistration?
    
    init() {
        setupListeners()
    }
    
    private func setupListeners() {
        // Dinleyicileri kur
        guard let userEmail = Auth.auth().currentUser?.email else {
            print("No user email found")
            return
        }
        
        print("Setting up new listener for email: \(userEmail)")
        
        budgetListener = FirebaseService.shared.addFamilyBudgetListener { [weak self] budget in
            Task { @MainActor in
                if let budget = budget {
                    print("Received budget update: \(budget.name)")
                    self?.currentBudget = budget
                    
                    // İşlemleri getir
                    if let budgetId = budget.id {
                        do {
                            let transactions = try await FirebaseService.shared.getFamilyTransactions(budgetId: budgetId)
                            await MainActor.run {
                                self?.transactions = transactions
                                print("Loaded \(transactions.count) family transactions")
                            }
                        } catch {
                            print("Error loading transactions: \(error)")
                        }
                    }
                } else {
                    print("No active budget found")
                    self?.currentBudget = nil
                    self?.transactions = []
                }
            }
        }
    }
    
    deinit {
        print("FamilyBudgetViewModel deinit")
        budgetListener?.remove()
        budgetListener = nil
    }
    
    func createFamilyBudget(name: String, members: [String], totalBudget: Double) async throws {
        print("Creating budget with name: \(name)")
        print("Members to invite: \(members)")
        
        guard let currentUserEmail = Auth.auth().currentUser?.email else { return }
        
        // Önce mevcut kullanıcıyı admin olarak ekle
        let currentUser = FamilyBudget.FamilyMember(
            id: AuthManager.shared.currentUserId ?? "",
            name: Auth.auth().currentUser?.displayName ?? "",
            email: currentUserEmail,
            role: .admin,
            spentAmount: 0
        )
        
        // Diğer üyeleri member rolüyle ekle
        let membersList = members.map { email in
            FamilyBudget.FamilyMember(
                id: UUID().uuidString,
                name: "",
                email: email,
                role: .member,
                spentAmount: 0
            )
        }
        
        let familyBudget = FamilyBudget(
            creatorId: AuthManager.shared.currentUserId ?? "",
            name: name,
            members: [currentUser] + membersList, // Tüm üyeleri birleştir
            categoryLimits: [],
            totalBudget: totalBudget,
            createdAt: Date(),
            month: Date().startOfMonth(),
            spentAmount: 0
        )
        
        try await FirebaseService.shared.createFamilyBudget(familyBudget)
    }
    
    func inviteMember(email: String) async throws {
        guard let budget = currentBudget else { return }
        
        // Email davetiyesi gönder
        try await FirebaseService.shared.sendBudgetInvitation(
            to: email,
            budgetId: budget.id ?? "",
            budgetName: budget.name
        )
    }
    
	func addTransaction(_ familyTransaction: FamilyTransaction) async throws {
        guard let budget = currentBudget else { return }
        
        // İşlemi ekle ve bütçeyi güncelle
        try await FirebaseService.shared.addFamilyTransaction(
			familyTransaction,
            toBudget: budget
        )
    }
    
    // Admin yetki kontrolü
    var isAdmin: Bool {
        guard let currentUserEmail = Auth.auth().currentUser?.email,
              let budget = currentBudget else { return false }
        
        return budget.members.first { member in 
            member.email == currentUserEmail && member.role == .admin 
        } != nil
    }
    
    // Bütçeyi güncelle
    func updateBudget(name: String? = nil, totalBudget: Double? = nil) async throws {
        guard isAdmin, var updatedBudget = currentBudget else {
            throw NetworkError.authenticationError
        }
        
        if let name = name {
            updatedBudget.name = name
        }
        
        if let totalBudget = totalBudget {
            updatedBudget.totalBudget = totalBudget
        }
        
        try await FirebaseService.shared.updateFamilyBudget(updatedBudget)
    }
    
    // Üye ekle
    func addMember(_ email: String) async throws {
        guard isAdmin, var updatedBudget = currentBudget else {
            throw NetworkError.authenticationError
        }
        
        let newMember = FamilyBudget.FamilyMember(
            id: UUID().uuidString,
            name: "",
            email: email,
            role: .member,
            spentAmount: 0
        )
        
        updatedBudget.members.append(newMember)
        try await FirebaseService.shared.updateFamilyBudget(updatedBudget)
        try await inviteMember(email: email)
    }
    
    // Üye çıkar
    func removeMember(_ email: String) async throws {
        guard isAdmin, var updatedBudget = currentBudget else {
            throw NetworkError.authenticationError
        }
        
        updatedBudget.members.removeAll { $0.email == email }
        try await FirebaseService.shared.updateFamilyBudget(updatedBudget)
    }
    
    // Bütçeyi sil
    func deleteBudget() async throws {
        guard isAdmin, let budget = currentBudget else {
            throw NetworkError.authenticationError
        }
        
        // Önce dinleyiciyi kaldır
        budgetListener?.remove()
        budgetListener = nil
        
        // Bütçeyi sil
        try await FirebaseService.shared.deleteFamilyBudget(budget)
        
        // UI'ı güncelle
        await MainActor.run {
            self.currentBudget = nil
        }
        
        // Yeni dinleyici kur
        setupListeners()
    }
    
    // Aile bütçesine işlem ekle
    func addFamilyTransaction(_ transaction: FamilyTransaction, toBudget budget: FamilyBudget) async throws {
        var updatedBudget = budget
        
        // İşlemi ekle
        try await FirebaseService.shared.addFamilyTransaction(transaction, toBudget: budget)
        
        // Kategori limitini güncelle
        if let index = updatedBudget.categoryLimits.firstIndex(where: { $0.category == transaction.category }) {
            updatedBudget.categoryLimits[index].spent += transaction.amount
        } else {
            let newLimit = FamilyCategoryBudget(
                id: UUID().uuidString,
                category: transaction.category,
                limit: transaction.amount * 2,
                spent: transaction.amount
            )
            updatedBudget.categoryLimits.append(newLimit)
        }
        
        // Toplam harcamayı güncelle
        updatedBudget.spentAmount += transaction.amount
        
        // Üyenin harcamasını güncelle
        if let index = updatedBudget.members.firstIndex(where: { $0.email == Auth.auth().currentUser?.email }) {
            updatedBudget.members[index].spentAmount += transaction.amount
        }
        
        // Bütçeyi güncelle
        try await FirebaseService.shared.updateFamilyBudget(updatedBudget)
    }
    
    func updateCategoryLimits(_ limits: [FamilyCategoryBudget]) async throws {
        guard isAdmin, var updatedBudget = currentBudget else {
            throw NetworkError.authenticationError
        }
        
        updatedBudget.categoryLimits = limits
        try await FirebaseService.shared.updateFamilyBudget(updatedBudget)
    }
} 
