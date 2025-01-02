import SwiftUI

struct CategorySpendingRow: View {
    let category: Category
    let spent: Double
    let limit: Double
    
    private var progress: Double {
        guard limit > 0 else { return 0 }
        return min(spent / limit, 1.0)
    }
    
    private var progressColor: Color {
        switch progress {
        case 0..<0.5: return .green
        case 0.5..<0.75: return .yellow
        case 0.75..<0.9: return .orange
        default: return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Label(category.rawValue, systemImage: category.icon)
                    .font(.headline)
                
                Spacer()
                
                Text("\(spent.currencyFormat()) / \(limit.currencyFormat())")
                    .font(.subheadline)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(progressColor)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("Kalan: \((limit - spent).currencyFormat())")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("%\(Int(progress * 100))")
                    .font(.caption)
                    .foregroundColor(progressColor)
            }
        }
        .padding(.vertical, 4)
    }
}
