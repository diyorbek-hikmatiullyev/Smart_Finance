// GoalViewModel.swift
// SmartFinance
// Byudjet rejasi uchun ViewModel — Firestore yuklanishi tuzatildi
 
// GoalViewModel.swift
// SmartFinance
// TransactionRepository pattern — viewWillAppear da sync, listener bilan
 
import Foundation
 
final class GoalViewModel {
 
    private(set) var plan: BudgetPlan?
    var onPlanChanged: (() -> Void)?
 
    private let repo: BudgetPlanRepositoryProtocol
    private let auth: AuthSessionProviding
 
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
 
    // MARK: - Load (xuddi TransactionRepository.startRemoteSync + fetchTransactions)
 
    func load() {
        guard let uid = auth.currentUserID else {
            plan = nil
            onPlanChanged?()
            return
        }
 
        // 1. Local + Firestore one-shot
        repo.loadPlan(forUserID: uid) { [weak self] result in
            guard let self = self else { return }
            if case .success(let loaded) = result {
                self.plan = loaded
                self.syncSpentFromTransactions(shouldPersist: false)
                DispatchQueue.main.async { self.onPlanChanged?() }
            }
        }
 
        // 2. Real-time listener — xuddi TransactionRepository.startRemoteSync kabi
        repo.startRemoteSync(forUserID: uid) { [weak self] remotePlan in
            guard let self = self else { return }
            self.plan = remotePlan
            self.syncSpentFromTransactions(shouldPersist: false)
            self.onPlanChanged?()
        }
    }
 
    func stopSync() {
        repo.stopRemoteSync()
    }
 
    // MARK: - Sync spent from transactions
 
    func syncSpent(transactions: [Transaction]) {
        syncSpent(transactions: transactions, shouldPersist: true)
    }
 
    private func syncSpent(transactions: [Transaction], shouldPersist: Bool) {
        guard var p = plan, !p.isExpired else { return }
 
        let filtered = transactions.filter { t in
            guard let date = t.date else { return false }
            return t.type == "Expense" && date >= p.startDate && date <= p.endDate
        }
 
        for i in p.categoryLimits.indices {
            let cat = p.categoryLimits[i].categoryName.lowercased()
            let spent = filtered
                .filter {
                    let tCat = ($0.category ?? "").lowercased()
                    return tCat.contains(cat) || cat.contains(tCat)
                }
                .reduce(0) { $0 + $1.amount }
            p.categoryLimits[i].spent = spent
        }
 
        let hasChanged = p.categoryLimits.map(\.spent) != plan?.categoryLimits.map(\.spent)
        plan = p
        if hasChanged && shouldPersist {
            persistPlan(p)
        }
    }
 
    private func syncSpentFromTransactions(shouldPersist: Bool) {
        guard let uid = auth.currentUserID,
              let transactions = try? TransactionRepository.shared.fetchTransactions(forUserID: uid)
        else { return }
        syncSpent(transactions: transactions, shouldPersist: shouldPersist)
    }
 
    // MARK: - Save / Delete
 
    func savePlan(_ plan: BudgetPlan) {
        self.plan = plan
        persistPlan(plan)
        syncSpentFromTransactions(shouldPersist: true)
        onPlanChanged?()
    }
 
    func deletePlan() {
        guard let uid = auth.currentUserID else { return }
        plan = nil
        repo.deletePlan(forUserID: uid) { _ in }
        onPlanChanged?()
    }
 
    private func persistPlan(_ plan: BudgetPlan) {
        guard let uid = auth.currentUserID else { return }
        repo.savePlan(plan, forUserID: uid) { error in
            if let error = error {
                print("❌ BudgetPlan persist: \(error.localizedDescription)")
            }
        }
    }
 
    // MARK: - Computed
 
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
