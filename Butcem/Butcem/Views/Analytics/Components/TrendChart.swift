import SwiftUI
import Charts

struct TrendChart: View {
    let data: [(date: Date, value: Double)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
			Text("Harcama Trendi".localized)
                .font(.headline)
            
            Chart {
                ForEach(data, id: \.date) { item in
                    LineMark(
						x: .value("Tarih".localized, item.date),
						y: .value("Tutar".localized, item.value)
                    )
                    .foregroundStyle(.blue)
                    
                    AreaMark(
						x: .value("Tarih".localized, item.date),
						y: .value("Tutar".localized, item.value)
                    )
                    .foregroundStyle(.blue.opacity(0.1))
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
} 
