// BudgetPlanRepository.swift
// SmartFinance
// TransactionRepository pattern — Firestore listener + local cache
 
import Foundation
import FirebaseFirestore
 
protocol BudgetPlanRepositoryProtocol: AnyObject {
    func loadPlan(forUserID uid: String, completion: @escaping (Result<BudgetPlan?, Error>) -> Void)
    func savePlan(_ plan: BudgetPlan, forUserID uid: String, completion: @escaping (Error?) -> Void)
    func deletePlan(forUserID uid: String, completion: @escaping (Error?) -> Void)
    func startRemoteSync(forUserID uid: String, onChange: @escaping (BudgetPlan?) -> Void)
    func stopRemoteSync()
}
 
final class BudgetPlanRepository: BudgetPlanRepositoryProtocol {
    static let shared = BudgetPlanRepository()
 
    private let db: Firestore
    private let cache: BudgetPlanStorage
    private var listener: ListenerRegistration?
 
    init(db: Firestore = .firestore(), cache: BudgetPlanStorage = .shared) {
        self.db = db
        self.cache = cache
    }
 
    // MARK: - Load
 
    func loadPlan(forUserID uid: String, completion: @escaping (Result<BudgetPlan?, Error>) -> Void) {
        // 1. Darhol local cache dan qaytarish (TransactionRepository.fetchTransactions kabi)
        if let cached = cache.load(for: uid) {
            completion(.success(cached))
        }
 
        // 2. Firestore dan yangilash
        db.collection("budgetPlans").document(uid).getDocument { [weak self] snapshot, error in
            if let error = error {
                print("❌ BudgetPlan getDocument: \(error.localizedDescription)")
                if self?.cache.load(for: uid) == nil {
                    completion(.failure(error))
                }
                return
            }
 
            guard let data = snapshot?.data(), !data.isEmpty else {
                self?.migrateLegacyIfNeeded(forUserID: uid, completion: completion)
                return
            }
 
            guard let parsed = Self.decode(data) else {
                completion(.success(self?.cache.load(for: uid)))
                return
            }
 
            self?.cache.save(parsed, for: uid)
            self?.cache.deleteLegacy()
            completion(.success(parsed))
        }
    }
 
    // MARK: - Save
 
    func savePlan(_ plan: BudgetPlan, forUserID uid: String, completion: @escaping (Error?) -> Void) {
        // 1. Darhol local ga yoz
        cache.save(plan, for: uid)
 
        // 2. Firestore ga yuborish
        db.collection("budgetPlans").document(uid).setData(Self.encode(plan, userID: uid)) { error in
            if let error = error {
                print("❌ BudgetPlan setData: \(error.localizedDescription)")
            }
            completion(error)
        }
    }
 
    // MARK: - Delete
 
    func deletePlan(forUserID uid: String, completion: @escaping (Error?) -> Void) {
        cache.delete(for: uid)
        cache.deleteLegacy()
        db.collection("budgetPlans").document(uid).delete { error in
            completion(error)
        }
    }
 
    // MARK: - Real-time Sync (xuddi TransactionRepository.startRemoteSync)
 
    func startRemoteSync(forUserID uid: String, onChange: @escaping (BudgetPlan?) -> Void) {
        listener?.remove()
        listener = db.collection("budgetPlans").document(uid)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("❌ BudgetPlan listener: \(error.localizedDescription)")
                    return
                }
 
                guard let data = snapshot?.data(), !data.isEmpty else {
                    self?.cache.delete(for: uid)
                    DispatchQueue.main.async { onChange(nil) }
                    return
                }
 
                guard let parsed = Self.decode(data) else { return }
                self?.cache.save(parsed, for: uid)
                self?.cache.deleteLegacy()
                DispatchQueue.main.async { onChange(parsed) }
            }
    }
 
    func stopRemoteSync() {
        listener?.remove()
        listener = nil
    }
 
    // MARK: - Migration
 
    private func migrateLegacyIfNeeded(forUserID uid: String,
                                       completion: @escaping (Result<BudgetPlan?, Error>) -> Void) {
        guard let legacy = cache.loadLegacy() else {
            completion(.success(nil))
            return
        }
        savePlan(legacy, forUserID: uid) { [weak self] error in
            self?.cache.deleteLegacy()
            completion(.success(error == nil ? legacy : nil))
        }
    }
 
    // MARK: - Encode / Decode
 
    static func encode(_ plan: BudgetPlan, userID: String) -> [String: Any] {
        [
            "id"             : plan.id,
            "userID"         : userID,
            "totalAmount"    : plan.totalAmount,
            "startDate"      : Timestamp(date: plan.startDate),
            "endDate"        : Timestamp(date: plan.endDate),
            "createdAt"      : Timestamp(date: plan.createdAt),
            "categoryLimits" : plan.categoryLimits.map { [
                "id"           : $0.id,
                "categoryName" : $0.categoryName,
                "limitAmount"  : $0.limitAmount,
                "spent"        : $0.spent
            ] as [String: Any] }
        ]
    }
 
    static func decode(_ data: [String: Any]) -> BudgetPlan? {
        guard let total = data["totalAmount"] as? Double else { return nil }
        let id        = data["id"]        as? String ?? UUID().uuidString
        let startDate = (data["startDate"] as? Timestamp)?.dateValue() ?? Date()
        let endDate   = (data["endDate"]   as? Timestamp)?.dateValue() ?? Date()
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let limits    = (data["categoryLimits"] as? [[String: Any]] ?? []).compactMap { d -> BudgetPlan.CategoryLimit? in
            guard let name = d["categoryName"] as? String else { return nil }
            return BudgetPlan.CategoryLimit(
                id           : d["id"]          as? String ?? UUID().uuidString,
                categoryName : name,
                limitAmount  : d["limitAmount"] as? Double ?? 0,
                spent        : d["spent"]       as? Double ?? 0
            )
        }
        return BudgetPlan(id: id, totalAmount: total, startDate: startDate,
                          endDate: endDate, categoryLimits: limits, createdAt: createdAt)
    }
}
