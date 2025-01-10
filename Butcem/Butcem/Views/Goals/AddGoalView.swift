import SwiftUI

struct AddGoalView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: FinancialGoalViewModel
    
    @State private var title = ""
    @State private var targetAmount: Double = 0
	@State private var currentAmount: Double = 0
    @State private var selectedCategory: GoalCategory = .savings
    @State private var selectedType: GoalType = .shortTerm
    @State private var deadline = Date()
    @State private var notes = ""
    @State private var showingError = false
    
    private var isFormValid: Bool {
        !title.isEmpty && targetAmount > 0 && deadline > Date()
    }
    
    var body: some View {
        NavigationView {
            Form {
				Section(header: Text("Hedef Detayları".localized)) {
					TextField("Hedef Başlığı".localized, text: $title)
                    
					HStack {
						TextField("Hedef Tutar".localized, text: Binding(
							get: { targetAmount == 0 ? "" : String(targetAmount) },
							set: { targetAmount = Double($0) ?? 0 }
						))
						.keyboardType(.decimalPad)
					}

					HStack {
						TextField("Mevcut Birikim".localized, text: Binding(
							get: { currentAmount == 0 ? "" : String(currentAmount) },
							set: { currentAmount = Double($0) ?? 0 }
						))
						.keyboardType(.decimalPad)
					}
                }
                
				Section(header: Text("Kategori ve Tip".localized)) {
                    Picker("Kategori", selection: $selectedCategory) {
                        ForEach(GoalCategory.allCases, id: \.self) { category in
							Label(category.localizedName, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                    
					Picker("Hedef Tipi".localized, selection: $selectedType) {
                        ForEach(GoalType.allCases, id: \.self) { type in
                            Text(type.localizedName).tag(type)
                        }
                    }
                }
                
				Section(header: Text("Tarih".localized)) {
                    DatePicker(
						"Hedef Tarihi".localized,
                        selection: $deadline,
                        in: Date()...,
                        displayedComponents: .date
                    )
                }
                
                Section(header: Text("Notlar")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
                
                if let monthlyTarget = calculateMonthlyTarget() {
					Section(header: Text("Aylık Hedef".localized)) {
                        HStack {
							Text("Aylık Birikim Hedefi".localized)
                            Spacer()
                            Text(monthlyTarget.currencyFormat())
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
			.navigationTitle("Yeni Hedef".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
					Button("İptal".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
					Button("Kaydet".localized) {
                        saveGoal()
                    }
                    .disabled(!isFormValid)
                }
            }
			.alert("Hata".localized, isPresented: $showingError) {
				Button("Tamam".localized, role: .cancel) {}
            } message: {
				Text("Lütfen tüm alanları doldurun".localized)
            }
        }
    }
    
    private func calculateMonthlyTarget() -> Double? {
        guard targetAmount > currentAmount else { return nil }
        
        let remainingAmount = targetAmount - currentAmount
        let months = Calendar.current.dateComponents([.month], from: Date(), to: deadline).month ?? 1
        
        return remainingAmount / Double(max(months, 1))
    }
    
    private func saveGoal() {
        guard isFormValid else {
            showingError = true
            return
        }
        
        let goal = FinancialGoal(
            userId: AuthManager.shared.currentUserId ?? "",
            title: title,
            targetAmount: targetAmount,
            currentAmount: currentAmount,
            deadline: deadline,
            type: selectedType,
            category: selectedCategory,
            createdAt: Date(),
            notes: notes.isEmpty ? nil : notes
        )
        
        Task {
            await viewModel.addGoal(goal)
            dismiss()
        }
    }
}
