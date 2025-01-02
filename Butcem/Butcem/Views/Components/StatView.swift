import SwiftUI

struct StatView: View {
    let title: String
    let amount: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(amount.currencyFormat())
                .font(.headline)
                .foregroundColor(color)
        }
    }
} 