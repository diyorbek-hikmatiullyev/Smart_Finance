// MonthlyGoal.swift
// SmartFinance
// Oylik tejash maqsadi modeli

import Foundation

struct MonthlyGoal: Codable {
    let id: String
    let userID: String
    let targetAmount: Double       // Maqsad summa (so'm)
    let month: Int                 // 1-12
    let year: Int                  // 2024, 2025...
    let createdAt: Date
    var note: String?              // Ixtiyoriy izoh

    // MARK: - Computed

    /// Joriy oyning maqsadimi?
    var isCurrentMonth: Bool {
        let calendar = Calendar.current
        let now = Date()
        return calendar.component(.month, from: now) == month &&
               calendar.component(.year,  from: now) == year
    }

    /// Oy nomi (o'zbek tilida)
    var monthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uz_UZ")
        formatter.dateFormat = "MMMM"
        var components = DateComponents()
        components.month = month
        components.year  = year
        components.day   = 1
        let date = Calendar.current.date(from: components) ?? Date()
        let raw = formatter.string(from: date)
        return raw.prefix(1).uppercased() + raw.dropFirst()
    }

    // MARK: - Firestore mapping

    var firestoreData: [String: Any] {
        return [
            "id"           : id,
            "userID"       : userID,
            "targetAmount" : targetAmount,
            "month"        : month,
            "year"         : year,
            "createdAt"    : createdAt,
            "note"         : note ?? ""
        ]
    }

    static func from(_ data: [String: Any]) -> MonthlyGoal? {
        guard
            let id           = data["id"]           as? String,
            let userID       = data["userID"]        as? String,
            let targetAmount = data["targetAmount"]  as? Double,
            let month        = data["month"]         as? Int,
            let year         = data["year"]          as? Int
        else { return nil }

        let createdAt = (data["createdAt"] as? Date) ?? Date()
        let note      = data["note"] as? String

        return MonthlyGoal(
            id:           id,
            userID:       userID,
            targetAmount: targetAmount,
            month:        month,
            year:         year,
            createdAt:    createdAt,
            note:         note
        )
    }
}

// MARK: - GoalProgress — hisoblangan natija

struct GoalProgress {
    let goal: MonthlyGoal
    let currentSaved: Double       // Hozirgi tejash (income - expense)
    let totalIncome: Double
    let totalExpense: Double

    /// 0.0 — 1.0 orasida progress
    var progressRatio: Double {
        guard goal.targetAmount > 0 else { return 0 }
        return min(currentSaved / goal.targetAmount, 1.0)
    }

    /// Foiz (0-100)
    var progressPercent: Int {
        Int(progressRatio * 100)
    }

    /// Maqsadga qancha qoldi
    var remaining: Double {
        max(goal.targetAmount - currentSaved, 0)
    }

    /// Maqsadga yetildimi?
    var isCompleted: Bool {
        currentSaved >= goal.targetAmount
    }

    /// Oyda qancha kun qolgan
    var daysLeftInMonth: Int {
        let calendar = Calendar.current
        let now = Date()
        guard let range = calendar.range(of: .day, in: .month, for: now),
              let day = calendar.dateComponents([.day], from: now).day
        else { return 0 }
        return range.count - day
    }

    /// Kunlik tejash kerak bo'lgan miqdor
    var dailySavingNeeded: Double {
        guard daysLeftInMonth > 0, remaining > 0 else { return 0 }
        return remaining / Double(daysLeftInMonth)
    }
}
