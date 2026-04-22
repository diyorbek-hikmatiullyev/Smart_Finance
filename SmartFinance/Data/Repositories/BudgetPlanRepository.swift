//
//  BudgetPlanRepository.swift
//  SmartFinance
//

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

    func loadPlan(forUserID uid: String, completion: @escaping (Result<BudgetPlan?, Error>) -> Void) {
        if let cached = cache.load(for: uid) {
            completion(.success(cached))
        }

        db.collection("budgetPlans").document(uid).getDocument { [weak self] snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = snapshot?.data() else {
                self?.migrateLegacyPlanIfNeeded(forUserID: uid, completion: completion)
                return
            }

            guard let parsed = Self.parseBudgetPlan(from: data) else {
                let parseError = NSError(
                    domain: "BudgetPlanRepository",
                    code: 422,
                    userInfo: [NSLocalizedDescriptionKey: "Budget plan format is invalid"]
                )
                completion(.failure(parseError))
                return
            }

            self?.cache.save(parsed, for: uid)
            self?.cache.deleteLegacy()
            completion(.success(parsed))
        }
    }

    func savePlan(_ plan: BudgetPlan, forUserID uid: String, completion: @escaping (Error?) -> Void) {
        cache.save(plan, for: uid)
        let data = Self.encodeBudgetPlan(plan, userID: uid)
        db.collection("budgetPlans").document(uid).setData(data, merge: true) { error in
            completion(error)
        }
    }

    func deletePlan(forUserID uid: String, completion: @escaping (Error?) -> Void) {
        cache.delete(for: uid)
        cache.deleteLegacy()
        db.collection("budgetPlans").document(uid).delete { error in
            completion(error)
        }
    }

    func startRemoteSync(forUserID uid: String, onChange: @escaping (BudgetPlan?) -> Void) {
        stopRemoteSync()
        listener = db.collection("budgetPlans").document(uid).addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                print("BudgetPlan listener error: \(error.localizedDescription)")
                return
            }

            guard let data = snapshot?.data() else {
                self?.cache.delete(for: uid)
                DispatchQueue.main.async { onChange(nil) }
                return
            }

            guard let parsed = Self.parseBudgetPlan(from: data) else { return }
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

    private func migrateLegacyPlanIfNeeded(forUserID uid: String,
                                           completion: @escaping (Result<BudgetPlan?, Error>) -> Void) {
        guard let legacy = cache.loadLegacy() else {
            completion(.success(nil))
            return
        }
        savePlan(legacy, forUserID: uid) { [weak self] error in
            if let error = error {
                completion(.failure(error))
                return
            }
            self?.cache.deleteLegacy()
            completion(.success(legacy))
        }
    }

    // MARK: - Mapping

    private static func encodeBudgetPlan(_ plan: BudgetPlan, userID: String) -> [String: Any] {
        let categories: [[String: Any]] = plan.categoryLimits.map { limit in
            [
                "id": limit.id,
                "categoryName": limit.categoryName,
                "limitAmount": limit.limitAmount,
                "spent": limit.spent
            ]
        }

        return [
            "id": plan.id,
            "userID": userID,
            "totalAmount": plan.totalAmount,
            "startDate": Timestamp(date: plan.startDate),
            "endDate": Timestamp(date: plan.endDate),
            "createdAt": Timestamp(date: plan.createdAt),
            "categoryLimits": categories
        ]
    }

    private static func parseBudgetPlan(from data: [String: Any]) -> BudgetPlan? {
        let id = data["id"] as? String ?? UUID().uuidString
        let totalAmount = data["totalAmount"] as? Double ?? 0
        guard totalAmount >= 0 else { return nil }

        let startDate = (data["startDate"] as? Timestamp)?.dateValue() ?? Date()
        let endDate = (data["endDate"] as? Timestamp)?.dateValue() ?? Date()
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()

        let rawLimits = data["categoryLimits"] as? [[String: Any]] ?? []
        let limits: [BudgetPlan.CategoryLimit] = rawLimits.compactMap { item in
            guard let name = item["categoryName"] as? String else { return nil }
            let amount = item["limitAmount"] as? Double ?? 0
            let spent = item["spent"] as? Double ?? 0
            let limitID = item["id"] as? String ?? UUID().uuidString
            return BudgetPlan.CategoryLimit(id: limitID, categoryName: name, limitAmount: amount, spent: spent)
        }

        return BudgetPlan(
            id: id,
            totalAmount: totalAmount,
            startDate: startDate,
            endDate: endDate,
            categoryLimits: limits,
            createdAt: createdAt
        )
    }
}
