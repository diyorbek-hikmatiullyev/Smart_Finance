// GoalRepository.swift
// SmartFinance
// Oylik maqsadlarni Firebase dan olish va saqlash

import Foundation
import FirebaseFirestore

protocol GoalRepositoryProtocol: AnyObject {
    func saveGoal(_ goal: MonthlyGoal, completion: @escaping (Error?) -> Void)
    func fetchCurrentMonthGoal(userID: String, completion: @escaping (MonthlyGoal?) -> Void)
    func deleteGoal(_ goal: MonthlyGoal, completion: @escaping (Error?) -> Void)
}

final class GoalRepository: GoalRepositoryProtocol {

    static let shared = GoalRepository()
    private let db = Firestore.firestore()
    private init() {}

    private var collection: CollectionReference {
        db.collection("monthly_goals")
    }

    // MARK: - Save

    func saveGoal(_ goal: MonthlyGoal, completion: @escaping (Error?) -> Void) {
        collection
            .document(goal.id)
            .setData(goal.firestoreData) { error in
                completion(error)
            }
    }

    // MARK: - Fetch joriy oy

    func fetchCurrentMonthGoal(userID: String, completion: @escaping (MonthlyGoal?) -> Void) {
        let calendar = Calendar.current
        let now      = Date()
        let month    = calendar.component(.month, from: now)
        let year     = calendar.component(.year,  from: now)

        collection
            .whereField("userID", isEqualTo: userID)
            .whereField("month",  isEqualTo: month)
            .whereField("year",   isEqualTo: year)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ GoalRepository fetch: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                guard let doc = snapshot?.documents.first else {
                    completion(nil)
                    return
                }
                completion(MonthlyGoal.from(doc.data()))
            }
    }

    // MARK: - Delete

    func deleteGoal(_ goal: MonthlyGoal, completion: @escaping (Error?) -> Void) {
        collection.document(goal.id).delete { error in
            completion(error)
        }
    }
}
