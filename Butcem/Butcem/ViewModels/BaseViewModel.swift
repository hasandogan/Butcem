import Foundation
import FirebaseFirestore
import Combine

@MainActor
class BaseViewModel: ObservableObject {
    private var isProcessing = false
    private let listenerManager = ListenerManager()
    
    init() {}
    
    func withProcessing<T>(_ operation: () async throws -> T) async throws -> T {
        guard !isProcessing else {
            throw ViewModelError.operationInProgress
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        return try await operation()
    }
}

enum ViewModelError: LocalizedError {
    case operationInProgress
    
    var errorDescription: String? {
        switch self {
        case .operationInProgress:
            return "İşlem devam ediyor, lütfen bekleyin"
        }
    }
} 