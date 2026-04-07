


import Foundation

final class DashboardViewModel {

    private let transactionsRepo: TransactionRepositoryProtocol
    private let auth: AuthSessionProviding

    var onStateChanged: (() -> Void)?
    var onRequireAuth: (() -> Void)?

    private(set) var allTransactions: [Transaction] = []
    private(set) var groupedTransactions: [GroupedTransactions] = []

    var currentSearchQuery: String = ""
    var timeSegmentIndex: Int = 1  // 0=Kun, 1=Oy, 2=Yil

    private(set) var currentNavigationDate: Date = Date()

    // MARK: - Init

    init(
        transactionsRepo: TransactionRepositoryProtocol = TransactionRepository.shared,
        auth: AuthSessionProviding = AuthSessionProvider.shared
    ) {
        self.transactionsRepo = transactionsRepo
        self.auth = auth
    }

    // MARK: - Chegaralar

    /// Bazadagi eng eski tranzaksiya sanasi — orqaga shu kungacha ketsa bo'ladi.
    var oldestTransactionDate: Date {
        allTransactions.compactMap { $0.date }.min() ?? Date()
    }

    /// Orqaga o'tish mumkinmi? Joriy sana eng eski tranzaksiya sanasidan kattami?
    var canGoToPrevious: Bool {
        guard !allTransactions.isEmpty else { return false }
        let calendar = Calendar.current
        let granularity = granularityForSegment()
        // Agar joriy navigatsiya sanasi eng eski sana bilan bir xil darajada bo'lsa — orqaga yo'q
        return calendar.compare(
            currentNavigationDate,
            to: oldestTransactionDate,
            toGranularity: granularity
        ) == .orderedDescending
    }

    /// Oldinga o'tish mumkinmi? Joriy sanadan katta bo'lmasin.
    var canGoToNext: Bool {
        let calendar = Calendar.current
        switch timeSegmentIndex {
        case 0: return !calendar.isDateInToday(currentNavigationDate)
        case 1: return !calendar.isDate(currentNavigationDate, equalTo: Date(), toGranularity: .month)
        case 2: return !calendar.isDate(currentNavigationDate, equalTo: Date(), toGranularity: .year)
        default: return false
        }
    }

    // MARK: - Navigatsiya

    func goToPrevious() {
        guard canGoToPrevious else { return }
        let calendar = Calendar.current
        switch timeSegmentIndex {
        case 0:
            currentNavigationDate = calendar.date(byAdding: .day,   value: -1, to: currentNavigationDate) ?? currentNavigationDate
        case 1:
            currentNavigationDate = calendar.date(byAdding: .month, value: -1, to: currentNavigationDate) ?? currentNavigationDate
        case 2:
            currentNavigationDate = calendar.date(byAdding: .year,  value: -1, to: currentNavigationDate) ?? currentNavigationDate
        default: break
        }
        regroupForTable()
        onStateChanged?()
    }

    func goToNext() {
        guard canGoToNext else { return }
        let calendar = Calendar.current
        switch timeSegmentIndex {
        case 0:
            currentNavigationDate = calendar.date(byAdding: .day,   value: 1, to: currentNavigationDate) ?? currentNavigationDate
        case 1:
            currentNavigationDate = calendar.date(byAdding: .month, value: 1, to: currentNavigationDate) ?? currentNavigationDate
        case 2:
            currentNavigationDate = calendar.date(byAdding: .year,  value: 1, to: currentNavigationDate) ?? currentNavigationDate
        default: break
        }
        regroupForTable()
        onStateChanged?()
    }

    func goToToday() {
        currentNavigationDate = Date()
        regroupForTable()
        onStateChanged?()
    }

    // MARK: - Navigatsiya sarlavhasi

    var navigationTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "uz_UZ")
        switch timeSegmentIndex {
        case 0:
            if Calendar.current.isDateInToday(currentNavigationDate)     { return "Bugun" }
            if Calendar.current.isDateInYesterday(currentNavigationDate) { return "Kecha" }
            formatter.dateFormat = "d MMMM"
            return formatter.string(from: currentNavigationDate)
        case 1:
            formatter.dateFormat = "MMMM yyyy"
            let raw = formatter.string(from: currentNavigationDate)
            return raw.prefix(1).uppercased() + raw.dropFirst()
        case 2:
            formatter.dateFormat = "yyyy"
            return formatter.string(from: currentNavigationDate)
        default:
            return ""
        }
    }

    // MARK: - Diagramma uchun tranzaksiyalar

    var transactionsForPeriodCharts: [Transaction] {
        filterByNavigationDate(allTransactions)
    }

    // MARK: - Segment o'zgarishi

    func setTimeSegmentIndex(_ index: Int) {
        timeSegmentIndex = index
        currentNavigationDate = Date()
        regroupForTable()
        onStateChanged?()
    }

    // MARK: - Lifecycle

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

    // MARK: - Guruhli tranzaksiyalar

    private func transactionsForTable() -> [Transaction] {
        if !currentSearchQuery.isEmpty {
            return allTransactions.filter {
                SmartSearchEngine.matches(transaction: $0, query: currentSearchQuery)
            }
        }
        return filterByNavigationDate(allTransactions)
    }

    private func regroupForTable() {
        groupedTransactions = TransactionGrouping.group(transactionsForTable())
    }

    private func clearLocalState() {
        allTransactions = []
        groupedTransactions = []
        onStateChanged?()
    }

    // MARK: - Sana bo'yicha filtrlash

    private func filterByNavigationDate(_ transactions: [Transaction]) -> [Transaction] {
        let calendar = Calendar.current
        let granularity = granularityForSegment()
        return transactions.filter { t in
            guard let date = t.date else { return false }
            return calendar.isDate(date, equalTo: currentNavigationDate, toGranularity: granularity)
        }
    }

    func granularityForSegment() -> Calendar.Component {
        switch timeSegmentIndex {
        case 0: return .day
        case 1: return .month
        case 2: return .year
        default: return .month
        }
    }

    // MARK: - CRUD

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
        transactionsRepo.updateTitleAndAmount(
            documentID: local.documentID,
            title: title,
            amount: amount,
            local: local
        )
        reloadFromLocal()
    }
}
