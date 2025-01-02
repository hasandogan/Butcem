import SwiftUI
import UniformTypeIdentifiers

struct ExportView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = TransactionsViewModel()
    @State private var showingShareSheet = false
    @State private var exportedFileURL: URL?
    @State private var dateRange: DateRange = .allTime
    @State private var startDate = Date().startOfMonth()
    @State private var endDate = Date()
    
    enum DateRange {
        case allTime
        case thisMonth
        case lastMonth
        case custom
        
        var title: String {
            switch self {
            case .allTime: return "Tüm Zamanlar"
            case .thisMonth: return "Bu Ay"
            case .lastMonth: return "Geçen Ay"
            case .custom: return "Özel Aralık"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Tarih Aralığı")) {
                    Picker("Tarih Aralığı", selection: $dateRange) {
                        Text("Tüm Zamanlar").tag(DateRange.allTime)
                        Text("Bu Ay").tag(DateRange.thisMonth)
                        Text("Geçen Ay").tag(DateRange.lastMonth)
                        Text("Özel Aralık").tag(DateRange.custom)
                    }
                    .pickerStyle(.menu)
                    
                    if dateRange == .custom {
                        DatePicker("Başlangıç", selection: $startDate, displayedComponents: .date)
                        DatePicker("Bitiş", selection: $endDate, displayedComponents: .date)
                    }
                }
                
                Section(header: Text("Dışa Aktarma Formatı")) {
                    Button {
                        if let url = viewModel.exportTransactions(format: .excel, 
                                                                dateRange: dateRange,
                                                                startDate: startDate,
                                                                endDate: endDate) {
                            exportedFileURL = url
                            showingShareSheet = true
                        }
                    } label: {
                        Label("Excel (CSV)", systemImage: "tablecells")
                    }
                    
                    Button {
                        if let url = viewModel.exportTransactions(format: .pdf,
                                                                dateRange: dateRange,
                                                                startDate: startDate,
                                                                endDate: endDate) {
                            exportedFileURL = url
                            showingShareSheet = true
                        }
                    } label: {
                        Label("PDF", systemImage: "doc.fill")
                    }
                }
            }
            .navigationTitle("Dışa Aktar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
            .onChange(of: dateRange) { newValue in
                updateDateRange(newValue)
            }
            .sheet(isPresented: $showingShareSheet, content: {
                if let url = exportedFileURL {
                    ShareSheet(activityItems: [url])
                }
            })
            .alert("Hata", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("Tamam", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
    
    private func updateDateRange(_ range: DateRange) {
        switch range {
        case .allTime:
            startDate = Date.distantPast
            endDate = Date()
        case .thisMonth:
            startDate = Date().startOfMonth()
            endDate = Date()
        case .lastMonth:
            let calendar = Calendar.current
            startDate = calendar.date(byAdding: .month, value: -1, to: Date().startOfMonth()) ?? Date()
            endDate = Date().startOfMonth().addingTimeInterval(-1)
        case .custom:
            // Mevcut seçili tarihleri koru
            break
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
} 