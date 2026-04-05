//
//  ProfileViewModel.swift
//  SmartFinance
//

import Foundation

final class ProfileViewModel {

    private let repository: TransactionRepositoryProtocol
    private let auth: AuthSessionProviding

    init(
        repository: TransactionRepositoryProtocol = TransactionRepository.shared,
        auth: AuthSessionProviding = AuthSessionProvider.shared
    ) {
        self.repository = repository
        self.auth = auth
    }

    func loadTransactions() -> [Transaction] {
        guard let uid = auth.currentUserID else { return [] }
        return (try? repository.fetchTransactions(forUserID: uid)) ?? []
    }

    func clearLocalDataForCurrentUser() {
        guard let uid = auth.currentUserID else { return }
        repository.deleteAllLocalTransactions(forUserID: uid)
    }
}
