import SwiftUI
import Charts

struct GoalDetailView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: FinancialGoalViewModel
    @State private var showingUpdateProgress = false
    @State private var showingDeleteAlert = false
    @State private var newAmount: Double = 0
    
    let goal: FinancialGoal
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // İlerleme Kartı
                GoalProgressCard(goal: goal)
                
                // Detay Kartı
                GoalDetailsCard(goal: goal)
                
                // Aylık Hedef Kartı
                if !goal.isCompleted {
                    MonthlyTargetCard(goal: goal)
                }
                
                // İlerleme Grafiği
                GoalProgressChart(goal: goal)
                
                // Notlar
                if let notes = goal.notes {
                    NotesCard(notes: notes)
                }
                
                // İlerleme Güncelle Butonu
                if !goal.isCompleted {
                    Button {
                        newAmount = goal.currentAmount
                        showingUpdateProgress = true
                    } label: {
                        Label("İlerleme Güncelle", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(goal.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Menu {
                if !goal.isCompleted {
                    Button {
                        showingUpdateProgress = true
                    } label: {
                        Label("İlerleme Güncelle", systemImage: "arrow.clockwise")
                    }
                }
                
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Hedefi Sil", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        .sheet(isPresented: $showingUpdateProgress) {
            UpdateProgressView(
                viewModel: viewModel,
                goal: goal,
                currentAmount: $newAmount
            )
        }
        .alert("Hedefi Sil", isPresented: $showingDeleteAlert) {
            Button("İptal", role: .cancel) {}
            Button("Sil", role: .destructive) {
                Task {
                    await viewModel.deleteGoal(goal)
                    dismiss()
                }
            }
        } message: {
            Text("Bu hedefi silmek istediğinizden emin misiniz?")
        }
    }
}

// MARK: - Helper Views
struct GoalProgressCard: View {
    let goal: FinancialGoal
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Label(goal.category.rawValue, systemImage: goal.category.icon)
                    .font(.headline)
                Spacer()
                Text(goal.targetAmount.currencyFormat())
                    .font(.title2)
                    .bold()
            }
            
            ProgressView(value: goal.progress, total: 100)
                .tint(goal.isCompleted ? .green : .blue)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Biriken")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(goal.currentAmount.currencyFormat())
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Kalan")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(goal.remainingAmount.currencyFormat())
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct GoalDetailsCard: View {
    let goal: FinancialGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detaylar")
                .font(.headline)
            
            DetailRow(title: "Hedef Tipi", value: goal.type.rawValue)
            DetailRow(title: "Son Tarih", value: goal.deadline.formatted(date: .long, time: .omitted))
            DetailRow(title: "Kalan Süre", value: "\(goal.remainingDays) gün")
            DetailRow(title: "İlerleme", value: "%\(Int(goal.progress))")
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct MonthlyTargetCard: View {
    let goal: FinancialGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Aylık Hedef")
                .font(.headline)
            
            HStack {
                Text("Aylık Birikim Hedefi")
                Spacer()
                Text(goal.monthlyTargetAmount.currencyFormat())
                    .bold()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct GoalProgressChart: View {
    let goal: FinancialGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("İlerleme Grafiği")
                .font(.headline)
            
            Chart {
                BarMark(
                    x: .value("İlerleme", goal.currentAmount),
                    y: .value("", "İlerleme")
                )
                .foregroundStyle(.blue)
                
                RuleMark(
                    x: .value("Hedef", goal.targetAmount)
                )
                .foregroundStyle(.red)
                .annotation(position: .top) {
                    Text("Hedef")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(height: 100)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct NotesCard: View {
    let notes: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notlar")
                .font(.headline)
            
            Text(notes)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
    }
}

struct UpdateProgressView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: FinancialGoalViewModel
    let goal: FinancialGoal
    @Binding var currentAmount: Double
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Text("₺")
                        TextField("Mevcut Birikim", value: $currentAmount, format: .number)
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .navigationTitle("İlerleme Güncelle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
                        Task {
                            await viewModel.updateProgress(goal, amount: currentAmount)
                            dismiss()
                        }
                    }
                }
            }
        }
    }
} 