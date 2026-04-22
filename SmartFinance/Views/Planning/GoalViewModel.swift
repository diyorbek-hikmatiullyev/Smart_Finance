// GoalViewModel.swift
// SmartFinance
// Byudjet rejasi uchun ViewModel
 
import Foundation
 
final class GoalViewModel {
 
    private(set) var plan: BudgetPlan?
    var onPlanChanged: (() -> Void)?
    private let repo: BudgetPlanRepositoryProtocol
    private let auth: AuthSessionProviding
 
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

    init(repo: BudgetPlanRepositoryProtocol = BudgetPlanRepository.shared,
         auth: AuthSessionProviding = AuthSessionProvider.shared) {
        self.repo = repo
        self.auth = auth
    }

    deinit {
        repo.stopRemoteSync()
    }
 
    // MARK: - Load
 
    func load() {
        guard let uid = auth.currentUserID else {
            plan = nil
            onPlanChanged?()
            return
        }

        repo.loadPlan(forUserID: uid) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let loaded):
                self.plan = loaded
                self.syncSpentFromTransactions(shouldPersist: false)
                DispatchQueue.main.async { self.onPlanChanged?() }
            case .failure(let error):
                print("BudgetPlan load error: \(error.localizedDescription)")
            }
        }

        repo.startRemoteSync(forUserID: uid) { [weak self] remotePlan in
            guard let self = self else { return }
            self.plan = remotePlan
            self.syncSpentFromTransactions(shouldPersist: false)
            self.onPlanChanged?()
        }
    }
 
    // MARK: - Tranzaksiyalardan "spent" ni yangilash
 
    func syncSpent(transactions: [Transaction]) {
        syncSpent(transactions: transactions, shouldPersist: true)
    }

    private func syncSpent(transactions: [Transaction], shouldPersist: Bool) {
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
 
        let hasChanged = p.categoryLimits.map(\.spent) != plan?.categoryLimits.map(\.spent)
        plan = p
        if hasChanged && shouldPersist {
            persistPlanToRemoteAndCache(p)
        }
    }
 
    private func syncSpentFromTransactions(shouldPersist: Bool) {
        // CoreData dan o'qish
        guard let uid = auth.currentUserID,
              let transactions = try? TransactionRepository.shared.fetchTransactions(forUserID: uid) else {
            return
        }
        syncSpent(transactions: transactions, shouldPersist: shouldPersist)
    }
 
    // MARK: - Save plan
 
    func savePlan(_ plan: BudgetPlan) {
        self.plan = plan
        persistPlanToRemoteAndCache(plan)
        syncSpentFromTransactions(shouldPersist: true)
        onPlanChanged?()
    }
 
    func deletePlan() {
        guard let uid = auth.currentUserID else { return }
        plan = nil
        repo.deletePlan(forUserID: uid) { error in
            if let error = error {
                print("BudgetPlan delete error: \(error.localizedDescription)")
            }
        }
        onPlanChanged?()
    }

    private func persistPlanToRemoteAndCache(_ plan: BudgetPlan) {
        guard let uid = auth.currentUserID else { return }
        repo.savePlan(plan, forUserID: uid) { error in
            if let error = error {
                print("BudgetPlan save error: \(error.localizedDescription)")
            }
        }
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
