import SwiftUI
import AuthenticationServices
import FirebaseAuth

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    
    init() {
        // Mevcut oturum durumunu kontrol et
        self.user = Auth.auth().currentUser
        self.isAuthenticated = user != nil
    }
    
    func signIn(email: String, password: String) {
        Task {
            do {
                self.user = try await FirebaseService.shared.signIn(email: email, password: password)
                await MainActor.run {
                    self.isAuthenticated = true
                    self.errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func signOut() {
        do {
            try FirebaseService.shared.signOut()
            self.user = nil
            self.isAuthenticated = false
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func signUp(email: String, password: String, name: String) async throws {
        do {
            self.user = try await FirebaseService.shared.signUp(email: email, password: password, name: name)
            await MainActor.run {
                self.isAuthenticated = true
                self.errorMessage = nil
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    func signInWithGoogle() async {
        do {
            self.user = try await FirebaseService.shared.signInWithGoogle()
            await MainActor.run {
                self.isAuthenticated = true
                self.errorMessage = nil
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func handleSignInWithApple(_ result: Swift.Result<ASAuthorization, Error>) async {
        do {
            self.user = try await FirebaseService.shared.handleSignInWithApple(result)
            await MainActor.run {
                self.isAuthenticated = true
                self.errorMessage = nil
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
} 
