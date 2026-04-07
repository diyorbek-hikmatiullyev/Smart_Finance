// GoalViewModel.swift
// SmartFinance
// Maqsad logic va progress hisoblash

import Foundation

final class GoalViewModel {

    // MARK: - Dependencies
    private let goalRepo: GoalRepositoryProtocol
    private let auth: AuthSessionProviding

    // MARK: - State
    private(set) var currentGoal: MonthlyGoal?
    private(set) var progress: GoalProgress?

    var onStateChanged: (() -> Void)?

    // MARK: - Init
    init(
        goalRepo: GoalRepositoryProtocol = GoalRepository.shared,
        auth: AuthSessionProviding = AuthSessionProvider.shared
    ) {
        self.goalRepo = goalRepo
        self.auth = auth
    }

    // MARK: - Load

    func loadGoal(transactions: [Transaction]) {
        guard let uid = auth.currentUserID else { return }

        goalRepo.fetchCurrentMonthGoal(userID: uid) { [weak self] goal in
            DispatchQueue.main.async {
                self?.currentGoal = goal
                self?.recalculate(transactions: transactions)
                self?.onStateChanged?()
            }
        }
    }

    // MARK: - Hisoblash

    func recalculate(transactions: [Transaction]) {
        guard let goal = currentGoal else {
            progress = nil
            return
        }

        // Faqat shu oyning tranzaksiyalari
        let calendar = Calendar.current
        let filtered = transactions.filter { t in
            guard let date = t.date else { return false }
            return calendar.component(.month, from: date) == goal.month &&
                   calendar.component(.year,  from: date) == goal.year
        }

        let income  = filtered.filter { $0.type == "Income"  }.reduce(0) { $0 + $1.amount }
        let expense = filtered.filter { $0.type == "Expense" }.reduce(0) { $0 + $1.amount }
        let saved   = income - expense

        progress = GoalProgress(
            goal:         goal,
            currentSaved: max(saved, 0),
            totalIncome:  income,
            totalExpense: expense
        )
    }

    // MARK: - Save yangi maqsad

    func saveGoal(targetAmount: Double, note: String?, completion: @escaping (Error?) -> Void) {
        guard let uid = auth.currentUserID, targetAmount > 0 else {
            completion(nil); return
        }

        let calendar = Calendar.current
        let now      = Date()

        let goal = MonthlyGoal(
            id:           UUID().uuidString,
            userID:       uid,
            targetAmount: targetAmount,
            month:        calendar.component(.month, from: now),
            year:         calendar.component(.year,  from: now),
            createdAt:    now,
            note:         note
        )

        goalRepo.saveGoal(goal) { [weak self] error in
            if error == nil {
                self?.currentGoal = goal
                self?.onStateChanged?()
            }
            completion(error)
        }
    }

    // MARK: - Delete

    func deleteGoal(completion: @escaping (Error?) -> Void) {
        guard let goal = currentGoal else { completion(nil); return }
        goalRepo.deleteGoal(goal) { [weak self] error in
            if error == nil {
                self?.currentGoal = nil
                self?.progress    = nil
                self?.onStateChanged?()
            }
            completion(error)
        }
    }

    // MARK: - Smart Banner ma'lumoti

    /// BudgetSpeedGuard + Goal birgalikda — foydalanuvchiga eng foydali xabar
    func smartBannerInfo(transactions: [Transaction]) -> SmartBannerInfo {
        let calendar = Calendar.current
        let now      = Date()

        let monthly = transactions.filter { t in
            guard let date = t.date else { return false }
            return calendar.isDate(date, equalTo: now, toGranularity: .month)
        }

        let income  = monthly.filter { $0.type == "Income"  }.reduce(0) { $0 + $1.amount }
        let expense = monthly.filter { $0.type == "Expense" }.reduce(0) { $0 + $1.amount }
        let balance = income - expense

        // Qancha kun qolgan
        guard let range = calendar.range(of: .day, in: .month, for: now),
              let dayOfMonth = calendar.dateComponents([.day], from: now).day else {
            return SmartBannerInfo(type: .safe, mainMessage: "✅ Moliyaviy ahvol yaxshi", suggestions: [])
        }

        let totalDays     = range.count
        let remainingDays = totalDays - dayOfMonth + 1
        let avgDailyExp   = dayOfMonth > 0 ? expense / Double(dayOfMonth) : 0
        let dailyLimit    = remainingDays > 0 ? balance / Double(remainingDays) : 0

        // Suggestions — konkret tavsiyalar
        var suggestions: [String] = []

        // Top xarajat kategoriyasi
        var categoryTotals: [String: Double] = [:]
        for t in monthly where t.type == "Expense" {
            let cat = t.category ?? "Boshqa"
            categoryTotals[cat, default: 0] += t.amount
        }
        if let topCat = categoryTotals.max(by: { $0.value < $1.value }) {
            let percent = expense > 0 ? Int((topCat.value / expense) * 100) : 0
            suggestions.append("'\(topCat.key)' ga \(percent)% sarfladingiz — \(formatSum(topCat.value)) so'm")
        }

        // Kunlik tejash tavsiyasi
        if avgDailyExp > dailyLimit && dailyLimit > 0 {
            let cutNeeded = avgDailyExp - dailyLimit
            suggestions.append("Kunlik xarajatni \(formatSum(cutNeeded)) so'm kamaytirsangiz, pul oyga yetadi")
        }

        // Goal tavsiyasi
        if let goal = currentGoal, let progress = progress {
            if !progress.isCompleted {
                suggestions.append("Maqsadga yetish uchun kuniga \(formatSum(progress.dailySavingNeeded)) so'm tejang")
            }
        } else {
            suggestions.append("Oylik maqsad qo'ying — sarfni nazorat qilish osonlashadi")
        }

        // Banner turi
        let bannerType: SmartBannerType
        if balance < 0 {
            bannerType = .danger
        } else if avgDailyExp > dailyLimit {
            bannerType = .warning
        } else {
            bannerType = .safe
        }

        // Asosiy xabar
        let mainMessage: String
        switch bannerType {
        case .danger:
            mainMessage = "🚨 Balansingiz manfiy — \(formatSum(abs(balance))) so'm minus"
        case .warning:
            let days = dailyLimit > 0 ? Int(balance / avgDailyExp) : 0
            mainMessage = "⚠️ Shu tezlikda \(days) kunda tugaydi • Limit: \(formatSum(dailyLimit))/kun"
        case .safe:
            mainMessage = "✅ Kunlik limit: \(formatSum(dailyLimit)) so'm • Yaxshi davom eting"
        }

        return SmartBannerInfo(
            type:        bannerType,
            mainMessage: mainMessage,
            suggestions: suggestions
        )
    }

    // MARK: - Helper
    private func formatSum(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle       = .decimal
        f.groupingSeparator = " "
        f.maximumFractionDigits = 0
        return (f.string(from: NSNumber(value: value)) ?? "\(Int(value))")
    }
}

// MARK: - SmartBannerInfo model

enum SmartBannerType {
    case safe, warning, danger
}

struct SmartBannerInfo {
    let type: SmartBannerType
    let mainMessage: String
    let suggestions: [String]
}

