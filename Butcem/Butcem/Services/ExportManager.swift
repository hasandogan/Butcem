import Foundation
import PDFKit
import UniformTypeIdentifiers

class ExportManager {
    static let shared = ExportManager()
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter
    }()
    
    func generatePDF(transactions: [Transaction], startDate: Date, endDate: Date) -> URL? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Bütçem",
            kCGPDFContextAuthor: "Bütçem App",
            kCGPDFContextTitle: "İşlem Raporu"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.27 * 72.0 // A4 genişlik
        let pageHeight = 11.69 * 72.0 // A4 yükseklik
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRendererFormat()
        let data = try? UIGraphicsPDFRenderer(bounds: pageRect, format: renderer).pdfData { context in
            context.beginPage()
            
            // Başlık
            let title = "İşlem Raporu"
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24)
            ]
            let titleSize = (title as NSString).size(withAttributes: titleAttributes)
            let titleRect = CGRect(x: (pageWidth - titleSize.width) / 2,
                                 y: 50,
                                 width: titleSize.width,
                                 height: titleSize.height)
            title.draw(in: titleRect, withAttributes: titleAttributes)
            
            // Tarih aralığı
            let dateRange = "\(dateFormatter.string(from: startDate)) - \(dateFormatter.string(from: endDate))"
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14)
            ]
            let dateSize = (dateRange as NSString).size(withAttributes: dateAttributes)
            let dateRect = CGRect(x: (pageWidth - dateSize.width) / 2,
                                y: titleRect.maxY + 20,
                                width: dateSize.width,
                                height: dateSize.height)
            dateRange.draw(in: dateRect, withAttributes: dateAttributes)
            
            // Tablo başlıkları
            let headers = ["Tarih", "Tür", "Kategori", "Not", "Tutar"]
            let columnWidths: [CGFloat] = [100, 80, 100, 200, 100]
            var xPosition: CGFloat = 40
            var yPosition: CGFloat = dateRect.maxY + 40
            
            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 12)
            ]
            
            for (index, header) in headers.enumerated() {
                let headerRect = CGRect(x: xPosition,
                                      y: yPosition,
                                      width: columnWidths[index],
                                      height: 20)
                header.draw(in: headerRect, withAttributes: headerAttributes)
                xPosition += columnWidths[index]
            }
            
            // Çizgi çek
            yPosition += 25
            let line = UIBezierPath()
            line.move(to: CGPoint(x: 40, y: yPosition))
            line.addLine(to: CGPoint(x: pageWidth - 40, y: yPosition))
            line.lineWidth = 1
            UIColor.black.setStroke()
            line.stroke()
            
            // İşlemleri listele
            let cellAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11)
            ]
            
            // Tarihe göre sırala
            let sortedTransactions = transactions.sorted { $0.date < $1.date }
            
            for transaction in sortedTransactions {
                if transaction.date >= startDate && transaction.date <= endDate {
                    yPosition += 25
                    xPosition = 40
                    
                    // Tarih
                    dateFormatter.string(from: transaction.date)
                        .draw(in: CGRect(x: xPosition, y: yPosition, width: columnWidths[0], height: 20),
                              withAttributes: cellAttributes)
                    xPosition += columnWidths[0]
                    
                    // Tür
                    transaction.type.rawValue
                        .draw(in: CGRect(x: xPosition, y: yPosition, width: columnWidths[1], height: 20),
                              withAttributes: cellAttributes)
                    xPosition += columnWidths[1]
                    
                    // Kategori
                    transaction.category.localizedName
                        .draw(in: CGRect(x: xPosition, y: yPosition, width: columnWidths[2], height: 20),
                              withAttributes: cellAttributes)
                    xPosition += columnWidths[2]
                    
                    // Not
					transaction.note?
                        .draw(in: CGRect(x: xPosition, y: yPosition, width: columnWidths[3], height: 20),
                              withAttributes: cellAttributes)
                    xPosition += columnWidths[3]
                    
                    // Tutar
                    transaction.amount.currencyFormat()
                        .draw(in: CGRect(x: xPosition, y: yPosition, width: columnWidths[4], height: 20),
                              withAttributes: cellAttributes)
                    
                    // Yeni sayfa kontrolü
                    if yPosition > pageHeight - 100 {
                        context.beginPage()
                        yPosition = 50
                    }
                }
            }
            
            // Özet bilgiler
            let totalIncome = transactions
                .filter { $0.date >= startDate && $0.date <= endDate && $0.type == .income }
                .reduce(0) { $0 + $1.amount }
            
            let totalExpense = transactions
                .filter { $0.date >= startDate && $0.date <= endDate && $0.type == .expense }
                .reduce(0) { $0 + $1.amount }
            
            yPosition += 40
            
            let summaryAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 14)
            ]
            
            "Toplam Gelir: \(totalIncome.currencyFormat())"
                .draw(in: CGRect(x: 40, y: yPosition, width: 200, height: 20),
                      withAttributes: summaryAttributes)
            
            "Toplam Gider: \(totalExpense.currencyFormat())"
                .draw(in: CGRect(x: 40, y: yPosition + 25, width: 200, height: 20),
                      withAttributes: summaryAttributes)
            
            "Net: \((totalIncome - totalExpense).currencyFormat())"
                .draw(in: CGRect(x: 40, y: yPosition + 50, width: 200, height: 20),
                      withAttributes: summaryAttributes)
        }
        
        // PDF dosyasını kaydet
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let pdfPath = documentsPath.appendingPathComponent("islem_raporu.pdf")
        
        try? data?.write(to: pdfPath)
        return pdfPath
    }
    
    func generateExcel(transactions: [Transaction], startDate: Date, endDate: Date) -> URL? {
        var csvString = "Tarih,Tür,Kategori,Not,Tutar\n"
        
        let filteredTransactions = transactions
            .filter { $0.date >= startDate && $0.date <= endDate }
            .sorted { $0.date < $1.date }
        
        for transaction in filteredTransactions {
            let row = [
                dateFormatter.string(from: transaction.date),
                transaction.type.rawValue,
                transaction.category.localizedName,
                transaction.note,
                transaction.amount.currencyFormat()
            ].map { "\"\($0)\"" }.joined(separator: ",")
            
            csvString.append(row + "\n")
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let csvPath = documentsPath.appendingPathComponent("islem_raporu.csv")
        
        try? csvString.write(to: csvPath, atomically: true, encoding: .utf8)
        return csvPath
    }
} 
