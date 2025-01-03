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
                Section(header: Text("Hedef Detayları")) {
                    TextField("Hedef Başlığı", text: $title)
                    
                    HStack {
                        Text("")
                        TextField("Hedef Tutar", value: $targetAmount, format: .number)
                            .keyboardType(.decimalPad)
                    }
                    
                    HStack {
                        Text("")
                        TextField("Mevcut Birikim", value: $currentAmount, format: .number)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section(header: Text("Kategori ve Tip")) {
                    Picker("Kategori", selection: $selectedCategory) {
                        ForEach(GoalCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                    
                    Picker("Hedef Tipi", selection: $selectedType) {
                        ForEach(GoalType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }
                
                Section(header: Text("Tarih")) {
                    DatePicker(
                        "Hedef Tarihi",
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
                    Section(header: Text("Aylık Hedef")) {
                        HStack {
                            Text("Aylık Birikim Hedefi")
                            Spacer()
                            Text(monthlyTarget.currencyFormat())
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Yeni Hedef")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
                        saveGoal()
                    }
                    .disabled(!isFormValid)
                }
            }
            .alert("Hata", isPresented: $showingError) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text("Lütfen tüm alanları doldurun")
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

#Preview {
    AddGoalView(viewModel: FinancialGoalViewModel())
} 
