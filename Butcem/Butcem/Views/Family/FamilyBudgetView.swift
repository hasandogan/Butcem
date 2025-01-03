import SwiftUI

struct FamilyBudgetView: View {
	@StateObject private var viewModel = FamilyBudgetViewModel()
	@State private var showingEditSheet = false
	@State private var showingDeleteAlert = false
	@State private var showingAddMemberSheet = false
	@State private var showingCreateBudget = false
	@State private var newMemberEmail = ""
	@State private var editingName = ""
	@State private var editingBudget = ""
	@State private var showingAddTransaction = false
	@State private var showingCategoryLimits = false
	
	var body: some View {
		Group {
			if let budget = viewModel.currentBudget {
				ScrollView {
					VStack(spacing: 20) {
						// Bütçe Özeti Kartı
						FamilyBudgetSummaryCard(budget: budget)
							.shadow(radius: 5)
						
						// Hızlı İşlemler - Tüm üyeler için göster
						FamilyQuickActionsView(
							onAddTransaction: { showingAddTransaction = true },
							onAddMember: { showingAddMemberSheet = true },
							onEdit: {
								editingName = budget.name
								editingBudget = String(budget.totalBudget)
								showingEditSheet = true
							},
							onShowLimits: { showingCategoryLimits = true },
							isAdmin: viewModel.isAdmin // Admin yetkisini geçir
						)
						
						// Kategori Harcamaları
						FamilyCategorySpendingCard(limits: budget.categoryLimits)
							.shadow(radius: 5)
						
						// İşlemler kartı
						FamilyTransactionsCard(
							budget: budget,
							transactions: viewModel.transactions
						)
						.shadow(radius: 5)
						
						// Silme butonu sadece admin için
						if viewModel.isAdmin {
							Button(role: .destructive) {
								showingDeleteAlert = true
							} label: {
								Label("Bütçeyi Sil", systemImage: "trash")
									.foregroundColor(.red)
									.frame(maxWidth: .infinity)
									.padding()
									.background(Color.red.opacity(0.1))
									.cornerRadius(12)
							}
							.padding(.horizontal)
						}
					}
					.padding()
				}
				.navigationTitle(budget.name)
				.background(Color(.systemGroupedBackground))
				.alert("Bütçeyi Sil", isPresented: $showingDeleteAlert) {
					Button("İptal", role: .cancel) { }
					Button("Sil", role: .destructive) {
						Task {
							try? await viewModel.deleteBudget()
						}
					}
				} message: {
					Text("Bu bütçeyi silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.")
				}
			} else {
				WelcomeView(showingCreateBudget: $showingCreateBudget)
			}
		}
		.sheet(isPresented: $showingCreateBudget) {
			CreateFamilyBudgetView()
		}
		.sheet(isPresented: $showingAddTransaction) {
			if let budget = viewModel.currentBudget {
				AddFamilyTransactionView(budget: budget)
			}
		}
		.sheet(isPresented: $showingAddMemberSheet) {
			AddMemberView(
				email: $newMemberEmail,
				viewModel: viewModel
			) { email in
				Task {
					do {
						try await viewModel.addMember(email)
					} catch {
						print("Failed to add member: \(error.localizedDescription)")
					}
				}
			}
		}
		.sheet(isPresented: $showingEditSheet) {
			EditBudgetView(name: $editingName, budget: $editingBudget) { name, amount in
				Task {
					if let amount = Double(amount) {
						try await viewModel.updateBudget(name: name, totalBudget: amount)
					}
				}
			}
		}
		.sheet(isPresented: $showingCategoryLimits) {
			if let budget = viewModel.currentBudget {
				SetFamilyCategoryLimitsView(viewModel: viewModel, budget: budget)
			}
		}
	}
	
	// MARK: - Alt Bileşenler
	struct FamilyBudgetSummaryCard: View {
		let budget: FamilyBudget
		
		var body: some View {
			VStack(spacing: 16) {
				// Başlık
				HStack {
					Text("Toplam Bütçe")
						.font(.headline)
					Spacer()
					Text(budget.totalBudget.currencyFormat())
						.font(.title2)
						.bold()
				}
				
				// İlerleme çubuğu
				ProgressView(value: budget.spentAmount, total: budget.totalBudget)
					.tint(budget.spentAmount > budget.totalBudget ? .red : .blue)
				
				// Alt bilgiler
				HStack {
					VStack(alignment: .leading) {
						Text("Harcanan")
							.font(.caption)
							.foregroundColor(.secondary)
						Text(budget.spentAmount.currencyFormat())
							.bold()
					}
					
					Spacer()
					
					VStack(alignment: .trailing) {
						Text("Kalan")
							.font(.caption)
							.foregroundColor(.secondary)
						Text((budget.totalBudget - budget.spentAmount).currencyFormat())
							.bold()
							.foregroundColor(budget.spentAmount > budget.totalBudget ? .red : .green)
					}
				}
			}
			.padding()
			.background(Color(.systemBackground))
			.cornerRadius(12)
		}
	}
	
	struct FamilyQuickActionsView: View {
		let onAddTransaction: () -> Void
		let onAddMember: () -> Void
		let onEdit: () -> Void
		let onShowLimits: () -> Void
		let isAdmin: Bool // Admin yetkisini al
		
		var body: some View {
			HStack(spacing: 12) {
				// Harcama Ekle butonu herkes için görünür
				FamilyQuickActionButton(
					title: "Harcama Ekle",
					icon: "plus.circle.fill",
					color: .blue,
					action: onAddTransaction
				)
				
				// Admin butonları
				if isAdmin {
					FamilyQuickActionButton(
						title: "Üyeler",
						icon: "person.3.fill",
						color: .green,
						action: onAddMember
					)
					
					FamilyQuickActionButton(
						title: "Düzenle",
						icon: "pencil.circle.fill",
						color: .orange,
						action: onEdit
					)
					
					FamilyQuickActionButton(
						title: "Limitler",
						icon: "chart.pie.fill",
						color: .purple,
						action: onShowLimits
					)
				}
			}
			.padding(.horizontal)
		}
	}
}
	struct FamilyQuickActionButton: View {
		let title: String
		let icon: String
		let color: Color
		let action: () -> Void
		
		var body: some View {
			Button(action: action) {
				VStack {
					Image(systemName: icon)
						.font(.title2)
					Text(title)
						.font(.caption)
				}
				.frame(maxWidth: .infinity)
				.padding(.vertical, 12)
				.background(color.opacity(0.1))
				.foregroundColor(color)
				.cornerRadius(12)
			}
		}
	}

struct WelcomeView: View {
	@Binding var showingCreateBudget: Bool
	
	var body: some View {
		VStack(spacing: 24) {
			Image(systemName: "person.3.fill")
				.font(.system(size: 60))
				.foregroundColor(.accentColor)
			
			Text("Aile Bütçesi Oluşturun")
				.font(.title2)
				.fontWeight(.bold)
			
			Text("Ailenizle birlikte harcamalarınızı takip edin ve yönetin")
				.multilineTextAlignment(.center)
				.foregroundColor(.secondary)
				.padding(.horizontal)
			
			Button {
				showingCreateBudget = true
			} label: {
				Text("Bütçe Oluştur")
					.font(.headline)
					.frame(maxWidth: .infinity)
					.padding()
					.background(Color.accentColor)
					.foregroundColor(.white)
					.cornerRadius(12)
			}
			.padding(.horizontal, 40)
			.padding(.top)
		}
		.padding()
	}
}
