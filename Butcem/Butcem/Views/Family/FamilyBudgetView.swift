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
	@State private var showingLeaveAlert = false
	
	var body: some View {
		Group {
			if let budget = viewModel.currentBudget {
				ScrollView {
					VStack(spacing: 20) {
						// Bütçe Özeti Kartı
						FamilyBudgetSummaryCard(budget: budget)
							.shadow(radius: 5)
						
						if viewModel.isAdmin {
							// Paylaşım Kodu Kartı
							SharingCodeCard(code: budget.sharingCode)
								.shadow(radius: 5)
						}
						
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
								Label("Bütçeyi Sil".localized, systemImage: "trash")
									.foregroundColor(.red)
									.frame(maxWidth: .infinity)
									.padding()
									.background(Color.red.opacity(0.1))
									.cornerRadius(12)
							}
							.padding(.horizontal)
						}
						
						// Admin değilse ayrılma butonu göster
						if let currentMember = viewModel.currentMember,
						   currentMember.role != .admin {
							Button(role: .destructive) {
								showingLeaveAlert = true
							} label: {
								HStack {
									Image(systemName: "person.fill.xmark")
									Text("Aile Bütçesinden Ayrıl")
								}
								.foregroundColor(.red)
								.frame(maxWidth: .infinity)
								.padding()
								.background(Color(.systemBackground))
								.cornerRadius(10)
								.shadow(radius: 2)
							}
							.padding(.horizontal)
						}
					}
					.padding()
				}
				.navigationTitle(budget.name)
				.background(Color(.systemGroupedBackground))
				.alert("Bütçeyi Sil".localized, isPresented: $showingDeleteAlert) {
					Button("İptal".localized, role: .cancel) { }
					Button("Sil".localized, role: .destructive) {
						Task {
							try? await viewModel.deleteBudget()
						}
					}
				} message: {
					Text("Bu bütçeyi silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.".localized)
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
			AddMemberView(viewModel: viewModel)
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
		.alert("Aile Bütçesinden Ayrıl", isPresented: $showingLeaveAlert) {
			Button("İptal", role: .cancel) { }
			Button("Ayrıl", role: .destructive) {
				Task {
					await viewModel.leaveFamilyBudget()
				}
			}
		} message: {
			Text("Aile bütçesinden ayrılmak istediğinize emin misiniz? Bu işlem geri alınamaz.")
		}
	}
	
	// MARK: - Alt Bileşenler
	struct FamilyBudgetSummaryCard: View {
		let budget: FamilyBudget
		
		var body: some View {
			VStack(spacing: 16) {
				// Başlık
				HStack {
					Text("Toplam Bütçe".localized)
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
						Text("Harcanan".localized)
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
					title: "Harcama Ekle".localized,
					icon: "plus.circle.fill",
					color: .blue,
					action: onAddTransaction
				)
				
				// Admin butonları
				if isAdmin {
					FamilyQuickActionButton(
						title: "Üyeler".localized,
						icon: "person.3.fill",
						color: .green,
						action: onAddMember
					)
					
					FamilyQuickActionButton(
						title: "Düzenle".localized,
						icon: "pencil.circle.fill",
						color: .orange,
						action: onEdit
					)
					
					FamilyQuickActionButton(
						title: "Limitler".localized,
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
	@StateObject private var viewModel = FamilyBudgetViewModel()
	@State private var sharingCode = ""
	@State private var isJoining = false
	@State private var showingError = false
	
	var body: some View {
		VStack(spacing: 24) {
			Image(systemName: "person.3.fill")
				.font(.system(size: 60))
				.foregroundColor(.accentColor)
			
			Text("Aile Bütçesine Hoş Geldiniz")
				.font(.title2)
				.fontWeight(.bold)
			
			Text("Yeni bir aile bütçesi oluşturun veya mevcut bir bütçeye katılın")
				.multilineTextAlignment(.center)
				.foregroundColor(.secondary)
				.padding(.horizontal)
			
			VStack(spacing: 16) {
				// Yeni Bütçe Oluştur
				Button {
					showingCreateBudget = true
				} label: {
					HStack {
						Image(systemName: "plus.circle.fill")
						Text("Yeni Bütçe Oluştur")
					}
					.frame(maxWidth: .infinity)
					.padding()
					.background(Color.accentColor)
					.foregroundColor(.white)
					.cornerRadius(12)
				}
				
				Text("veya")
					.foregroundColor(.secondary)
					.padding(.vertical, 8)
				
				// Bütçeye Katıl
				VStack(spacing: 12) {
					TextField("Paylaşım Kodunu Girin", text: $sharingCode)
						.textFieldStyle(RoundedBorderTextFieldStyle())
						.autocapitalization(.none)
						.padding(.horizontal)
					
					Button {
						isJoining = true
						Task {
							await viewModel.joinBudget(withCode: sharingCode)
							isJoining = false
						}
					} label: {
						HStack {
							if isJoining {
								ProgressView()
									.progressViewStyle(CircularProgressViewStyle(tint: .white))
									.padding(.trailing, 8)
							}
							Text("Bütçeye Katıl")
						}
						.frame(maxWidth: .infinity)
						.padding()
						.background(Color.green)
						.foregroundColor(.white)
						.cornerRadius(12)
					}
					.disabled(sharingCode.isEmpty || isJoining)
				}
				.padding()
				.background(Color(.systemBackground))
				.cornerRadius(16)
				.shadow(radius: 2)
			}
			.padding(.horizontal)
		}
		.padding()
		.background(Color(.systemGroupedBackground))
		.alert("Hata", isPresented: $viewModel.showError) {
			Button("Tamam", role: .cancel) { }
		} message: {
			Text(viewModel.errorMessage ?? "Bilinmeyen bir hata oluştu")
		}
	}
	
	// Preview için
	struct WelcomeView_Previews: PreviewProvider {
		static var previews: some View {
			WelcomeView(showingCreateBudget: .constant(false))
		}
	}
}

// Paylaşım Kodu Kartı
struct SharingCodeCard: View {
	let code: String
	@State private var showingCopiedAlert = false
	
	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			Text("Paylaşım Kodu")
				.font(.headline)
			
			Text("Bu kodu aile üyeleriyle paylaşarak bütçeye katılmalarını sağlayabilirsiniz")
				.font(.caption)
				.foregroundColor(.secondary)
			
			HStack {
				Text(code)
					.font(.title2)
					.bold()
					.foregroundColor(.blue)
				
				Spacer()
				
				Button {
					UIPasteboard.general.string = code
					showingCopiedAlert = true
				} label: {
					HStack {
						Image(systemName: "doc.on.doc")
						Text("Kopyala")
					}
					.padding(.horizontal, 12)
					.padding(.vertical, 8)
					.background(Color.blue.opacity(0.1))
					.cornerRadius(8)
				}
			}
			.padding()
			.background(Color.secondary.opacity(0.1))
			.cornerRadius(12)
		}
		.padding()
		.background(Color(.systemBackground))
		.cornerRadius(16)
		.overlay(
			RoundedRectangle(cornerRadius: 16)
				.stroke(Color.blue.opacity(0.2), lineWidth: 1)
		)
		.alert("Kopyalandı", isPresented: $showingCopiedAlert) {
			Button("Tamam", role: .cancel) { }
		} message: {
			Text("Paylaşım kodu panoya kopyalandı")
		}
	}
}
