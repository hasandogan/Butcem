import Foundation

enum Result<Success, Failure: Error> {
    case success(Success)
    case failure(Failure)
    
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    var isFailure: Bool {
        return !isSuccess
    }
    
    var success: Success? {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }
    
    var failure: Failure? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
} 