import Foundation

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    @Published var userId: String
    @Published var userName: String
    
    private let userNameKey = "com.app.userName"
    
    private init() {
        // Geçici bir userId oluştur
        let tempUserId = KeychainManager.shared.getUserId()
        self.userId = tempUserId
        
        // Geçici userId ile userName'i ayarla
        let defaultName = "Kullanıcı-\(String(tempUserId.prefix(4)))"
        if let savedName = UserDefaults.standard.string(forKey: userNameKey) {
            self.userName = savedName
        } else {
            UserDefaults.standard.set(defaultName, forKey: userNameKey)
            self.userName = defaultName
        }
    }
    
    var currentUserId: String {
        return userId
    }
    
    var currentUserName: String {
        return userName
    }
    
    func updateUserName(_ name: String) {
        userName = name
        UserDefaults.standard.set(name, forKey: userNameKey)
    }
    
    // Aile bütçesi için paylaşım kodu oluştur
    func generateSharingCode() -> String {
        return String(userId.prefix(8))
    }
} 
