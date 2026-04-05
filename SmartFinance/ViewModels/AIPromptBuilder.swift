// AIPromptBuilder.swift
// SmartFinance

// AIPromptBuilder.swift
// SmartFinance

import Foundation
import CoreData

struct FinancialSummary {
    let totalIncome: Double
    let totalExpense: Double
    let balance: Double
    let categoryBreakdown: [String: Double]
    let transactionCount: Int
    let budgetWarning: String?
    let periodLabel: String
}

final class AIPromptBuilder {

    // MARK: - Ma'lumot yig'ish

    static func buildSummary(from transactions: [Transaction], periodLabel: String) -> FinancialSummary {
        let income  = transactions.filter { $0.type == "Income"  }.reduce(0) { $0 + $1.amount }
        let expense = transactions.filter { $0.type == "Expense" }.reduce(0) { $0 + $1.amount }

        var categoryTotals: [String: Double] = [:]
        for t in transactions where t.type == "Expense" {
            let cat = t.category ?? "Boshqa"
            categoryTotals[cat, default: 0] += t.amount
        }

        let budgetResult = BudgetSpeedGuard.checkSpeed(totalIncome: income, totalExpense: expense)

        return FinancialSummary(
            totalIncome: income,
            totalExpense: expense,
            balance: income - expense,
            categoryBreakdown: categoryTotals,
            transactionCount: transactions.count,
            budgetWarning: budgetResult?.message,
            periodLabel: periodLabel
        )
    }

    // MARK: - Prompt yaratish

    static func buildSystemPrompt() -> String {
        return """
        Siz SmartFinance ilovasining moliyaviy maslahatchi yordamchisisiz.

        MUHIM QOIDALAR:
        - Faqat moliya, pul, xarajat, daromad, tejash, byudjet mavzularida javob bering
        - Moliyaga aloqasiz savollarga: "Men faqat moliyaviy masalalar bo'yicha yordam bera olaman." deb javob bering
        - Javobni doim "Salom" yoki "Assalomu alaykum" bilan BOSHLAMANG
        - To'g'ridan-to'g'ri mavzuga kiring
        - Faqat o'zbek tilida yozing
        - Aniq raqamlar va foizlar bilan gapiring
        - 3-5 gap, qisqa va aniq
        - Har bir javobni to'liq tugating, o'rtada uzmang
        """
    }

    static func buildUserPrompt(summary: FinancialSummary, userQuestion: String?) -> String {
        var prompt = "\(summary.periodLabel.capitalized) moliyaviy ma'lumotlar:\n\n"

        prompt += "• Daromad: \(formatSum(summary.totalIncome))\n"
        prompt += "• Xarajat: \(formatSum(summary.totalExpense))\n"
        prompt += "• Balans: \(formatSum(summary.balance))\n"
        prompt += "• Tranzaksiyalar: \(summary.transactionCount) ta\n\n"

        if !summary.categoryBreakdown.isEmpty {
            prompt += "Xarajat taqsimoti:\n"
            let sorted = summary.categoryBreakdown.sorted { $0.value > $1.value }
            for (category, amount) in sorted {
                let pct = summary.totalExpense > 0
                    ? Int((amount / summary.totalExpense) * 100) : 0
                prompt += "  \(category): \(formatSum(amount)) (\(pct)%)\n"
            }
            prompt += "\n"
        }

        if let warning = summary.budgetWarning {
            prompt += "Tizim ogohlantirishi: \(warning)\n\n"
        }

        if let question = userQuestion, !question.isEmpty {
            prompt += "Savol: \(question)\n\nTo'liq javob ber, o'rtada uzma."
        } else {
            prompt += "Moliyaviy vaziyatni qisqacha tahlil qil va 2-3 ta amaliy maslahat ber."
        }

        return prompt
    }

    // MARK: - Helper

    private static func formatSum(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = " "
        f.maximumFractionDigits = 0
        return (f.string(from: NSNumber(value: value)) ?? "\(Int(value))") + " so'm"
    }
}
