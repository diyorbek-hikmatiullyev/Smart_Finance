// GoalViewModel.swift
// SmartFinance
// Byudjet rejasi uchun ViewModel
 
import Foundation
 
final class GoalViewModel {
 
    private(set) var plan: BudgetPlan?
    var onPlanChanged: (() -> Void)?
 
    // Kategoriya ikonlari (DashboardViewController+TableView bilan moslashtirilgan)
    static let categoryMeta: [(name: String, icon: String, color: String)] = [
        ("Oziq-ovqat",  "cart.fill",          "#34C759"),
        ("Transport",   "car.fill",            "#007AFF"),
        ("Ijara",       "house.fill",          "#30B0C7"),
        ("Kiyim",       "tshirt.fill",         "#AF52DE"),
        ("O'yin-kulgi", "gamecontroller.fill", "#FF9500"),
        ("Salomatlik",  "heart.fill",          "#FF3B30"),
        ("Boshqa",      "square.grid.2x2.fill","#8E8E93"),
    ]
 
    // MARK: - Load
 
    func load() {
        plan = BudgetPlanStorage.shared.load()
        syncSpentFromTransactions()
    }
 
    // MARK: - Tranzaksiyalardan "spent" ni yangilash
 
    func syncSpent(transactions: [Transaction]) {
        guard var p = plan else { return }
        guard !p.isExpired else { return }
 
        let filtered = transactions.filter { t in
            guard let date = t.date else { return false }
            return t.type == "Expense" &&
                   date >= p.startDate &&
                   date <= p.endDate
        }
 
        for i in p.categoryLimits.indices {
            let cat = p.categoryLimits[i].categoryName.lowercased()
            let spent = filtered
                .filter { ($0.category ?? "").lowercased().contains(cat) || cat.contains($0.category?.lowercased() ?? "") }
                .reduce(0) { $0 + $1.amount }
            p.categoryLimits[i].spent = spent
        }
 
        plan = p
        BudgetPlanStorage.shared.save(p)
        onPlanChanged?()
    }
 
    private func syncSpentFromTransactions() {
        // CoreData dan o'qish
        guard let uid = AuthSessionProvider.shared.currentUserID,
              let transactions = try? TransactionRepository.shared.fetchTransactions(forUserID: uid) else {
            return
        }
        syncSpent(transactions: transactions)
    }
 
    // MARK: - Save plan
 
    func savePlan(_ plan: BudgetPlan) {
        self.plan = plan
        BudgetPlanStorage.shared.save(plan)
        syncSpentFromTransactions()
        onPlanChanged?()
    }
 
    func deletePlan() {
        plan = nil
        BudgetPlanStorage.shared.delete()
        onPlanChanged?()
    }
 
    // MARK: - Ogohlantirishlar
 
    /// Foiz bo'yicha eng xavfli kategoriya
    var mostCriticalLimit: BudgetPlan.CategoryLimit? {
        plan?.categoryLimits.max(by: { $0.percentSpent < $1.percentSpent })
    }
 
    var overBudgetCategories: [BudgetPlan.CategoryLimit] {
        plan?.categoryLimits.filter { $0.isOverBudget } ?? []
    }
 
    var warningCategories: [BudgetPlan.CategoryLimit] {
        plan?.categoryLimits.filter { $0.percentSpent >= 80 && !$0.isOverBudget } ?? []
    }
}
