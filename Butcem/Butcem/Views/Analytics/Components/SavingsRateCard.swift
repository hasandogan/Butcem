import SwiftUI

struct SavingsRateCard: View {
    let rate: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
			Text("Tasarruf Oranı".localized)
                .font(.headline)
            
            HStack {
                Text(rate.percentFormat())
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.blue)
                
                Spacer()
                
				CircularProgressView(progress: rate / 100, color: .blue)
                    .frame(width: 60, height: 60)
            }
        }
        .padding()
        .background(Color.systemBackground)
        .cornerRadius(12)
    }
}
