import SwiftUI

struct SetBudgetView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: BudgetViewModel
    
    @State private var totalBudget: Double
    @State private var categoryLimits: [Category: Double]
    @State private var showingError = false
    @State private var notificationsEnabled: Bool = true
    @State private var warningThreshold: Double = 70
    @State private var dangerThreshold: Double = 90
    @State private var showingLimitError = false
    @State private var limitErrorMessage = ""
    
    init(viewModel: BudgetViewModel) {
        self.viewModel = viewModel
        // Mevcut bütçe varsa değerleri al
        if let budget = viewModel.budget {
            _totalBudget = State(initialValue: budget.amount)
            _categoryLimits = State(initialValue: Dictionary(
                uniqueKeysWithValues: budget.categoryLimits.map {
                    ($0.category, $0.limit)
                }
            ))
        } else {
            _totalBudget = State(initialValue: 0)
            _categoryLimits = State(initialValue: [:])
        }
    }
    
    private var totalCategoryLimits: Double {
        categoryLimits.values.reduce(0, +)
    }
    
    private var remainingBudget: Double {
        totalBudget - totalCategoryLimits
    }
    
    var body: some View {
        NavigationView {
            Form {
				Section(header: Text("Toplam Bütçe".localized)) {
                    HStack {
                        Text("")
                        TextField("", value: $totalBudget, format: .number)
                            .keyboardType(.decimalPad)
                    }
                }
                
				Section(header: Text("Kategori Limitleri".localized),
                        footer: Text("Kalan Bütçe: \(remainingBudget.currencyFormat())")) {
                    ForEach(Category.expenseCategories, id: \.self) { category in
                        CategoryLimitRow(
								category: category,
                            limit: categoryLimitBinding(for: category),
                            maxLimit: remainingBudget + (categoryLimits[category] ?? 0)
                        )
                    }
                }
                
				Section("Bildirim Ayarları".localized) {
					Toggle("Bütçe Uyarıları".localized, isOn: $notificationsEnabled)
                    
                    if notificationsEnabled {
                        VStack(alignment: .leading) {
                            Text("Uyarı Eşiği: %\(Int(warningThreshold))")
                            Slider(value: $warningThreshold, in: 50...90, step: 5)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Kritik Eşik: %\(Int(dangerThreshold))")
                            Slider(value: $dangerThreshold, in: warningThreshold...100, step: 5)
                        }
                    }
                }
            }
			.navigationTitle("Bütçe Belirle".localized)
            .navigationBarItems(
				leading: Button("İptal".localized) {
                    dismiss()
                },
				trailing: Button("Kaydet".localized) {
                    saveBudget()
                }
            )
			.alert("Hata".localized, isPresented: $showingError) {
				Button("Tamam".localized, role: .cancel) {}
            } message: {
				Text("Toplam bütçe 0'dan büyük olmalıdır".localized)
            }
            .alert("Hata".localized, isPresented: $showingLimitError) {
                Button("Tamam".localized, role: .cancel) {}
            } message: {
                Text(limitErrorMessage)
            }
        }
    }
    
    private func categoryLimitBinding(for category: Category) -> Binding<Double> {
        Binding(
            get: { self.categoryLimits[category, default: 0] },
            set: { newValue in
                let currentLimit = self.categoryLimits[category, default: 0]
                let otherLimitsTotal = self.totalCategoryLimits - currentLimit
                
                if otherLimitsTotal + newValue > totalBudget {
                    showingLimitError = true
                    limitErrorMessage = "Kategori limitleri toplamı toplam bütçeyi aşamaz".localized
                } else {
                    self.categoryLimits[category] = newValue
                }
            }
        )
    }
    
    private func saveBudget() {
        guard totalBudget > 0 else {
            showingError = true
            return
        }
        
        // Sadece 0'dan büyük limitleri kaydet
        let limits = categoryLimits
            .filter { $0.value > 0 }
            .map { CategoryBudget(
                id: UUID().uuidString,
                category: $0.key,
                limit: $0.value,
                spent: 0
            )}
        
        Task {
            if viewModel.budget != nil {
                try await viewModel.updateBudget(amount: totalBudget, categoryLimits: limits)
            } else {
                try? await viewModel.setBudget(amount: totalBudget, categoryLimits: limits)
            }
            dismiss()
        }
    }
}

struct CategoryLimitRow: View {
    let category: Category
    @Binding var limit: Double
    let maxLimit: Double
    
    var body: some View {
        HStack {
			Label(category.localizedName, systemImage: category.icon)
            Spacer()
			TextField("Limit".localized, value: $limit, format: .currency(code: "TRY"))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .onChange(of: limit) { newValue in
                    if newValue > maxLimit {
                        limit = maxLimit
                    }
                }
        }
    }
}
