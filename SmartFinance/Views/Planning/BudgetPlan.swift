// BudgetPlan.swift
// SmartFinance
// Byudjet rejasi modeli — kategoriya limitleri + muddat
 
import Foundation
 
// MARK: - BudgetPlan
 
struct BudgetPlan: Codable {
    var id: String
    var totalAmount: Double          // Umumiy ajratilgan pul
    var startDate: Date
    var endDate: Date
    var categoryLimits: [CategoryLimit]
    var createdAt: Date
 
    struct CategoryLimit: Codable {
        var id: String
        var categoryName: String
        var limitAmount: Double      // So'mda
        var spent: Double            // Hozircha sarflangan
 
        var remaining: Double { limitAmount - spent }
        var percentSpent: Double {
            guard limitAmount > 0 else { return 0 }
            return min((spent / limitAmount) * 100, 100)
        }
        var isOverBudget: Bool { spent > limitAmount }
 
        init(id: String = UUID().uuidString,
             categoryName: String,
             limitAmount: Double,
             spent: Double = 0) {
            self.id = id
            self.categoryName = categoryName
            self.limitAmount = limitAmount
            self.spent = spent
        }
    }
 
    // Jami ajratilgan limitlar yig'indisi
    var totalAllocated: Double {
        categoryLimits.reduce(0) { $0 + $1.limitAmount }
    }
 
    // Qolgan (taqsimlanmagan) pul
    var unallocated: Double {
        totalAmount - totalAllocated
    }
 
    // Muddat qolgan kunlar
    var remainingDays: Int {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
        return max(0, days)
    }
 
    // Muddat o'tib ketganmi?
    var isExpired: Bool { Date() > endDate }
 
    // Muddat nechchi kun?
    var totalDays: Int {
        let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        return max(1, days)
    }
 
    // O'tgan kunlar foizi
    var timeProgressPercent: Double {
        let elapsed = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        return min(Double(max(0, elapsed)) / Double(totalDays) * 100, 100)
    }
 
    init(
        id: String = UUID().uuidString,
        totalAmount: Double,
        startDate: Date = Date(),
        endDate: Date,
        categoryLimits: [CategoryLimit] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.totalAmount = totalAmount
        self.startDate = startDate
        self.endDate = endDate
        self.categoryLimits = categoryLimits
        self.createdAt = createdAt
    }
}
 
// MARK: - BudgetPlanStorage (UserDefaults)
 
final class BudgetPlanStorage {
    static let shared = BudgetPlanStorage()
    private init() {}
    private let key = "sf_budget_plan_v2"
 
    func save(_ plan: BudgetPlan) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        if let data = try? encoder.encode(plan) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
 
    func load() -> BudgetPlan? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try? decoder.decode(BudgetPlan.self, from: data)
    }
 
    func delete() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
