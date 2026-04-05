// FirestoreService.swift
// SmartFinance
// Data Integrity: Validation + Duplicate check + Firestore save

import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - Validation

struct ValidationResult {
    let isValid: Bool
    let errors: [String]
}

final class ExpenseValidator {

    static func validate(_ expense: ScannedExpense) -> ValidationResult {
        var errors: [String] = []

        if expense.amount <= 0 {
            errors.append("Summa 0 dan katta bo'lishi kerak")
        }
        if expense.amount > 100_000_000 {
            errors.append("Summa 100 mln so'mdan oshmasligi kerak")
        }

        let trimmedName = expense.vendorName.trimmingCharacters(in: .whitespaces)
        if trimmedName.isEmpty {
            errors.append("Do'kon nomi kiritilmagan")
        }
        if trimmedName.count > 100 {
            errors.append("Do'kon nomi juda uzun (max 100 belgi)")
        }

        if expense.date > Date() {
            errors.append("Sana kelajakda bo'lishi mumkin emas")
        }

        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
}

// MARK: - FirestoreService

final class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()
    private init() {}

    /// ScannedExpense ni tekshirib, duplicate bo'lmasa Firestore'ga saqlaydi
    func saveExpense(_ expense: ScannedExpense,
                     completion: @escaping (Result<Void, Error>) -> Void) {

        // 1. Client-side validation
        let validation = ExpenseValidator.validate(expense)
        guard validation.isValid else {
            let message = validation.errors.joined(separator: "\n")
            let error = NSError(domain: "Validation", code: 400,
                                userInfo: [NSLocalizedDescriptionKey: message])
            completion(.failure(error))
            return
        }

        // 2. Duplicate check — so'nggi 5 daqiqa ichida xuddi shu rawURL bormi?
        let fiveMinutesAgo = Date().addingTimeInterval(-300)
        db.collection("expenses")
            .whereField("rawURL", isEqualTo: expense.rawURL)
            .whereField("date", isGreaterThan: Timestamp(date: fiveMinutesAgo))
            .getDocuments { [weak self] snapshot, error in

                if let error = error {
                    completion(.failure(error))
                    return
                }

                if let docs = snapshot?.documents, !docs.isEmpty {
                    let dupError = NSError(domain: "Duplicate", code: 409,
                                          userInfo: [NSLocalizedDescriptionKey: "Bu chek allaqachon saqlangan"])
                    completion(.failure(dupError))
                    return
                }

                // 3. Haqiqiy yozish
                self?.writeExpense(expense, completion: completion)
            }
    }

    private func writeExpense(_ expense: ScannedExpense,
                              completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else {
            let error = NSError(domain: "Auth", code: 401,
                                userInfo: [NSLocalizedDescriptionKey: "Foydalanuvchi tizimga kirmagan"])
            completion(.failure(error))
            return
        }

        let data: [String: Any] = [
            "userID"           : userID,
            "amount"           : expense.amount,
            "vendorName"       : expense.vendorName,
            "category"         : expense.category.rawValue,
            "date"             : Timestamp(date: expense.date),
            "rawURL"           : expense.rawURL,
            "createdAt"        : FieldValue.serverTimestamp(),
            "isManuallyEdited" : false
        ]

        db.collection("expenses").addDocument(data: data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
