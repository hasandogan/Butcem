import SwiftUI
import Charts

struct CategorySpendingChart: View {
    let spending: [CategorySpending]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Kategori Dağılımı")
                .font(.headline)
            
            Chart {
                ForEach(spending, id: \.category) { item in
                    BarMark(
                        x: .value("Kategori", item.category.rawValue),
                        y: .value("Tutar", item.amount)
                    )
                    .foregroundStyle(by: .value("Kategori", item.category.rawValue))
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks { value in
                    if let category = value.as(String.self) {
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            Text(category)
                                .rotationEffect(Angle(degrees: -45))
                        }
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
