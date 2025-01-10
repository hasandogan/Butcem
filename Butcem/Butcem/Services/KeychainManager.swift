import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()
    private let userIdKey = "com.app.userId"
    
    private init() {}
    
    func getUserId() -> String {
        if let existingId = retrieveUserId() {
            return existingId
        }
        
        // Yeni UUID oluştur ve kaydet
        let newId = UUID().uuidString
        try? saveUserId(newId)
        return newId
    }
    
    private func saveUserId(_ userId: String) throws {
        let data = userId.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: userIdKey,
            kSecValueData as String: data
        ]
        
        // Önce varolan kaydı sil
        SecItemDelete(query as CFDictionary)
        
        // Yeni kaydı ekle
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed
        }
    }
    
    private func retrieveUserId() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: userIdKey,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess,
           let data = dataTypeRef as? Data,
           let userId = String(data: data, encoding: .utf8) {
            return userId
        }
        
        return nil
    }
    
    enum KeychainError: Error {
        case saveFailed
        case retrieveFailed
    }
} 