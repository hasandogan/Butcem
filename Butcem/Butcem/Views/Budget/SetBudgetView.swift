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
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Toplam Bütçe")) {
                    HStack {
                        Text("")
                        TextField("", value: $totalBudget, format: .number)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section(header: Text("Kategori Limitleri")) {
                    ForEach(Category.expenseCategories, id: \.self) { category in
                        CategoryLimitRow(
                            category: category,
                            limit: categoryLimitBinding(for: category)
                        )
                    }
                }
                
                Section("Bildirim Ayarları") {
                    Toggle("Bütçe Uyarıları", isOn: $notificationsEnabled)
                    
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
            .navigationTitle("Bütçe Belirle")
            .navigationBarItems(
                leading: Button("İptal") {
                    dismiss()
                },
                trailing: Button("Kaydet") {
                    saveBudget()
                }
            )
            .alert("Hata", isPresented: $showingError) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text("Toplam bütçe 0'dan büyük olmalıdır")
            }
        }
    }
    
    private func categoryLimitBinding(for category: Category) -> Binding<Double> {
        Binding(
            get: { self.categoryLimits[category, default: 0] },
            set: { self.categoryLimits[category] = $0 }
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
                await viewModel.updateBudget(amount: totalBudget, categoryLimits: limits)
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
    
    var body: some View {
        HStack {
            Label(category.rawValue, systemImage: category.icon)
            Spacer()
            TextField("Limit", value: $limit, format: .currency(code: "TRY"))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
        }
    }
}
