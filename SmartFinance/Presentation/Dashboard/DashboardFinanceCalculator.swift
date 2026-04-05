//
//  DashboardFinanceCalculator.swift
//  SmartFinance
//

import UIKit
import DGCharts

enum DashboardFinanceCalculator {

    static func filterBySegment(_ transactions: [Transaction], segmentIndex: Int) -> [Transaction] {
        let calendar = Calendar.current
        let now = Date()

        return transactions.filter { transaction in
            guard let date = transaction.date else { return false }
            switch segmentIndex {
            case 0: return calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
            case 1: return calendar.isDate(date, equalTo: now, toGranularity: .month)
            case 2: return calendar.isDate(date, equalTo: now, toGranularity: .year)
            default: return false
            }
        }
    }

    static func balanceTextAndColor(filtered: [Transaction]) -> (text: String, color: UIColor) {
        let income = filtered.filter { $0.type == "Income" }.reduce(0) { $0 + $1.amount }
        let expense = filtered.filter { $0.type == "Expense" }.reduce(0) { $0 + $1.amount }
        let total = income - expense
        let text = "\(Int(total)) so'm"
        let color: UIColor = total >= 0 ? .systemGreen : .systemRed
        return (text, color)
    }

    struct SpeedWarningStyle {
        let message: String
        let containerBackground: UIColor
        let labelColor: UIColor
    }

    static func speedWarningStyle(filtered: [Transaction]) -> SpeedWarningStyle? {
        let income = filtered.filter { $0.type == "Income" }.reduce(0) { $0 + $1.amount }
        let expense = filtered.filter { $0.type == "Expense" }.reduce(0) { $0 + $1.amount }

        if let result = BudgetSpeedGuard.checkSpeed(totalIncome: income, totalExpense: expense) {
            let isDanger = result.isDanger
            return SpeedWarningStyle(
                message: result.message,
                containerBackground: isDanger
                    ? UIColor.systemRed.withAlphaComponent(0.12)
                    : UIColor.systemGreen.withAlphaComponent(0.12),
                labelColor: isDanger ? .systemRed : .systemGreen
            )
        }
        return SpeedWarningStyle(
            message: "ℹ️ Ushbu muddat uchun tranzaksiyalar yetarli emas.",
            containerBackground: .systemGray6,
            labelColor: .secondaryLabel
        )
    }

    static func buildPieChartData(filteredTransactions: [Transaction]) -> (data: PieChartData?, noDataText: String?) {
        let expenses = filteredTransactions.filter { $0.type == "Expense" }

        guard !expenses.isEmpty else {
            return (nil, "Ushbu muddatda xarajatlar yo'q")
        }

        let standardCategories = [
            "Oziq-ovqat", "Transport", "Ijara",
            "Kiyim-kechak", "O'yin-kulgi", "Salomatlik"
        ]
        let categoryColors: [String: UIColor] = [
            "Oziq-ovqat": .systemYellow,
            "Transport": .systemBlue,
            "Ijara": .systemGreen,
            "Kiyim-kechak": .systemOrange,
            "O'yin-kulgi": .systemPurple,
            "Salomatlik": .systemPink,
            "Boshqa": .systemGray
        ]

        var categoryTotals: [String: Double] = [:]
        for expense in expenses {
            let raw = expense.category ?? "Boshqa"
            let category = standardCategories.contains(raw) ? raw : "Boshqa"
            categoryTotals[category, default: 0] += expense.amount
        }

        var entries: [PieChartDataEntry] = []
        var chartColors: [UIColor] = []

        for (category, total) in categoryTotals.sorted(by: { $0.value > $1.value }) {
            entries.append(PieChartDataEntry(value: total, label: category))
            chartColors.append(categoryColors[category] ?? .systemGray)
        }

        let dataSet = PieChartDataSet(entries: entries, label: "")
        dataSet.colors = chartColors
        dataSet.drawValuesEnabled = false
        dataSet.sliceSpace = 2

        let chartData = PieChartData(dataSet: dataSet)
        return (chartData, nil)
    }
}
