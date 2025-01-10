import SwiftUI
import Charts

struct IncomeExpenseChart: View {
    let data: [(date: Date, income: Double, expense: Double)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
			Text("Gelir/Gider Analizi".localized)
                .font(.headline)
            
            Chart {
                ForEach(data, id: \.date) { item in
                    BarMark(
						x: .value("Tarih".localized, item.date),
						y: .value("Gelir".localized, item.income)
                    )
                    .foregroundStyle(.green)
                    
                    BarMark(
						x: .value("Tarih".localized, item.date),
						y: .value("Gider".localized, item.expense)
                    )
                    .foregroundStyle(.red)
                }
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
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
