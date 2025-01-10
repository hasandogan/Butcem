import Vision
import VisionKit
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth
class ReceiptScannerService: ObservableObject {
    static let shared = ReceiptScannerService()
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    
    func scanReceipt(image: UIImage) async throws -> Receipt {
        // 1. Görüntüyü işle
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Görüntü işlenemedi"])
        }
        
        // 2. OCR işlemi
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        let request = VNRecognizeTextRequest()
        try await requestHandler.perform([request])
        
        guard let observations = request.results else {
            throw NSError(domain: "", code: -2, userInfo: [NSLocalizedDescriptionKey: "Metin tanıma başarısız"])
        }
        
        // 3. Metni analiz et
        let recognizedText = observations.compactMap { $0.topCandidates(1).first?.string }
        
        // 4. Fatura bilgilerini çıkar
        let receiptInfo = try await extractReceiptInfo(from: recognizedText)
        
        // 5. Görüntüyü kaydet
        let imageURL = try await uploadImage(image)
        
        // 6. Receipt oluştur
        let receipt = Receipt(
            id: UUID().uuidString,
            imageURL: imageURL,
            date: receiptInfo.date,
            merchantName: receiptInfo.merchantName,
            totalAmount: receiptInfo.totalAmount,
            items: receiptInfo.items,
            category: receiptInfo.suggestedCategory,
            status: .completed,
			userId: AuthManager.shared.currentUserId ?? "",
            createdAt: Date()
        )
        
        // 7. Firestore'a kaydet
        try await saveReceipt(receipt)
        
