import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class FamilyBudgetViewModel: ObservableObject {
    @Published private(set) var familyBudgets: [FamilyBudget] = []
    @Published private(set) var currentBudget: FamilyBudget?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
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
                } else {
                    print("No active budget found")
                    self?.currentBudget = nil
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
        
        let familyBudget = FamilyBudget(
            creatorId: AuthManager.shared.currentUserId ?? "",
            name: name,
            members: members.map { email in
                FamilyBudget.FamilyMember(
                    id: UUID().uuidString,
                    name: "",
                    email: email,
                    role: .member,
                    spentAmount: 0
                )
            },
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
    
    func addTransaction(_ transaction: Transaction) async throws {
        guard let budget = currentBudget else { return }
        
        // İşlemi ekle ve bütçeyi güncelle
        try await FirebaseService.shared.addFamilyTransaction(
            transaction,
            toBudget: budget
        )
    }
    
    // Admin yetki kontrolü
    var isAdmin: Bool {
        guard let currentUserEmail = Auth.auth().currentUser?.email,
              let budget = currentBudget else { return false }
        
        return budget.members.first { $0.email == currentUserEmail }?.role == .admin
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
        guard isAdmin else {
            throw NetworkError.authenticationError
        }
        
        // Bütçeyi güncelle
        var updatedBudget = budget
        updatedBudget.spentAmount += transaction.amount
        
        // Üyenin harcamasını güncelle
        if let index = updatedBudget.members.firstIndex(where: { $0.email == Auth.auth().currentUser?.email }) {
            updatedBudget.members[index].spentAmount += transaction.amount
        }
        
        // Kategori limitini güncelle
        if let index = updatedBudget.categoryLimits.firstIndex(where: { $0.category.rawValue == transaction.category.rawValue }) {
            updatedBudget.categoryLimits[index].spent += transaction.amount
        }
        
        // Önce işlemi kaydet
        try await FirebaseService.shared.addFamilyTransaction(transaction, toBudget: budget)
        
        // Sonra bütçeyi güncelle
        try await FirebaseService.shared.updateFamilyBudget(updatedBudget)
        
        // UI'ı güncelle
        await MainActor.run {
            self.currentBudget = updatedBudget
        }
    }
} 
