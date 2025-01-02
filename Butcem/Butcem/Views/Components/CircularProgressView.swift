import SwiftUI

struct CircularProgressView: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    color.opacity(0.2),
                    lineWidth: 8
                )
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: 8,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
} 