        return receipt
    }
    
    private func extractReceiptInfo(from text: [String]) async throws -> (
        date: Date,
        merchantName: String?,
        totalAmount: Double,
        items: [ReceiptItem]?,
        suggestedCategory: Category
    ) {
        print("Tanınan metin satırları:")
        text.forEach { print($0) }
        
        // Toplam tutar analizi
        let totalPatterns = [
            #"TOPLAM\s*[*]?(\d+[.,]\d{2})"#,          // TOPLAM 91,65
            #"KREDİ\s*KARTI\s*[*]?(\d+[.,]\d{2})"#    // KREDİ KARTI 91,65
        ]
        
        var totalAmount: Double = 0
        for pattern in totalPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = text.reversed().first(where: { line in
                   let range = NSRange(line.startIndex..., in: line)
                   return regex.firstMatch(in: line, range: range) != nil
               }),
               let amount = match.extractAmount() {
                totalAmount = amount
                print("Bulunan toplam tutar: \(totalAmount)")
                break
            }
        }
        
        // Tarih analizi - daha kapsamlı regex
        let datePatterns = [
            #"\d{2}[/.]\d{2}[/.]\d{4}"#,  // 08.01.2024
            #"\d{2}[-]\d{2}[-]\d{4}"#,     // 08-01-2024
            #"\d{4}[-]\d{2}[-]\d{2}"#      // 2024-01-08
        ]
        
        var receiptDate = Date()
        for pattern in datePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = text.first(where: { line in
                   let range = NSRange(line.startIndex..., in: line)
                   return regex.firstMatch(in: line, range: range) != nil
               }) {
                if let date = match.toDate() {
                    receiptDate = date
                    print("Bulunan tarih: \(date)")
                    break
                }
            }
        }
        
        // Mağaza adı analizi - en büyük tutarlı ürünü bul
        let items = extractItems(from: text, totalAmount: totalAmount)
        let merchantName = items.max(by: { $0.price < $1.price })?.name
        print("Bulunan mağaza adı (en yüksek tutarlı ürün): \(merchantName ?? "Bulunamadı")")
        
        // Kategori tahmini - tüm ürün isimlerini kullan
        let category = suggestCategory(from: items.map { $0.name })
        print("Önerilen kategori: \(category.localizedName)")
        
        return (
            date: receiptDate,
            merchantName: merchantName,
            totalAmount: totalAmount,
            items: items,
            suggestedCategory: category
        )
    }
    
    private func uploadImage(_ image: UIImage) async throws -> String {
        // Resmi boyutlandır
        let resizedImage = image.resizedImage(targetSize: CGSize(width: 800, height: 800))
        
        guard var imageData = resizedImage.jpegData(compressionQuality: 0.5) else {
            throw NSError(domain: "", code: -3, userInfo: [NSLocalizedDescriptionKey: "Görüntü sıkıştırılamadı"])
        }
        
        // Boyut kontrolü ve sıkıştırma
        let maxSize = 2 * 1024 * 1024
        if imageData.count > maxSize {
            var compressionQuality: CGFloat = 0.5
            while imageData.count > maxSize && compressionQuality > 0.1 {
                compressionQuality -= 0.1
                if let newData = resizedImage.jpegData(compressionQuality: compressionQuality) {
                    imageData = newData
                }
            }
        }
        
        let filename = "\(UUID().uuidString).jpg"
        let storageRef = storage.reference()
        let receiptsRef = storageRef.child("receipts")
        let imageRef = receiptsRef.child(filename)
        
        do {
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            print("Dosya yükleniyor: receipts/\(filename) (Boyut: \(imageData.count) bytes)")
            
            // Önce yükleme işlemini tamamla
            _ = try await imageRef.putDataAsync(imageData, metadata: metadata)
            
            // Yükleme başarılı olduktan sonra URL'yi al
            let downloadURL = try await imageRef.downloadURL()
            print("Dosya başarıyla yüklendi: \(downloadURL.absoluteString)")
            
            return downloadURL.absoluteString
        } catch let error as NSError {
            print("""
                Yükleme hatası:
                Error: \(error.localizedDescription)
                Code: \(error.code)
                Domain: \(error.domain)
                File: receipts/\(filename)
                Size: \(imageData.count) bytes
                """)
            
            // Firebase Storage'a özgü hata kodlarını kontrol et
            if error.domain == StorageErrorDomain {
                switch error.code {
                case StorageErrorCode.objectNotFound.rawValue:
                    throw NSError(
                        domain: "",
                        code: -4,
                        userInfo: [NSLocalizedDescriptionKey: "Dosya yüklenemedi. Lütfen internet bağlantınızı kontrol edip tekrar deneyin."]
                    )
                case StorageErrorCode.unauthorized.rawValue:
                    throw NSError(
                        domain: "",
                        code: -4,
                        userInfo: [NSLocalizedDescriptionKey: "Dosya yükleme izniniz yok. Lütfen tekrar giriş yapın."]
                    )
                default:
                    throw NSError(
                        domain: "",
                        code: -4,
                        userInfo: [NSLocalizedDescriptionKey: "Fatura yüklenirken bir hata oluştu (\(error.code)). Lütfen tekrar deneyin."]
                    )
                }
            }
            
            throw NSError(
                domain: "",
                code: -4,
                userInfo: [NSLocalizedDescriptionKey: "Fatura yüklenirken beklenmeyen bir hata oluştu. Lütfen tekrar deneyin."]
            )
        }
    }
    
    private func saveReceipt(_ receipt: Receipt) async throws {
        try await db.collection("receipts").document(receipt.id).setData(from: receipt)
    }
    
    private func suggestCategory(from itemNames: [String]) -> Category {
        let marketKeywords = ["MARKET", "SÜPERMARKET", "GIDA", "YOĞURT", "EKMEK", "SÜT", "ÇAMAŞIR", "DETERJAN"]
        let restaurantKeywords = ["RESTAURANT", "CAFE", "LOKANTA", "KAHVE", "YEMEK"]
        let billKeywords = ["FATURA", "ELEKTRİK", "SU", "DOĞALGAZ", "İNTERNET"]
        let healthKeywords = ["ECZANE", "İLAÇ", "HASTANE", "SAĞLIK"]
        let clothingKeywords = ["GİYİM", "KIYAFET", "AYAKKABI", "ÇANTA"]
        
        let upperNames = itemNames.map { $0.uppercased() }
        
        // Her kategorinin eşleşme sayısını hesapla
        var categoryMatches: [Category: Int] = [:]
        
        for name in upperNames {
            if marketKeywords.contains(where: { name.contains($0) }) {
                categoryMatches[.market, default: 0] += 1
            }
            if restaurantKeywords.contains(where: { name.contains($0) }) {
                categoryMatches[.restoran, default: 0] += 1
            }
            if billKeywords.contains(where: { name.contains($0) }) {
                categoryMatches[.faturalar, default: 0] += 1
            }
            if healthKeywords.contains(where: { name.contains($0) }) {
                categoryMatches[.saglik, default: 0] += 1
            }
            if clothingKeywords.contains(where: { name.contains($0) }) {
                categoryMatches[.giyim, default: 0] += 1
            }
        }
        
        // En çok eşleşen kategoriyi bul
        return categoryMatches.max(by: { $0.value < $1.value })?.key ?? .digerGider
    }
    
    private func extractItems(from text: [String], totalAmount: Double) -> [ReceiptItem] {
        var items: [ReceiptItem] = []
        
        // Ürün satırı formatı: {ürün adı} %{kdv} {fiyat}
        let itemPattern = #"(.+?)\s+%(\d+)\s+[*]?(\d+[.,]\d{2})"#
        
        for line in text {
            // Toplam ve KDV satırlarını atla
            if line.uppercased().contains("TOPLAM") || 
               line.uppercased().contains("KDV") ||
               line.uppercased().contains("FİŞ") ||
               line.uppercased().contains("KREDİ KARTI") {
                continue
            }
            
            if let regex = try? NSRegularExpression(pattern: itemPattern),
               let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) {
                let nsLine = line as NSString
                
                // Ürün adı
                let name = nsLine.substring(with: match.range(at: 1))
                    .trimmingCharacters(in: .whitespaces)
                
                // Fiyat
                if let price = line.extractAmount(),
                   price > 0,
                   price != totalAmount {
                    let item = ReceiptItem(
                        id: UUID().uuidString,
                        name: name,
                        quantity: 1,
                        price: price,
                        totalPrice: price
                    )
                    items.append(item)
                    print("Bulunan ürün: \(name) - \(price)")
                }
            }
        }
        
        return items
    }
}

// UIImage extension ekle
private extension UIImage {
    func resizedImage(targetSize: CGSize) -> UIImage {
        let size = self.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // En-boy oranını koru
        let ratio = min(widthRatio, heightRatio)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? self
    }
} 
