import SwiftUI
import VisionKit

struct ReceiptScannerView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = ReceiptScannerViewModel()
    @State private var showingImagePicker = false
    @State private var showingScanner = false
    @State private var scannedImage: UIImage?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let image = scannedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                        .cornerRadius(12)
                }
                
                VStack(spacing: 16) {
                    Button {
                        showingScanner = true
                    } label: {
                        Label("Fatura Tara", systemImage: "doc.text.viewfinder")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    Button {
                        showingImagePicker = true
                    } label: {
                        Label("Galeriden Seç", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.secondary.opacity(0.1))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                    }
                }
                .padding()
                
                if viewModel.isProcessing {
                    ProgressView("İşleniyor...")
                }
                
                if let receipt = viewModel.scannedReceipt {
                    ReceiptPreviewCard(receipt: receipt) {
                        Task {
                            await viewModel.saveReceipt()
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Fatura Tarama")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $scannedImage)
            }
            .sheet(isPresented: $showingScanner) {
                ScannerView { result in
                    switch result {
                    case .success(let scan):
                        scannedImage = scan.image
                        processScannedImage(scan.image)
                    case .failure(let error):
                        print("Scanning error: \(error.localizedDescription)")
                    }
                    showingScanner = false
                }
            }
            .onChange(of: scannedImage) { newImage in
                if let image = newImage {
                    processScannedImage(image)
                }
            }
            .alert("Hata", isPresented: $viewModel.showError) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "Bir hata oluştu")
            }
        }
    }
    
    private func processScannedImage(_ image: UIImage) {
        Task {
            await viewModel.processReceipt(image: image)
        }
    }
}

struct ReceiptPreviewCard: View {
    let receipt: Receipt
    let onSave: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let merchantName = receipt.merchantName {
                Text(merchantName)
                    .font(.headline)
            }
            
            HStack {
                Label(receipt.category.localizedName, systemImage: receipt.category.icon)
                Spacer()
                Text(receipt.totalAmount.currencyFormat())
                    .font(.headline)
            }
            
            Text(receipt.date.formatted(date: .abbreviated, time: .shortened))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: onSave) {
                Text("İşlem Olarak Kaydet")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
} 