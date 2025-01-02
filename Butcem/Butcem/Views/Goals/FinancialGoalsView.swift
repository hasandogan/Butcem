import SwiftUI

struct FinancialGoalsView: View {
    @StateObject private var viewModel = FinancialGoalViewModel()
    @State private var showingAddGoal = false
    @State private var selectedGoal: FinancialGoal?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Genel İlerleme
                GoalsSummaryCard(
                    totalTarget: viewModel.totalSavingsTarget,
                    currentAmount: viewModel.totalCurrentSavings,
                    progress: viewModel.overallProgress
                )
                
                // Yaklaşan Hedefler
                if !viewModel.getUpcomingDeadlines().isEmpty {
                    UpcomingGoalsCard(goals: viewModel.getUpcomingDeadlines())
                }
                
                // Aktif Hedefler
                if !viewModel.activeGoals.isEmpty {
                    Section(header: SectionHeader(title: "Aktif Hedefler")) {
                        ForEach(viewModel.activeGoals) { goal in
                            GoalCard(goal: goal)
                                .onTapGesture {
                                    selectedGoal = goal
                                }
                        }
                    }
                }
                
                // Tamamlanan Hedefler
                if !viewModel.completedGoals.isEmpty {
                    Section(header: SectionHeader(title: "Tamamlanan Hedefler")) {
                        ForEach(viewModel.completedGoals) { goal in
                            GoalCard(goal: goal)
                                .onTapGesture {
                                    selectedGoal = goal
                                }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Finansal Hedefler")
        .toolbar {
            Button {
                showingAddGoal = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showingAddGoal) {
            AddGoalView(viewModel: viewModel)
        }
        .sheet(item: $selectedGoal) { goal in
            GoalDetailView(viewModel: viewModel, goal: goal)
        }
        .alert("Hata", isPresented: $viewModel.showAlert) {
            Button("Tamam") {
                viewModel.clearError()
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
}

// MARK: - Helper Views
struct GoalsSummaryCard: View {
    let totalTarget: Double
    let currentAmount: Double
    let progress: Double
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Toplam Hedef")
                    .font(.headline)
                Spacer()
                Text(totalTarget.currencyFormat())
                    .font(.title2)
                    .bold()
            }
            
            ProgressView(value: progress, total: 100)
                .tint(.blue)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Biriken")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(currentAmount.currencyFormat())
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("İlerleme")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("%\(Int(progress))")
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct UpcomingGoalsCard: View {
    let goals: [FinancialGoal]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Yaklaşan Hedefler")
                .font(.headline)
            
            ForEach(goals) { goal in
                HStack {
                    Label(goal.title, systemImage: goal.category.icon)
                    Spacer()
                    Text("\(goal.remainingDays) gün")
                        .foregroundColor(goal.remainingDays < 7 ? .red : .secondary)
                }
                .font(.subheadline)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct GoalCard: View {
    let goal: FinancialGoal
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Label(goal.title, systemImage: goal.category.icon)
                    .font(.headline)
                Spacer()
                Text(goal.targetAmount.currencyFormat())
            }
            
            ProgressView(value: goal.progress, total: 100)
                .tint(goal.isCompleted ? .green : .blue)
            
            HStack {
                Text("Kalan: \(goal.remainingAmount.currencyFormat())")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(goal.progress))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
        }
        .padding(.vertical, 8)
    }
} 