//
//  BudgetSpeedGuard.swift
//  SmartFinance
//
//  Created by Diyorbek Xikmatullayev on 27/03/26.
//

import Foundation

struct BudgetSpeedGuard {
    
    static func checkSpeed(totalIncome: Double, totalExpense: Double) -> (message: String, isDanger: Bool)? {
        let calendar = Calendar.current
        let now = Date()
        
        guard let dayOfMonth = calendar.dateComponents([.day], from: now).day,
              let range = calendar.range(of: .day, in: .month, for: now) else { return nil }
        
        let totalDaysInMonth = range.count
        let remainingDays = totalDaysInMonth - dayOfMonth + 1
        
        // 🚨 1-Qoida: Agar balans minus bo'lsa
        let currentBalance = totalIncome - totalExpense
        if currentBalance < 0 {
            return (message: "🚨 Balansingiz minusda (\(Int(currentBalance)) so'm)! Xarajatlarni to'xtating va daromadni oshiring.", isDanger: true)
        }
        
        guard remainingDays > 0 else { return nil }
        let dynamicDailyLimit = currentBalance / Double(remainingDays)
        
        if totalExpense == 0 {
            return (message: "✅ Bugungi yangi kunlik limit: \(Int(dynamicDailyLimit)) so'm. Xarid qilishni boshlashingiz mumkin.", isDanger: false)
        }
        
        let averageDailyExpense = totalExpense / Double(dayOfMonth)
        
        // 🛑 2-Qoida: O'rtacha xarajat yangi limitdan katta bo'lsa
        if averageDailyExpense > dynamicDailyLimit {
            let predictedDaysLeft = Int(currentBalance / averageDailyExpense)
            return (message: "⚠️ Shu tezlikda ketsangiz, mavjud pulingiz \(predictedDaysLeft) kunda tugaydi. Limit: \(Int(dynamicDailyLimit)) so'm.", isDanger: true)
        }
        
        return (message: "✅ Xarajat me'yorda. Bugungi yangi kunlik limit: \(Int(dynamicDailyLimit)) so'm.", isDanger: false)
    }
}
