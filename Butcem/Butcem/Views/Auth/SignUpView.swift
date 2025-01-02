import SwiftUI
import AuthenticationServices

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var name = ""
    @State private var isLoading = false
    @State private var isSecured = true
    @State private var isConfirmSecured = true
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && !name.isEmpty &&
        password == confirmPassword && password.count >= 6
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Başlık
                    Text("Yeni Hesap Oluştur")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    // Form
                    VStack(spacing: 20) {
                        CustomTextField(
                            text: $name,
                            placeholder: "Ad Soyad",
                            systemImage: "person"
                        )
                        
                        CustomTextField(
                            text: $email,
                            placeholder: "E-posta",
                            systemImage: "envelope"
                        )
                        
                        CustomSecureField(
                            text: $password,
                            isSecured: $isSecured,
                            placeholder: "Şifre"
                        )
                        
                        CustomSecureField(
                            text: $confirmPassword,
                            isSecured: $isConfirmSecured,
                            placeholder: "Şifre Tekrar"
                        )
                        
                        if let error = authViewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        
                        // Kayıt Ol Butonu
                        Button {
                            signUp()
                        } label: {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Kayıt Ol")
                                    .frame(maxWidth: .infinity)
                                    .font(.headline)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(!isFormValid || isLoading)
                        
                        // Sosyal Medya ile Kayıt
                        VStack(spacing: 15) {
                            Text("veya")
                                .foregroundColor(.secondary)
                            
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
                            
                            Button {
                                Task {
                                    await authViewModel.signInWithGoogle()
                                }
                            } label: {
                                HStack {
                                    Image("google_logo")
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                    Text("Google ile kayıt ol")
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
                }
                .padding()
            }
            .navigationBarItems(trailing: Button("İptal") {
                dismiss()
            })
        }
    }
    
    private func signUp() {
        isLoading = true
        Task {
            do {
                try await authViewModel.signUp(email: email, password: password, name: name)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Signup error: \(error)")
            }
            await MainActor.run {
                isLoading = false
            }
        }
    }
} 