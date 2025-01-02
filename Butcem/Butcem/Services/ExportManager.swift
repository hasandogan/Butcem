import Foundation
import PDFKit
import UniformTypeIdentifiers

enum ExportFormat {
    case pdf
    case excel
    
    var fileExtension: String {
        switch self {
        case .pdf: return "pdf"
        case .excel: return "csv"
        }
    }
    
    var mimeType: String {
        switch self {
        case .pdf: return "application/pdf"
        case .excel: return "text/csv"
        }
    }
}

class ExportManager {
    static let shared = ExportManager()
    private init() {}
    
    func exportTransactions(_ transactions: [Transaction], format: ExportFormat) -> URL? {
        switch format {
        case .pdf:
            return createPDF(from: transactions)
        case .excel:
            return createCSV(from: transactions)
        }
    }
    
    private func createPDF(from transactions: [Transaction]) -> URL? {
        // PDF için A4 sayfa boyutu
        let pageWidth = 8.27 * 72.0
        let pageHeight = 11.69 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        // PDF oluşturma
        let pdfMetaData = [
            kCGPDFContextCreator: "Butcem App",
            kCGPDFContextAuthor: "Butcem User",
            kCGPDFContextTitle: "İşlem Raporu"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let pdfUrl = documentsPath.appendingPathComponent("transactions.pdf")
        
        do {
            try renderer.writePDF(to: pdfUrl) { context in
                context.beginPage()
                
                // Başlık
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 24)
                ]
                let titleString = "İşlem Raporu"
                titleString.draw(at: CGPoint(x: 50, y: 50), withAttributes: titleAttributes)
                
                // Tablo başlıkları
                let headerAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 12)
                ]
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                
                let headers = ["Tarih", "Tür", "Kategori", "Tutar", "Açıklama"]
                var xPosition: CGFloat = 50
                let yPosition: CGFloat = 100
                
                headers.forEach { header in
                    header.draw(at: CGPoint(x: xPosition, y: yPosition), withAttributes: headerAttributes)
                    xPosition += 100
                }
                
                // İşlemler
                let contentAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10)
                ]
                
                var currentY: CGFloat = yPosition + 20
                
                for transaction in transactions {
                    if currentY > pageHeight - 50 {
                        context.beginPage()
                        currentY = 50
                    }
                    
                    let row = [
                        dateFormatter.string(from: transaction.date),
                        transaction.type.rawValue,
                        transaction.category.rawValue,
                        transaction.amount.currencyFormat(),
                        transaction.note ?? ""
                    ]
                    
                    var currentX: CGFloat = 50
                    row.forEach { item in
                        item.draw(at: CGPoint(x: currentX, y: currentY), withAttributes: contentAttributes)
                        currentX += 100
                    }
                    
                    currentY += 20
                }
            }
            
            return pdfUrl
        } catch {
            print("PDF oluşturma hatası: \(error)")
            return nil
        }
    }
    
    private func createCSV(from transactions: [Transaction]) -> URL? {
        var csvString = "Tarih,Tür,Kategori,Tutar,Açıklama\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        for transaction in transactions {
            // CSV'de virgül ve yeni satır karakterlerini temizle
            let note = transaction.note?.replacingOccurrences(of: ",", with: ";")
                .replacingOccurrences(of: "\n", with: " ") ?? ""
            
            let row = [
                dateFormatter.string(from: transaction.date),
                transaction.type.rawValue,
                transaction.category.rawValue,
                String(format: "%.2f", transaction.amount),
                note
            ].joined(separator: ",")
            
            csvString.append(row + "\n")
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let csvUrl = documentsPath.appendingPathComponent("transactions.csv")
        
        do {
            try csvString.write(to: csvUrl, atomically: true, encoding: .utf8)
            return csvUrl
        } catch {
            print("CSV oluşturma hatası: \(error)")
            return nil
        }
    }
} 