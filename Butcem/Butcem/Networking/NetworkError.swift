import Foundation

enum NetworkError: LocalizedError {
	case authenticationError
	case connectionError
	case serverError(String)
	case decodingError
	case encodingError
	case invalidData(String)
	case unknown
	case noConnection
	case notFound(String)
	
	var errorDescription: String? {
		switch self {
		case .authenticationError:
			return "Oturum süreniz doldu. Lütfen tekrar giriş yapın."
		case .connectionError:
			return "İnternet bağlantınızı kontrol edin."
		case .serverError(let message):
			return message
		case .decodingError:
			return "Veri işlenirken bir hata oluştu."
		case .encodingError:
			return "Veri gönderilirken bir hata oluştu."
		case .invalidData(let message):
			return message
		case .unknown:
			return "Bilinmeyen bir hata oluştu."
		case .noConnection:
			return "İnternet bağlantısı yok"
		case .notFound(let message):
			return message
		}
		
	}
}
