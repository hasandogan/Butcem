import SwiftUI
import Charts

struct FamilyTransactionsCard: View {
    let budget: FamilyBudget
    let transactions: [FamilyTransaction]
    
    var body: some View {
        VStack(spacing: 20) {
            // Kategori bazlı harcamalar
            CategoryTransactionsList(budget: budget, transactions: transactions)
            
            // Harcama dağılımı grafiği
            SpendingDistributionChart(transactions: transactions)
            
            // Üye harcamaları
            MemberSpendingList(budget: budget)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// Kategori bazlı işlemler listesi
struct CategoryTransactionsList: View {
    let budget: FamilyBudget
    let transactions: [FamilyTransaction]
    
    // Hesaplamaları ayır
    var groupedTransactions: [(FamilyBudgetCategory, [FamilyTransaction])] {
        let grouped = Dictionary(grouping: transactions, by: { $0.category })
        let sortedByAmount = grouped.map { (category, transactions) in
            let total = transactions.reduce(0) { sum, transaction in
                sum + transaction.amount
            }
            return (category, transactions, total)
        }
        .sorted { $0.2 > $1.2 }
        .map { ($0.0, $0.1) }
        
        return sortedByAmount
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Kategori Bazlı Harcamalar")
                .font(.headline)
            
            ForEach(groupedTransactions, id: \.0) { category, categoryTransactions in
                CategoryTransactionRow(
                    category: category,
                    transactions: categoryTransactions
                )
            }
        }
    }
}

// Kategori satırı için ayrı bir view
struct CategoryTransactionRow: View {
    let category: FamilyBudgetCategory
    let transactions: [FamilyTransaction]
    
    var totalAmount: Double {
        transactions.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Kategori başlığı ve toplam
            HStack {
                Label(category.rawValue, systemImage: category.icon)
                    .font(.subheadline)
                Spacer()
                Text(totalAmount.currencyFormat())
                    .fontWeight(.medium)
            }
            
            // Kategori işlemleri
            ForEach(transactions) { transaction in
				FamilyTransactionRow(transaction: transaction)
            }
            
            Divider()
        }
    }
}

// İşlem satırı için ayrı bir view
struct FamilyTransactionRow: View {
    let transaction: FamilyTransaction
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(transaction.note ?? "")
                    .font(.subheadline)
                Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(transaction.amount.currencyFormat())
                    .font(.subheadline)
				Text(transaction.memberName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.leading)
    }
}

// Harcama dağılımı pasta grafiği
struct SpendingDistributionChart: View {
    let transactions: [FamilyTransaction]
    
    var categoryTotals: [(FamilyBudgetCategory, Double)] {
        Dictionary(grouping: transactions, by: { $0.category })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
            .sorted { $0.value > $1.value }
            .map { ($0.key, $0.value) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Harcama Dağılımı")
                .font(.headline)
            
            Chart {
                ForEach(categoryTotals, id: \.0) { category, amount in
                    SectorMark(
                        angle: .value("Harcama", amount),
                        innerRadius: .ratio(0.618),
                        angularInset: 1.5
                    )
                    .foregroundStyle(category.color)
                    .cornerRadius(5)
                }
            }
            .frame(height: 200)
            
            // Açıklama
            VStack(alignment: .leading, spacing: 8) {
                ForEach(categoryTotals, id: \.0) { category, amount in
                    HStack {
                        Circle()
                            .fill(category.color)
                            .frame(width: 8, height: 8)
                        Text(category.rawValue)
                            .font(.caption)
                        Spacer()
                        Text(amount.currencyFormat())
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
        }
    }
}

// Üye harcamaları listesi
struct MemberSpendingList: View {
    let budget: FamilyBudget
    
    var sortedMembers: [FamilyBudget.FamilyMember] {
        budget.members.sorted { $0.spentAmount > $1.spentAmount }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Üye Harcamaları")
                .font(.headline)
            
            ForEach(sortedMembers, id: \.id) { member in
                HStack {
                    VStack(alignment: .leading) {
                        Text(member.name.isEmpty ? member.email : member.name)
                            .font(.subheadline)
                        Text(member.role.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(member.spentAmount.currencyFormat())
                        .fontWeight(.medium)
                }
                
                // İlerleme çubuğu
                ProgressView(
                    value: member.spentAmount,
                    total: budget.totalBudget
                )
                .tint(member.spentAmount > (budget.totalBudget / Double(budget.members.count)) ? .orange : .blue)
            }
        }
    }
} 
