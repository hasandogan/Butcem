import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showingSignUp = false
    @State private var isSecured = true
    
    #if DEBUG
    @State private var showingTestDataAlert = false
    #endif
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Logo ve Başlık
                    VStack(spacing: 15) {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor)
                        
                        Text("Bütçem")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Finansal hedeflerinize ulaşmanın en kolay yolu")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 50)
                    
                    // Giriş Formu
                    VStack(spacing: 20) {
                        // Email
                        CustomTextField(
                            text: $email,
                            placeholder: "E-posta",
                            systemImage: "envelope"
                        )
                        
                        // Şifre
                        CustomSecureField(
                            text: $password,
                            isSecured: $isSecured,
                            placeholder: "Şifre"
                        )
                        
                        // Hata Mesajı
                        if let error = authViewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        
                        // Giriş Butonu
                        Button {
                            authViewModel.signIn(email: email, password: password)
                        } label: {
                            Text("Giriş Yap")
                                .frame(maxWidth: .infinity)
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        
                        // Sosyal Medya Girişleri
                        VStack(spacing: 15) {
                            Text("veya")
                                .foregroundColor(.secondary)
                            
                            // Apple ile Giriş
                            SignInWithAppleButton { request in
                                let nonce = FirebaseService.shared.startSignInWithAppleFlow()
                                request.requestedScopes = [.email, .fullName]
                                request.nonce = FirebaseService.shared.sha256(nonce)
                            } onCompletion: { result in
                                Task {
                                    await authViewModel.handleSignInWithApple(result)
                                }
                            }
                            .frame(height: 50)
                            .cornerRadius(8)
                            
                            // Google ile Giriş
                            Button {
                                Task {
                                    await authViewModel.signInWithGoogle()
                                }
                            } label: {
                                HStack {
                                    Image("google_logo") // Google logosunu assets'e eklemeyi unutmayın
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                    Text("Google ile devam et")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Kayıt Ol Butonu
                    Button {
                        showingSignUp.toggle()
                    } label: {
                        Text("Hesabınız yok mu? Kayıt olun")
                            .foregroundColor(.accentColor)
                    }
                    
                    #if DEBUG
                    Button("Test Verisi Oluştur") {
                        showingTestDataAlert = true
                    }
                    .padding()
                    .alert("Test Verisi", isPresented: $showingTestDataAlert) {
                        Button("İptal", role: .cancel) {}
                        Button("Oluştur") {
                            Task {
                                do {
                                    try await TestDataGenerator.shared.generateTestData()
                                    email = TestDataGenerator.shared.testUser.email
                                    password = TestDataGenerator.shared.testUser.password
                                } catch {
                                    print("Test verisi oluşturma hatası: \(error.localizedDescription)")
                                }
                            }
                        }
                    } message: {
                        Text("Test verileri oluşturulacak. Bu işlem biraz zaman alabilir.")
                    }
                    #endif
                }
                .padding()
            }
            .sheet(isPresented: $showingSignUp) {
                SignUpView()
            }
        }
    }
}

// Custom TextField
struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    let systemImage: String
    
    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(.gray)
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// Custom SecureField
struct CustomSecureField: View {
    @Binding var text: String
    @Binding var isSecured: Bool
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "lock")
                .foregroundColor(.gray)
            
            if isSecured {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
            
            Button {
                isSecured.toggle()
            } label: {
                Image(systemName: isSecured ? "eye.slash" : "eye")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
} 
