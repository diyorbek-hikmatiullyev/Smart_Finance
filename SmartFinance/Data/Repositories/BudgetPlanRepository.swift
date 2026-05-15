
 
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
 
    // MARK: - Load (Local + Firestore)
 
    func loadPlan(forUserID uid: String, completion: @escaping (Result<BudgetPlan?, Error>) -> Void) {
        // 1. Darhol local cache dan qaytarish
        if let cached = cache.load(for: uid) {
            completion(.success(cached))
        }
 
        // 2. Firestore dan yangilash
        db.collection("budgetPlans").document(uid).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
 
            if let error = error {
                print("❌ BudgetPlan getDocument: \(error.localizedDescription)")
                if self.cache.load(for: uid) == nil {
                    completion(.failure(error))
                }
                return
            }
 
            guard let data = snapshot?.data(), !data.isEmpty else {
                // Firestore da yo'q — legacy ni tekshirish
                self.migrateLegacyIfNeeded(forUserID: uid, completion: completion)
                return
            }
 
            guard let parsed = Self.decode(data) else {
                completion(.success(self.cache.load(for: uid)))
                return
            }
 
            self.cache.save(parsed, for: uid)
            self.cache.deleteLegacy()
            completion(.success(parsed))
        }
    }
 
    // MARK: - Save (Local + Firestore)
 
    func savePlan(_ plan: BudgetPlan, forUserID uid: String, completion: @escaping (Error?) -> Void) {
        // 1. Darhol local ga yoz
        cache.save(plan, for: uid)
 
        // 2. Firestore ga yuborish (setData — yangi bo'lsa yaratadi, mavjud bo'lsa to'liq almashtiradi)
        let data = Self.encode(plan, userID: uid)
        db.collection("budgetPlans").document(uid).setData(data) { error in
            if let error = error {
                print("❌ BudgetPlan setData: \(error.localizedDescription)")
            } else {
                print("✅ BudgetPlan Firestore ga saqlandi: \(uid)")
            }
            completion(error)
        }
    }
 
    // MARK: - Delete (Local + Firestore)
 
    func deletePlan(forUserID uid: String, completion: @escaping (Error?) -> Void) {
        cache.delete(for: uid)
        cache.deleteLegacy()
 
        db.collection("budgetPlans").document(uid).delete { error in
            if let error = error {
                print("❌ BudgetPlan delete: \(error.localizedDescription)")
            } else {
                print("✅ BudgetPlan Firestore dan o'chirildi: \(uid)")
            }
            completion(error)
        }
    }
 
    // MARK: - Real-time Sync
 
    func startRemoteSync(forUserID uid: String, onChange: @escaping (BudgetPlan?) -> Void) {
        listener?.remove()
        listener = db.collection("budgetPlans").document(uid)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
 
                if let error = error {
                    print("❌ BudgetPlan listener: \(error.localizedDescription)")
                    return
                }
 
                // Hujjat o'chirilgan yoki mavjud emas
                guard let data = snapshot?.data(), !data.isEmpty else {
                    self.cache.delete(for: uid)
                    DispatchQueue.main.async { onChange(nil) }
                    return
                }
 
                guard let parsed = Self.decode(data) else { return }
                self.cache.save(parsed, for: uid)
                self.cache.deleteLegacy()
                print("🔄 BudgetPlan real-time yangilandi: \(parsed.totalAmount) so'm")
                DispatchQueue.main.async { onChange(parsed) }
            }
    }
 
    func stopRemoteSync() {
        listener?.remove()
        listener = nil
    }
 
    // MARK: - Legacy Migration
 
    private func migrateLegacyIfNeeded(forUserID uid: String,
                                       completion: @escaping (Result<BudgetPlan?, Error>) -> Void) {
        guard let legacy = cache.loadLegacy() else {
            completion(.success(nil))
            return
        }
        print("🔄 Legacy BudgetPlan migratsiya boshlandi")
        savePlan(legacy, forUserID: uid) { [weak self] error in
            self?.cache.deleteLegacy()
            if error == nil {
                print("✅ Legacy migratsiya muvaffaqiyatli")
            }
            completion(.success(error == nil ? legacy : nil))
        }
    }
 
    // MARK: - Encode / Decode
 
    static func encode(_ plan: BudgetPlan, userID: String) -> [String: Any] {
        return [
            "id"             : plan.id,
            "userID"         : userID,
            "totalAmount"    : plan.totalAmount,
            "startDate"      : Timestamp(date: plan.startDate),
            "endDate"        : Timestamp(date: plan.endDate),
            "createdAt"      : Timestamp(date: plan.createdAt),
            "updatedAt"      : FieldValue.serverTimestamp(),
            "categoryLimits" : plan.categoryLimits.map { limit -> [String: Any] in
                return [
                    "id"           : limit.id,
                    "categoryName" : limit.categoryName,
                    "limitAmount"  : limit.limitAmount,
                    "spent"        : limit.spent
                ]
            }
        ]
    }
 
    static func decode(_ data: [String: Any]) -> BudgetPlan? {
        guard let total = data["totalAmount"] as? Double else { return nil }
        let id        = data["id"]        as? String ?? UUID().uuidString
        let startDate = (data["startDate"] as? Timestamp)?.dateValue() ?? Date()
        let endDate   = (data["endDate"]   as? Timestamp)?.dateValue() ?? Date()
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
 
        let limits = (data["categoryLimits"] as? [[String: Any]] ?? []).compactMap { d -> BudgetPlan.CategoryLimit? in
            guard let name = d["categoryName"] as? String else { return nil }
            return BudgetPlan.CategoryLimit(
                id           : d["id"]          as? String ?? UUID().uuidString,
                categoryName : name,
                limitAmount  : d["limitAmount"] as? Double ?? 0,
                spent        : d["spent"]       as? Double ?? 0
            )
        }
 
        return BudgetPlan(
            id             : id,
            totalAmount    : total,
            startDate      : startDate,
            endDate        : endDate,
            categoryLimits : limits,
            createdAt      : createdAt
        )
    }
}
