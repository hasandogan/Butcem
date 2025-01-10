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
						Label("İlerleme Güncelle".localized, systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
				
					Button {
						showingDeleteAlert = true
					} label: {
						Label("Hedefi Sil".localized, systemImage: "trash")
							.frame(maxWidth: .infinity)
							.padding()
							.background(.red)
							.foregroundColor(.white)
							.cornerRadius(10)
					}
					.padding(.horizontal)
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
						Label("İlerleme Güncelle".localized, systemImage: "arrow.clockwise")
                    }
                }
                
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
					Label("Hedefi Sil".localized, systemImage: "trash")
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
		.alert("Hedefi Sil".localized, isPresented: $showingDeleteAlert) {
			Button("İptal".localized, role: .cancel) {}
			Button("Sil".localized, role: .destructive) {
                Task {
                    await viewModel.deleteGoal(goal)
                    dismiss()
                }
            }
        } message: {
			Text("Bu hedefi silmek istediğinizden emin misiniz?".localized)
        }
    }
}

// MARK: - Helper Views
struct GoalProgressCard: View {
    let goal: FinancialGoal
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
				Label(goal.category.localizedName, systemImage: goal.category.icon)
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
					Text("Biriken".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(goal.currentAmount.currencyFormat())
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
					Text("Kalan".localized)
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
			Text("Detaylar".localized)
                .font(.headline)
            
			DetailRow(title: "Hedef Tipi".localized, value: goal.type.localizedName)
			DetailRow(title: "Son Tarih".localized, value: goal.deadline.formatted(date: .long, time: .omitted))
			DetailRow(title: "Kalan Süre".localized, value: "\(goal.remainingDays) Gün".localized)
			DetailRow(title: "İlerleme".localized, value: "%\(Int(goal.progress))".localized)
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
			Text("Aylık Hedef".localized)
                .font(.headline)
            
            HStack {
				Text("Aylık Birikim Hedefi".localized)
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
			Text("İlerleme Grafiği".localized)
                .font(.headline)
            
            Chart {
                BarMark(
					x: .value("İlerleme".localized, goal.currentAmount),
					y: .value("", "İlerleme".localized)
                )
                .foregroundStyle(.blue)
                
                RuleMark(
					x: .value("Hedef".localized, goal.targetAmount)
                )
                .foregroundStyle(.red)
                .annotation(position: .top) {
					Text("Hedef".localized)
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
			Text("Notlar".localized)
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
                        Text("")
						TextField("Mevcut Birikim".localized, value: $currentAmount, format: .number)
                            .keyboardType(.decimalPad)
                    }
                }
            }
			.navigationTitle("İlerleme Güncelle".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
					Button("İptal".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
					Button("Kaydet".localized) {
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
