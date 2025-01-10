import SwiftUI
import Charts

struct TrendsTab: View {
    let monthlyData: [MonthlyComparison]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
				Text("Aylık Karşılaştırma".localized)
                    .font(.headline)
                
                if monthlyData.isEmpty {
					Text("Veri bulunamadı".localized)
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    // Grafik
                    Chart {
                        ForEach(monthlyData) { data in
                            BarMark(
								x: .value("Ay".localized, data.month.monthString()),
								y: .value("Gelir".localized, data.income),
                                width: .fixed(20)
                            )
                            .foregroundStyle(.green)
							.position(by: .value("Tür".localized, "Gelir".localized))
                            
                            BarMark(
								x: .value("Ay".localized, data.month.monthString()),
								y: .value("Gider".localized, data.expense),
                                width: .fixed(20)
                            )
                            .foregroundStyle(.red)
							.position(by: .value("Tür".localized, "Gider".localized))
                        }
                    }
                    .frame(height: 200)
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            if let amount = value.as(Double.self) {
                                AxisValueLabel {
                                    Text(amount.currencyFormat())
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            if let month = value.as(String.self) {
                                AxisValueLabel {
                                    Text(month)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    
                    // Grafik Açıklaması
                    HStack(spacing: 20) {
                        HStack {
                            Circle()
                                .fill(.green)
                                .frame(width: 8, height: 8)
							Text("Gelir".localized)
                                .font(.caption)
                        }
                        
                        HStack {
                            Circle()
                                .fill(.red)
                                .frame(width: 8, height: 8)
							Text("Gider".localized)
                                .font(.caption)
                        }
                    }
                    .padding(.top)
                    
                    // Özet Tablo
                    VStack(spacing: 12) {
                        ForEach(monthlyData.reversed()) { data in
                            HStack {
                                Text(data.month.monthYearString())
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Gelir: \(data.income.currencyFormat())")
                                        .foregroundColor(.green)
                                    Text("Gider: \(data.expense.currencyFormat())")
                                        .foregroundColor(.red)
                                    Text("Net: \(data.savings.currencyFormat())")
                                        .foregroundColor(data.savings >= 0 ? .green : .red)
                                }
                                .font(.caption)
                            }
                            .padding(.horizontal)
                            
                            if data.id != monthlyData.first?.id {
                                Divider()
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
    }
}

struct MonthlyComparisonRow: View {
    let data: MonthlyComparison
    
    var body: some View {
        VStack(spacing: 12) {
            Text(data.month.monthYearString())
                .font(.headline)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
					Text("Gelir".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(data.income.currencyFormat())
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading) {
					Text("Gider".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(data.expense.currencyFormat())
                        .foregroundColor(.red)
                }
                
                VStack(alignment: .leading) {
					Text("Tasarruf".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(data.savings.currencyFormat())
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color.systemBackground)
        .cornerRadius(12)
    }
}

#Preview {
    TrendsTab(monthlyData: [
        MonthlyComparison(id: UUID(), month: Date(), income: 5000, expense: 3000, savings: 2000),
        MonthlyComparison(id: UUID(), month: Date().addingTimeInterval(-2592000), income: 4500, expense: 3500, savings: 1000)
    ])
}
