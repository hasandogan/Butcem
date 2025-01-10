import SwiftUI
import Charts


struct MonthlyComparisonCard: View {
    let comparisons: [MonthlyComparison]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
			Text("Aylık Karşılaştırma".localized)
                .font(.headline)
            
            if comparisons.isEmpty {
				Text("Henüz veri bulunmuyor".localized)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                Chart(comparisons) { comparison in
                    BarMark(
						x: .value("Ay".localized, comparison.month, unit: .month),
						y: .value("Tutar".localized, comparison.expense)
                    )
                    .foregroundStyle(.red)
                    
                    BarMark(
						x: .value("Ay".localized, comparison.month, unit: .month),
						y: .value("Tutar".localized, comparison.income)
                    )
                    .foregroundStyle(.green)
                }
                .frame(height: 200)
                
                // Açıklama
                HStack {
					Label("Gelir".localized, systemImage: "circle.fill")
                        .foregroundColor(.green)
                    
                    Spacer()
                    
					Label("Gider".localized, systemImage: "circle.fill")
                        .foregroundColor(.red)
                }
                .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
} 
