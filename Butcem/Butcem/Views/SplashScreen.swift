import SwiftUI

struct SplashScreen: View {
    @State private var isActive = false
    @State private var size = 0.7
    @State private var opacity = 0.0
    @State private var rotation = -30.0
    @State private var yOffset: CGFloat = 300
    @State private var isPulsing = false
    
    var body: some View {
        if isActive {
            ContentView()
        } else {
            ZStack {
                // Gradient Arka Plan
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.accentColor,
                        Color.accentColor.opacity(0.8),
                        Color.blue.opacity(0.6),
                        Color.purple.opacity(0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Animasyonlu Dalgalar
                WaveShape(yOffset: yOffset)
                    .fill(Color.white.opacity(0.1))
                    .blur(radius: 3)
                    .ignoresSafeArea()
                
                WaveShape(yOffset: yOffset - 50)
                    .fill(Color.white.opacity(0.2))
                    .blur(radius: 2)
                    .ignoresSafeArea()
                
                VStack(spacing: 25) {
                    // Logo ve İkon
                    ZStack {
                        // Pulse efekti için arka halka
                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 130, height: 130)
                            .scaleEffect(isPulsing ? 1.2 : 1.0)
                            .opacity(isPulsing ? 0.5 : 1)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 120, height: 120)
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.accentColor)
                            .rotationEffect(.degrees(rotation))
                    }
                    .scaleEffect(size)
                    
                    VStack(spacing: 15) {
                        // Başlık
						Text("Bütçem".localized)
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 2)
                        
                        // Alt Başlık
						Text("Finansal hedeflerinize ulaşmanın\nen kolay yolu".localized)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                    }
                    .opacity(opacity)
                }
                .offset(y: -50)
            }
            .onAppear {
                // Logo Animasyonları
                withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                    self.size = 1.0
                    self.rotation = 0
                }
                
                // Metin Animasyonu
                withAnimation(.easeInOut(duration: 1.0).delay(0.3)) {
                    self.opacity = 1.0
                }
                
                // Pulse Animasyonu
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    self.isPulsing = true
                }
                
                // Dalga Animasyonu
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    self.yOffset = 280
                }
                
                // Ana ekrana geçiş
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeInOut(duration: 0.7)) {
                        isActive = true
                    }
                }
            }
        }
    }
}

// Dalga Şekli
struct WaveShape: Shape {
    var yOffset: CGFloat
    
    var animatableData: CGFloat {
        get { yOffset }
        set { yOffset = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midWidth = width / 2
        
        path.move(to: CGPoint(x: 0, y: height))
        path.addCurve(
            to: CGPoint(x: midWidth, y: height - yOffset),
            control1: CGPoint(x: width * 0.25, y: height - yOffset + 50),
            control2: CGPoint(x: width * 0.25, y: height - yOffset - 50)
        )
        path.addCurve(
            to: CGPoint(x: width, y: height),
            control1: CGPoint(x: width * 0.75, y: height - yOffset - 50),
            control2: CGPoint(x: width * 0.75, y: height - yOffset + 50)
        )
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        
        return path
    }
}

#Preview {
    SplashScreen()
       
} 
