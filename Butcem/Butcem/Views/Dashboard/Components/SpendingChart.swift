import SwiftUI
import Charts

struct SpendingChart: View {
	@ObservedObject var viewModel: DashboardViewModel
	
	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			Text("Harcama Dağılımı".localized)
				.font(.headline)
			
			Chart {
				ForEach(viewModel.categorySpending, id: \.category) { spending in
					SectorMark(
						angle: .value("Harcama".localized, spending.amount),
						innerRadius: .ratio(0.618),
						angularInset: 1.5
					)
					.foregroundStyle(by: .value("Kategori".localized, spending.category.localizedName))
					.annotation(position: .overlay) {
						Text("%\(Int(spending.percentage))")
							.font(.caption)
							.foregroundColor(.white)
					}
				}
			}
			.frame(height: 200)
			
			// Kategori Listesi
			VStack(spacing: 8) {
				ForEach(viewModel.categorySpending, id: \.category) { spending in
					HStack {
						Circle()
							.fill(spending.category.color)
							.frame(width: 8, height: 8)
						Text(spending.category.localizedName)
						Spacer()
						Text("%\(Int(spending.percentage))")
							.foregroundColor(.secondary)
					}
					.font(.caption)
				}
			}
		}
		.padding()
		.background(Color(.systemBackground))
		.cornerRadius(12)
		.shadow(radius: 2)
	}
}
