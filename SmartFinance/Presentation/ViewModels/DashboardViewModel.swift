//
//  DashboardViewModel.swift
//  SmartFinance
//

import Foundation

/// Dashboard: ma'lumot va qidiruv holati. Core Data / Firestore `TransactionRepository` orqali.
final class DashboardViewModel {

    private let transactionsRepo: TransactionRepositoryProtocol
    private let auth: AuthSessionProviding

    var onStateChanged: (() -> Void)?
    var onRequireAuth: (() -> Void)?

    private(set) var allTransactions: [Transaction] = []
    private(set) var groupedTransactions: [GroupedTransactions] = []

    var currentSearchQuery: String = ""
    var timeSegmentIndex: Int = 1

    init(
        transactionsRepo: TransactionRepositoryProtocol = TransactionRepository.shared,
        auth: AuthSessionProviding = AuthSessionProvider.shared
    ) {
        self.transactionsRepo = transactionsRepo
        self.auth = auth
    }

    /// Diagramma va balans: doim segment bo'yicha filtr (qidiruvdan mustaqil).
    var transactionsForPeriodCharts: [Transaction] {
        DashboardFinanceCalculator.filterBySegment(allTransactions, segmentIndex: timeSegmentIndex)
    }

    func viewWillAppear() {
        guard auth.currentUserID != nil else {
            clearLocalState()
            onRequireAuth?()
            return
        }
        reloadFromLocal()
        if let uid = auth.currentUserID {
            transactionsRepo.startRemoteSync(userID: uid) { [weak self] in
                self?.reloadFromLocal()
            }
        }
    }

    func viewWillDisappear() {
        transactionsRepo.stopRemoteSync()
    }

    func reloadFromLocal() {
        guard let uid = auth.currentUserID else {
            clearLocalState()
            onRequireAuth?()
            return
        }
        do {
            allTransactions = try transactionsRepo.fetchTransactions(forUserID: uid)
            regroupForTable()
            onStateChanged?()
        } catch {
            print("❌ Fetch: \(error.localizedDescription)")
        }
    }

    func setSearchQuery(_ raw: String) {
        currentSearchQuery = raw.trimmingCharacters(in: .whitespaces)
        regroupForTable()
        onStateChanged?()
    }

    func setTimeSegmentIndex(_ index: Int) {
        timeSegmentIndex = index
        regroupForTable()
        onStateChanged?()
    }

    /// Jadval: qidiruv bo'lsa — butun bazadan mos keluvchilar; bo'lmasa — segment bo'yicha.
    private func transactionsForTable() -> [Transaction] {
        if !currentSearchQuery.isEmpty {
            return allTransactions.filter { SmartSearchEngine.matches(transaction: $0, query: currentSearchQuery) }
        }
        return DashboardFinanceCalculator.filterBySegment(allTransactions, segmentIndex: timeSegmentIndex)
    }

    private func regroupForTable() {
        groupedTransactions = TransactionGrouping.group(transactionsForTable())
    }

    private func clearLocalState() {
        allTransactions = []
        groupedTransactions = []
        onStateChanged?()
    }

    func transaction(at indexPath: IndexPath) -> Transaction? {
        guard groupedTransactions.indices.contains(indexPath.section) else { return nil }
        let rows = groupedTransactions[indexPath.section].transactions
        guard rows.indices.contains(indexPath.row) else { return nil }
        return rows[indexPath.row]
    }

    func deleteTransaction(at indexPath: IndexPath) {
        guard let t = transaction(at: indexPath) else { return }
        transactionsRepo.deleteLocalAndRemote(t)
        reloadFromLocal()
    }

    func updateTransaction(at indexPath: IndexPath, title: String, amount: Double) {
        guard let local = transaction(at: indexPath) else { return }
        transactionsRepo.updateTitleAndAmount(documentID: local.documentID, title: title, amount: amount, local: local)
        reloadFromLocal()
    }
}
