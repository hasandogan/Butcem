import SwiftUI

struct CategoryAnalyticsCard: View {
    let analytics: [CategoryAnalytics]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Kategori Bazlı Harcamalar")
                .font(.headline)
            
            if analytics.isEmpty {
                Text("Henüz harcama bulunmuyor")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ForEach(analytics) { analytic in
                    VStack(spacing: 8) {
                        HStack {
                            Label(analytic.category.rawValue, systemImage: analytic.category.icon)
                            Spacer()
                            Text(analytic.amount.currencyFormat())
                        }
                        
                        ProgressView(value: analytic.percentage, total: 100)
                            .tint(.blue)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
} 
