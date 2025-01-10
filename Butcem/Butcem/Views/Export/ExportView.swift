import SwiftUI
import UniformTypeIdentifiers

struct ExportView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = TransactionsViewModel()
    @State private var startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var showingExportOptions = false
    @State private var selectedExportType: ExportType = .pdf
    @State private var exportURL: URL?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Tarih Seçimi
                    dateSelectionSection
                    
                    // İşlem Sayısı
                    transactionCountSection
                    
                    // Dışa Aktarma Seçenekleri
                    exportOptionsSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dışa Aktar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarItems
            }
            .sheet(isPresented: $showingExportOptions) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .task {
                await viewModel.refreshData()
            }
        }
    }
    
    private var dateSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tarih Aralığı")
                .font(.headline)
            
            VStack(spacing: 12) {
                DatePickerField(
                    title: "Başlangıç",
                    date: $startDate,
                    icon: "calendar"
                )
                
                DatePickerField(
                    title: "Bitiş",
                    date: $endDate,
                    icon: "calendar.badge.clock"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var transactionCountSection: some View {
        HStack {
            Label(
                title: { Text("İşlem Sayısı") },
                icon: { Image(systemName: "doc.text.fill") }
            )
            
            Spacer()
            
            Text("\(filteredTransactionCount)")
                .font(.headline)
                .foregroundColor(.accentColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var exportOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Dışa Aktarma Formatı")
                .font(.headline)
            
            Picker("Format", selection: $selectedExportType) {
                ForEach(ExportType.allCases) { type in
                    Label(
                        type.description,
                        systemImage: type.icon
                    ).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(8)
            .background(Color(.systemBackground))
            .cornerRadius(8)
            
            Button(action: exportData) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Dışa Aktar")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    filteredTransactionCount > 0 ?
                    Color.accentColor : Color.gray
                )
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(filteredTransactionCount == 0)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var toolbarItems: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("İptal") {
                    dismiss()
                }
            }
        }
    }
    
    private var filteredTransactionCount: Int {
        viewModel.transactions.filter { transaction in
            transaction.date >= startDate && transaction.date <= endDate
        }.count
    }
    
    private func exportData() {
        let filteredTransactions = viewModel.transactions.filter { transaction in
            transaction.date >= startDate && transaction.date <= endDate
        }
        
        switch selectedExportType {
        case .pdf:
            exportURL = ExportManager.shared.generatePDF(
                transactions: filteredTransactions,
                startDate: startDate,
                endDate: endDate
            )
        case .excel:
            exportURL = ExportManager.shared.generateExcel(
                transactions: filteredTransactions,
                startDate: startDate,
                endDate: endDate
            )
        }
        
        if exportURL != nil {
            showingExportOptions = true
        }
    }
}

enum ExportType: String, CaseIterable, Identifiable {
    case pdf
    case excel
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .pdf: return "PDF"
        case .excel: return "Excel"
        }
    }
    
    var icon: String {
        switch self {
        case .pdf: return "doc.fill"
        case .excel: return "tablecells"
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct DatePickerField: View {
    let title: String
    @Binding var date: Date
    let icon: String
    
    var body: some View {
        HStack {
            Label(title, systemImage: icon)
                .foregroundColor(.secondary)
            
            Spacer()
            
            DatePicker(
                "",
                selection: $date,
                displayedComponents: .date
            )
            .labelsHidden()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
} 
