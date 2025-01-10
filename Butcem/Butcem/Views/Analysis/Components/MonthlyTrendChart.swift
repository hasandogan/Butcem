import SwiftUI
import Charts

struct MonthlyTrendChart: View {
    let trends: [(month: String, amount: Double)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
			Text("Aylık Trend".localized)
                .font(.headline)
            
            Chart {
                ForEach(trends, id: \.month) { trend in
                    LineMark(
                        x: .value("Ay", trend.month),
                        y: .value("Tutar", trend.amount)
                    )
                    .symbol(by: .value("Ay", trend.month))
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks { value in
                    if let month = value.as(String.self) {
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            Text(month)
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
