import SwiftUI
import Charts

struct IncomeExpenseChart: View {
    let data: [(date: Date, income: Double, expense: Double)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Gelir/Gider Analizi")
                .font(.headline)
            
            Chart {
                ForEach(data, id: \.date) { item in
                    BarMark(
                        x: .value("Tarih", item.date),
                        y: .value("Gelir", item.income)
                    )
                    .foregroundStyle(.green)
                    
                    BarMark(
                        x: .value("Tarih", item.date),
                        y: .value("Gider", item.expense)
                    )
                    .foregroundStyle(.red)
                }
            }
            .frame(height: 200)
            
            // Açıklama
            HStack {
                Label("Gelir", systemImage: "circle.fill")
                    .foregroundColor(.green)
                Spacer()
                Label("Gider", systemImage: "circle.fill")
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
