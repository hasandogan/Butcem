import SwiftUI

struct SetFamilyCategoryLimitsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: FamilyBudgetViewModel
    let budget: FamilyBudget
    
    @State private var categoryLimits: [FamilyBudgetCategory: Double] = [:]
    @State private var showingError = false
    
    init(viewModel: FamilyBudgetViewModel, budget: FamilyBudget) {
        self.viewModel = viewModel
        self.budget = budget
        // Mevcut limitleri state'e aktar
        _categoryLimits = State(initialValue: Dictionary(
            uniqueKeysWithValues: budget.categoryLimits.map {
                ($0.category, $0.limit)
            }
        ))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Toplam Bütçe: \(budget.totalBudget.currencyFormat())")) {
                    Text("Kalan Dağıtılabilir: \(remainingBudget.currencyFormat())")
                        .foregroundColor(remainingBudget < 0 ? .red : .secondary)
                }
                
                Section(header: Text("Kategori Limitleri")) {
                    ForEach(FamilyBudgetCategory.allCases, id: \.self) { category in
                        FamilyCategoryLimitRow(
                            category: category,
                            limit: limitBinding(for: category),
                            maxLimit: budget.totalBudget
                        )
                    }
                }
            }
            .navigationTitle("Kategori Limitleri")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
                        saveLimits()
                    }
                    .disabled(remainingBudget < 0)
                }
            }
            .alert("Hata", isPresented: $showingError) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text("Kategori limitleri toplamı bütçeyi aşamaz")
            }
        }
    }
    
    private var remainingBudget: Double {
        budget.totalBudget - categoryLimits.values.reduce(0, +)
    }
    
    private func limitBinding(for category: FamilyBudgetCategory) -> Binding<Double> {
        Binding(
            get: { self.categoryLimits[category, default: 0] },
            set: { newValue in
                // Yeni değer bütçeyi aşmıyorsa güncelle
                if (self.categoryLimits.values.reduce(0, +) - (self.categoryLimits[category] ?? 0) + newValue) <= budget.totalBudget {
                    self.categoryLimits[category] = newValue
                }
            }
        )
    }
    
    private func saveLimits() {
        guard remainingBudget >= 0 else {
            showingError = true
            return
        }
        
        let limits = categoryLimits
            .filter { $0.value > 0 }
            .map { category, limit in 
                FamilyCategoryBudget(
                    id: UUID().uuidString,
                    category: category,
                    limit: limit,
                    spent: budget.categoryLimits.first { $0.category == category }?.spent ?? 0
                )
            }
        
        Task {
            try? await viewModel.updateCategoryLimits(limits)
            dismiss()
        }
    }
}

struct FamilyCategoryLimitRow: View {
    let category: FamilyBudgetCategory
    @Binding var limit: Double
    let maxLimit: Double
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Label(category.rawValue, systemImage: category.icon)
                Spacer()
                TextField("Limit", value: $limit, format: .currency(code: "TRY"))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }
            
            // Slider ile limit ayarlama
            Slider(
                value: $limit,
                in: 0...maxLimit,
                step: 100
            )
        }
        .padding(.vertical, 4)
    }
} 
