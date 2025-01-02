import SwiftUI

struct NetworkStatusView: View {
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    
    var body: some View {
        if !networkMonitor.isConnected {
            VStack {
                HStack {
                    Image(systemName: "wifi.slash")
                    Text("İnternet bağlantısı yok")
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.red)
                .cornerRadius(8)
            }
            .padding()
            .transition(.move(edge: .top))
        }
    }
} 
