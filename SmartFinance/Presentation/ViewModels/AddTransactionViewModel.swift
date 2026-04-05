//
//  AddTransactionViewModel.swift
//  SmartFinance
//

import Foundation

final class AddTransactionViewModel {

    private let repository: TransactionRepositoryProtocol
    private let auth: AuthSessionProviding

    let expenseCategories = [
        "Oziq-ovqat", "Transport", "Ijara", "Kiyim-kechak", "O'yin-kulgi", "Salomatlik", "Boshqa..."
    ]

    init(
        repository: TransactionRepositoryProtocol = TransactionRepository.shared,
        auth: AuthSessionProviding = AuthSessionProvider.shared
    ) {
        self.repository = repository
        self.auth = auth
    }

    func save(
        title: String,
        cleanedAmountText: String,
        isIncome: Bool,
        selectedCategory: String,
        completion: @escaping (Error?) -> Void
    ) {
        guard let amount = Double(cleanedAmountText),
              let uid = auth.currentUserID, !uid.isEmpty else {
            completion(nil)
            return
        }

        let input = NewTransactionInput(
            title: title,
            amount: amount,
            isIncome: isIncome,
            category: selectedCategory,
            userID: uid
        )
        repository.createTransaction(input, completion: completion)
    }
}
