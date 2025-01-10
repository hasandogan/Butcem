import Foundation
import FirebaseAuth

class TestDataHelper {
    static let shared = TestDataHelper()
    
    func createTestData() {
        // Test kullanıcısı ile giriş yap
        Auth.auth().signIn(withEmail: "test@example.com", password: "123456") { result, error in
            if let error = error {
                print("Test kullanıcı girişi hatası: \(error.localizedDescription)")
                return
            }
            
            guard let user = result?.user else {
                print("Kullanıcı bilgisi alınamadı")
                return
            }
            
            print("Test kullanıcı ID: \(user.uid)")
            
            // Test verilerini oluştur
            TestDataGenerator.shared.generateTestData { error in
                if let error = error {
                    print("Test verisi oluşturma hatası: \(error.localizedDescription)")
                } else {
                    print("Test verileri başarıyla oluşturuldu")
                }
            }
        }
    }
} 