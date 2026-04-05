
//import UIKit
//import CoreData
//import DGCharts
//
//extension DashboardViewController {
//
//    // 📅 1. Segmentga qarab sanalarni qat'iy filtrlash funksiyasi
//    func filterTransactionsBySegment(_ transactions: [Transaction]) -> [Transaction] {
//        let calendar = Calendar.current
//        let now = Date()
//        
//        return transactions.filter { transaction in
//            guard let date = transaction.date else { return false }
//            
//            switch timeSegmentControl.selectedSegmentIndex {
//            case 0: // 🗓 Haftalik (Dushanbadan Yakshanbagacha)
//                return calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
//                
//            case 1: // 🗓 Oylik (Faqat joriy oy tranzaksiyalari)
//                return calendar.isDate(date, equalTo: now, toGranularity: .month)
//                
//            case 2: // 🗓 Yillik (Faqat joriy yil tranzaksiyalari)
//                return calendar.isDate(date, equalTo: now, toGranularity: .year)
//                
//            default:
//                return false
//            }
//        }
//    }
//
//    // 📊 2. Diagrammani yangilash (Segmentga qarab)
//    func updateChartData() {
//        // Faqat tanlangan segmentdagi ma'lumotlarni olamiz:
//        let filteredTransactions = filterTransactionsBySegment(allTransactionsForChart)
//        let expenses = filteredTransactions.filter { $0.type == "Expense" }
//        
//        // Agar bu segmentda xarajat bo'lmasa, diagrammani tozalaymiz
//        if expenses.isEmpty {
//            pieChartView.data = nil
//            pieChartView.noDataText = "Ushbu muddatda xarajatlar yo'q"
//            return
//        }
//        
//        let standardCategories = ["Oziq-ovqat", "Transport", "Ijara", "Kiyim-kechak", "O'yin-kulgi", "Salomatlik"]
//        let categoryColors: [String: UIColor] = [
//            "Oziq-ovqat": .systemYellow, "Transport": .systemBlue, "Ijara": .systemGreen,
//            "Kiyim-kechak": .systemOrange, "O'yin-kulgi": .systemPurple, "Salomatlik": .systemPink, "Boshqa": .systemGray
//        ]
//        
//        var categoryTotals: [String: Double] = [:]
//        for expense in expenses {
//            let category = expense.category ?? "Boshqa"
//            let finalCategory = standardCategories.contains(category) ? category : "Boshqa"
//            categoryTotals[finalCategory, default: 0] += expense.amount
//        }
//        
//        var entries: [PieChartDataEntry] = []
//        var chartColors: [UIColor] = []
//        
//        for (category, total) in categoryTotals {
//            entries.append(PieChartDataEntry(value: total, label: category))
//            chartColors.append(categoryColors[category] ?? .systemGray)
//        }
//        
//        let dataSet = PieChartDataSet(entries: entries, label: "")
//        dataSet.colors = chartColors
//        dataSet.drawValuesEnabled = false
//        
//        pieChartView.data = PieChartData(dataSet: dataSet)
//        pieChartView.animate(xAxisDuration: 0.8, yAxisDuration: 0.8)
//    }
//
//    // ⚖️ 3. Balansni yangilash (Segmentga qarab)
//    func calculateBalance() {
//        let filteredTransactions = filterTransactionsBySegment(allTransactionsForChart)
//        
//        let income = filteredTransactions.filter { $0.type == "Income" }.reduce(0) { $0 + $1.amount }
//        let expense = filteredTransactions.filter { $0.type == "Expense" }.reduce(0) { $0 + $1.amount }
//        let total = income - expense
//        
//        balanceLabel.text = "\(Int(total)) so'm"
//        
//        if total > 0 {
//            balanceLabel.textColor = .systemGreen
//        } else if total < 0 {
//            balanceLabel.textColor = .systemRed
//        } else {
//            balanceLabel.textColor = .label
//        }
//        
//        if let result = BudgetSpeedGuard.checkSpeed(totalIncome: income, totalExpense: expense) {
//            speedWarningLabel.text = result.message
//            warningContainerView.backgroundColor = result.isDanger ? .systemRed.withAlphaComponent(0.12) : .systemGreen.withAlphaComponent(0.12)
//            speedWarningLabel.textColor = result.isDanger ? .systemRed : .systemGreen
//        } else {
//            speedWarningLabel.text = "ℹ️ Ushbu muddat uchun tranzaksiyalar yetarli emas."
//            warningContainerView.backgroundColor = .systemGray6
//            speedWarningLabel.textColor = .secondaryLabel
//        }
//    }
//}


