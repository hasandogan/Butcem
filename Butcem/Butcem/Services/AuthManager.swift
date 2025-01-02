import FirebaseAuth
import SwiftUI

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published private(set) var user: User?
    @Published private(set) var isAuthenticated = false
    @Published var errorMessage: String?
    
    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
    private init() {
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.user = user
                self?.isAuthenticated = user != nil
            }
			
        }
    }
    
    func signIn(email: String, password: String) async throws {
        do {
            user = try await FirebaseService.shared.signIn(email: email, password: password)
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func signUp(email: String, password: String, name: String) async throws {
        do {
            user = try await FirebaseService.shared.signUp(email: email, password: password, name: name)
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func signOut() {
        do {
            try FirebaseService.shared.signOut()
            user = nil
            isAuthenticated = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
} 
