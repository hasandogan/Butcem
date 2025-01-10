import SwiftUI

struct CategoryPieChart: View {
    let data: [(category: Category, amount: Double, percentage: Double)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
			Text("Kategori Dağılımı".localized)
                .font(.headline)
            
            // Kategori listesi
            ForEach(data, id: \.category) { item in
                HStack {
					Label(item.category.localizedName, systemImage: item.category.icon)
                    Spacer()
                    Text(item.amount.currencyFormat())
                    Text("(\(Int(item.percentage))%)")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
} 