import UIKit
import CoreData
import DGCharts

extension DashboardViewController {

    // MARK: - Segment bo'yicha filtrlash
    func filterTransactionsBySegment(_ transactions: [Transaction]) -> [Transaction] {
        let calendar = Calendar.current
        let now = Date()

        return transactions.filter { transaction in
            guard let date = transaction.date else { return false }
            switch timeSegmentControl.selectedSegmentIndex {
            case 0: return calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
            case 1: return calendar.isDate(date, equalTo: now, toGranularity: .month)
            case 2: return calendar.isDate(date, equalTo: now, toGranularity: .year)
            default: return false
            }
        }
    }

    // MARK: - ✅ TUZATILGAN: Chart yangilash
    func updateChartData() {
        let filteredTransactions = filterTransactionsBySegment(allTransactionsForChart)
        let expenses = filteredTransactions.filter { $0.type == "Expense" }

        guard !expenses.isEmpty else {
            // Ma'lumot yo'q — chartni tozalash
            pieChartView.data = nil
            pieChartView.noDataText = "Ushbu muddatda xarajatlar yo'q"
            // ✅ Muhim: notifyDataSetChanged o'rniga clear state uchun layout
            pieChartView.setNeedsDisplay()
            return
        }

        let standardCategories = [
            "Oziq-ovqat", "Transport", "Ijara",
            "Kiyim-kechak", "O'yin-kulgi", "Salomatlik"
        ]
        let categoryColors: [String: UIColor] = [
            "Oziq-ovqat":    .systemYellow,
            "Transport":     .systemBlue,
            "Ijara":         .systemGreen,
            "Kiyim-kechak":  .systemOrange,
            "O'yin-kulgi":   .systemPurple,
            "Salomatlik":    .systemPink,
            "Boshqa":        .systemGray
        ]

        var categoryTotals: [String: Double] = [:]
        for expense in expenses {
            let raw = expense.category ?? "Boshqa"
            let category = standardCategories.contains(raw) ? raw : "Boshqa"
            categoryTotals[category, default: 0] += expense.amount
        }

        var entries: [PieChartDataEntry] = []
        var chartColors: [UIColor] = []

        // Tartiblangan holda ko'rsatish (kattadan kichikka)
        for (category, total) in categoryTotals.sorted(by: { $0.value > $1.value }) {
            entries.append(PieChartDataEntry(value: total, label: category))
            chartColors.append(categoryColors[category] ?? .systemGray)
        }

        let dataSet = PieChartDataSet(entries: entries, label: "")
        dataSet.colors = chartColors
        dataSet.drawValuesEnabled = false
        dataSet.sliceSpace = 2

        let chartData = PieChartData(dataSet: dataSet)
        pieChartView.data = chartData

        // ✅ TUZATILDI: notifyDataSetChanged + layout majburlash
        // Bu "bosgandan keyin ko'rinish" xatosini bartaraf etadi
        pieChartView.data?.notifyDataChanged()
        pieChartView.notifyDataSetChanged()
        pieChartView.setNeedsLayout()
        pieChartView.layoutIfNeeded()

        pieChartView.animate(xAxisDuration: 0.6, yAxisDuration: 0.6, easingOption: .easeInOutQuad)
    }

    // MARK: - Balans hisoblash
    func calculateBalance() {
        let filtered = filterTransactionsBySegment(allTransactionsForChart)

        let income  = filtered.filter { $0.type == "Income"  }.reduce(0) { $0 + $1.amount }
        let expense = filtered.filter { $0.type == "Expense" }.reduce(0) { $0 + $1.amount }
        let total   = income - expense

        balanceLabel.text = "\(Int(total)) so'm"
        balanceLabel.textColor = total >= 0 ? .systemGreen : .systemRed

        if let result = BudgetSpeedGuard.checkSpeed(totalIncome: income, totalExpense: expense) {
            speedWarningLabel.text = result.message
            let isDanger = result.isDanger
            warningContainerView.backgroundColor = isDanger
                ? UIColor.systemRed.withAlphaComponent(0.12)
                : UIColor.systemGreen.withAlphaComponent(0.12)
            speedWarningLabel.textColor = isDanger ? .systemRed : .systemGreen
        } else {
            speedWarningLabel.text = "ℹ️ Ushbu muddat uchun tranzaksiyalar yetarli emas."
            warningContainerView.backgroundColor = .systemGray6
            speedWarningLabel.textColor = .secondaryLabel
        }
    }
}
