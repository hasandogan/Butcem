import SwiftUI

@MainActor
class ReceiptScannerViewModel: ObservableObject {
    @Published var scannedReceipt: Receipt?
    @Published var isProcessing = false
    @Published var showError = false
    @Published var errorMessage: String?
    
    private let scannerService = ReceiptScannerService.shared
    
    func processReceipt(image: UIImage) async {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            scannedReceipt = try await scannerService.scanReceipt(image: image)
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
    }
    
    func saveReceipt() async {
        guard let receipt = scannedReceipt,
              let transaction = receipt.transaction else {
            return
        }
        
        do {
            try await FirebaseService.shared.addTransaction(transaction)
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
    }
} 