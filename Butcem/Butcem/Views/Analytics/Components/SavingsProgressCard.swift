import SwiftUI


struct SavingsProgressCard: View {
    let progress: [SavingsProgress]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tasarruf İlerlemesi")
                .font(.headline)
            
            if progress.isEmpty {
                Text("Henüz veri bulunmuyor")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ForEach(progress) { item in
                    VStack(spacing: 8) {
                        HStack {
                            Text(item.currentAmount.currencyFormat())
                            Spacer()
                            Text("\(Int(item.percentage))%")
                        }
                        
                        ProgressView(value: item.percentage, total: 100)
                            .tint(.green)
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
