import SwiftUI

struct AdvancedAnalytics {
    let transactions: [Transaction]
    let budget: Budget?
    let recurringTransactions: [RecurringTransaction]
    
    // Güven puanı hesaplama (0-100 arası)
    var trustScore: Double {
        // Her bileşenin puanını ayrı ayrı hesapla
        let budgetScore = calculateBudgetManagementScore()     // 0-30 puan
        let paymentScore = calculatePaymentRegularityScore()   // 0-25 puan
        let savingsScore = calculateSavingsScore()             // 0-25 puan
        let categoryScore = calculateCategoryBalanceScore()    // 0-20 puan
        
        // Toplam puanı hesapla
        let totalScore = budgetScore + paymentScore + savingsScore + categoryScore
        
        
        return min(max(totalScore, 0), 100)
    }
    
    // Bütçe yönetimi puanı
    private func calculateBudgetManagementScore() -> Double {
        guard let budget = budget else { return 0 }
        
        var score = 15.0 // Başlangıç puanı (orta seviye)
        let categoryLimits = budget.categoryLimits
        
        if categoryLimits.isEmpty { return 0 }
        
        let totalPossibleScore = Double(categoryLimits.count * 5) // Her kategori için maksimum 5 puan
        var earnedScore = 0.0
        
        for limit in categoryLimits {
            let spentRatio = limit.spent / limit.limit
            
            if spentRatio <= 0.7 { // %70'in altında harcama - mükemmel
                earnedScore += 5.0
            } else if spentRatio <= 0.85 { // %85'in altında harcama - iyi
                earnedScore += 4.0
            } else if spentRatio <= 1.0 { // Limit içinde - orta
                earnedScore += 3.0
            } else if spentRatio <= 1.1 { // %10 aşım - kötü
                earnedScore += 1.0
            } else { // %10'dan fazla aşım - çok kötü
                earnedScore -= 2.0
            }
        }
        
        // Puanı 30 üzerinden normalize et
        let normalizedScore = (earnedScore / totalPossibleScore) * 30
        return min(max(normalizedScore, 0), 30)
    }
    
    // Düzenli ödeme puanı
    private func calculatePaymentRegularityScore() -> Double {
        let recurringCount = recurringTransactions.count
        if recurringCount == 0 { return 12.5 } // Tekrarlanan işlem yoksa orta puan
        
        let activeRecurring = recurringTransactions.filter { $0.isActive }.count
        let activeRatio = Double(activeRecurring) / Double(recurringCount)
        
        // Son 3 ayda zamanında yapılan ödemelerin oranı
        let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
        let recentTransactions = transactions.filter { $0.date >= threeMonthsAgo }
        
        if recentTransactions.isEmpty { return 12.5 } // İşlem yoksa orta puan
        
        let onTimePayments = recentTransactions.filter { transaction in
            guard let note = transaction.note, note.contains("Otomatik oluşturuldu:") else { 
                // Manuel işlemler için vade tarihini kontrol et
                if let dueDate = getDueDate(for: transaction),
                   transaction.date <= dueDate {
                    return true
                }
                return false
            }
            return true
        }.count
        
        let paymentRatio = Double(onTimePayments) / Double(recentTransactions.count)
        
        // Aktiflik ve ödeme oranlarını ağırlıklı olarak hesapla
        let weightedScore = (activeRatio * 0.4 + paymentRatio * 0.6) * 25
        return min(weightedScore, 25)
    }
    
    // Tasarruf puanı
    private func calculateSavingsScore() -> Double {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let monthlyTransactions = transactions.filter {
            Calendar.current.component(.month, from: $0.date) == currentMonth
        }
        
        let totalIncome = monthlyTransactions
            .filter { $0.type == TransactionType.income }
            .reduce(0) { $0 + $1.amount }
        
        let totalExpense = monthlyTransactions
            .filter { $0.type == TransactionType.expense }
            .reduce(0) { $0 + $1.amount }
        
        if totalIncome == 0 { return 12.5 } // Gelir yoksa orta puan
        
        let savingsRatio = (totalIncome - totalExpense) / totalIncome
        
        // Tasarruf oranına göre dinamik puanlama
        if savingsRatio >= 0.3 { // %30 ve üzeri tasarruf
            return 25.0
        } else if savingsRatio >= 0.2 { // %20-%30 arası
            return 20.0 + ((savingsRatio - 0.2) / 0.1) * 5.0
        } else if savingsRatio >= 0.1 { // %10-%20 arası
            return 15.0 + ((savingsRatio - 0.1) / 0.1) * 5.0
        } else if savingsRatio >= 0 { // %0-%10 arası
            return 10.0 + (savingsRatio / 0.1) * 5.0
        } else { // Negatif tasarruf
            return max(0, 10.0 + (savingsRatio * 20.0))
        }
    }
    
    // Kategori dengesi puanı
    private func calculateCategoryBalanceScore() -> Double {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let monthlyExpenses = transactions.filter {
            Calendar.current.component(.month, from: $0.date) == currentMonth &&
            $0.type == TransactionType.expense
        }
        
        if monthlyExpenses.isEmpty { return 10.0 } // İşlem yoksa orta puan
        
        var categoryExpenses: [Category: Double] = [:]
        monthlyExpenses.forEach { transaction in
            categoryExpenses[transaction.category, default: 0] += transaction.amount
        }
        
        let totalExpense = monthlyExpenses.reduce(0) { $0 + $1.amount }
        var score = 20.0
        
        // Kategori çeşitliliği puanı
        let categoryCount = categoryExpenses.count
		let diversityScore = min(Double(categoryCount) * 2.0, 10.0) // Maksimum 10 puan
        
        // Denge puanı
        var balanceScore = 10.0
        for (_, amount) in categoryExpenses {
            let ratio = amount / totalExpense
            if ratio > 0.4 { // Bir kategoride %40'tan fazla harcama
                balanceScore -= (ratio - 0.4) * 25
            }
        }
        
        return max(diversityScore + balanceScore, 0)
    }
    
    // Yardımcı fonksiyon: İşlem için vade tarihi bulma
    private func getDueDate(for transaction: Transaction) -> Date? {
        // Tekrarlanan işlemlerden bu işlemle eşleşeni bul
        let matchingRecurring = recurringTransactions.first {
            $0.amount == transaction.amount &&
            $0.category == transaction.category &&
            $0.type == transaction.type
        }
        
        return matchingRecurring?.nextProcessDate
    }
    
    // Güven puanı açıklaması
    var trustScoreDescription: String {
        let score = trustScore
        switch score {
        case 90...100:
            return "Mükemmel finansal yönetim! Bütçenizi çok iyi kontrol ediyorsunuz.".localized
        case 80..<90:
            return "Çok iyi! Finansal hedeflerinize ulaşmak için doğru yoldasınız.".localized
        case 70..<80:
            return "İyi! Bazı küçük iyileştirmelerle daha da yükselebilirsiniz.".localized
        case 60..<70:
            return "Orta! Bütçe yönetiminizde geliştirilmesi gereken alanlar var.".localized
        case 50..<60:
            return "Geliştirilmeli! Bütçenizi daha dikkatli takip etmelisiniz.".localized
        default:
            return "Dikkat! Finansal alışkanlıklarınızı gözden geçirmeniz gerekiyor.".localized
        }
    }
    
    // Güven puanı rengi
    var trustScoreColor: Color {
        let score = trustScore
        switch score {
        case 90...100: return .green
        case 80..<90: return .mint
        case 70..<80: return .blue
        case 60..<70: return .yellow
        case 50..<60: return .orange
        default: return .red
        }
    }
} 
