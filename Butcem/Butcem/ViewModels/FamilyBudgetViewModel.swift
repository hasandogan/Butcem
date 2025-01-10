import Foundation
import FirebaseFirestore

@MainActor
class FamilyBudgetViewModel: ObservableObject {
	@Published private(set) var familyBudgets: [FamilyBudget] = []
	@Published private(set) var currentBudget: FamilyBudget?
	@Published var isLoading = false
	@Published var errorMessage: String?
	@Published private(set) var transactions: [FamilyTransaction] = []
	@Published var showError = false
	
	private var budgetListener: ListenerRegistration?
	
	init() {
		setupListeners()
	}
	
	private func setupListeners() {
		print("Setting up new listener for userId: \(AuthManager.shared.currentUserId)")
		
		// Önceki listener'ı temizle
		budgetListener?.remove()
		budgetListener = nil
		
		budgetListener = FirebaseService.shared.addFamilyBudgetListener { [weak self] budget in
			guard let self = self else { return }
			
			Task { @MainActor in
				if let budget = budget {
					print("Received budget update: \(budget.name) with ID: \(budget.id ?? "unknown")")
					self.currentBudget = budget
					
					// İşlemleri getir
					if let budgetId = budget.id {
						do {
							let transactions = try await FirebaseService.shared.getFamilyTransactions(budgetId: budgetId)
							self.transactions = transactions
							print("Loaded \(transactions.count) family transactions")
						} catch {
							print("Error loading transactions: \(error.localizedDescription)")
						}
					}
				} else {
					print("No active budget found for user: \(AuthManager.shared.currentUserId)")
					self.currentBudget = nil
					self.transactions = []
				}
			}
		}
	}
	
	deinit {
		print("FamilyBudgetViewModel deinit")
		budgetListener?.remove()
		
		budgetListener = nil
	}
	
	func createFamilyBudget(name: String, totalBudget: Double) async throws {
		print("🔄 Creating new family budget...")
		
		let currentUser = FamilyBudget.FamilyMember(
			id: AuthManager.shared.currentUserId,
			name: AuthManager.shared.currentUserName,
			role: .admin,
			spentAmount: 0
		)
		
		let familyBudget = FamilyBudget(
			creatorId: AuthManager.shared.currentUserId,
			name: name,
			members: [currentUser],
			categoryLimits: [],
			totalBudget: totalBudget,
			createdAt: Date(),
			month: Date().startOfMonth(),
			spentAmount: 0
		)
		
		// Önce listener'ı kaldır
		budgetListener?.remove()
		budgetListener = nil
		
		// Bütçeyi oluştur
		try await FirebaseService.shared.createFamilyBudget(familyBudget)
		print("✅ Family budget created successfully")
		
		// Kısa bir gecikme ekle
		try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 saniye
		
		// Listener'ı yeniden kur
		setupListeners()
		print("🔄 Listeners restarted after budget creation")
		
		// Bütçeyi hemen güncelle
		if let newBudget = try? await FirebaseService.shared.getFamilyBudget() {
			await MainActor.run {
				self.currentBudget = newBudget
				print("✅ Budget updated immediately after creation")
			}
		}
	}
	
	func addTransaction(_ familyTransaction: FamilyTransaction) async throws {
		guard let budget = currentBudget else { return }
		try await FirebaseService.shared.addFamilyTransaction(familyTransaction, toBudget: budget)
	}
	
	// Admin yetki kontrolü
	var isAdmin: Bool {
		guard let budget = currentBudget else { return false }
		let currentUserId = AuthManager.shared.currentUserId
		return budget.members.first { member in
			member.id == currentUserId && member.role == .admin
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
	func addMember(withCode code: String) async throws {
		guard isAdmin, var updatedBudget = currentBudget else {
			throw NetworkError.authenticationError
		}
		
		guard let newMember = try await FirebaseService.shared.getFamilyMember(withCode: code) else {
			throw NetworkError.serverError("Üye bulunamadı")
		}
		
		let familyMember = FamilyBudget.FamilyMember(
			id: newMember.id,
			name: newMember.name,
			role: .member,
			spentAmount: 0
		)
		
		updatedBudget.members.append(familyMember)
		try await FirebaseService.shared.updateFamilyBudget(updatedBudget)
	}
	
	// Üye çıkar
	func removeMember(withId memberId: String) async throws {
		guard isAdmin, var updatedBudget = currentBudget else {
			throw NetworkError.authenticationError
		}
		
		updatedBudget.members.removeAll { $0.id == memberId }
		try await FirebaseService.shared.updateFamilyBudget(updatedBudget)
	}
	
	// Bütçeyi sil
	func deleteBudget() async throws {
		guard isAdmin, let budget = currentBudget else {
			throw NetworkError.authenticationError
		}
		
		budgetListener?.remove()
		budgetListener = nil
		
		try await FirebaseService.shared.deleteFamilyBudget(budget)
		
		await MainActor.run {
			self.currentBudget = nil
		}
		
		setupListeners()
	}
	
	// Kategori limitlerini güncelle
	func updateCategoryLimits(_ limits: [FamilyCategoryBudget]) async throws {
		guard isAdmin, var updatedBudget = currentBudget else {
			throw NetworkError.authenticationError
		}
		
		updatedBudget.categoryLimits = limits
		try await FirebaseService.shared.updateFamilyBudget(updatedBudget)
	}
	
	func joinBudget(withCode code: String) async {
		do {
			try await FirebaseService.shared.joinFamilyBudget(withCode: code)
		} catch {
			errorMessage = error.localizedDescription
			showError = true
		}
	}
	
	// Mevcut üyeyi hesapla
	var currentMember: FamilyBudget.FamilyMember? {
		guard let budget = currentBudget else { return nil }
		return budget.members.first { $0.id == AuthManager.shared.currentUserId }
	}
	
	func leaveFamilyBudget() async {
		guard let budget = currentBudget,
			  let currentMember = currentMember else { return }
		
		do {
			try await FirebaseService.shared.removeMemberFromBudget(
					memberId: currentMember.id,
					fromBudget: budget
			)
			
			// Aile bütçesi verilerini temizle
			self.currentBudget = nil
			self.transactions = []
			
			print("✅ Successfully left family budget")
		} catch {
			print("❌ Error leaving family budget: \(error.localizedDescription)")
		}
	}
}
