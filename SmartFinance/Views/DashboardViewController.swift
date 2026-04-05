
import UIKit
import FirebaseAuth
import DGCharts
import CoreData
import FirebaseFirestore
import NaturalLanguage

// MARK: - SmartSearchEngine (NaturalLanguage + Sinonimlar + Highlight)

struct SmartSearchEngine {

    // Kategoriya → bog'liq kalit so'zlar
    static let categoryKeywords: [String: [String]] = [
        "transport":    ["mashina", "avto", "benzin", "metan", "zapravka", "moy", "jarima",
                         "taksi", "avtobus", "metro", "poezd", "yo'l", "motor", "kir"],
        "oziq-ovqat":   ["osh", "non", "tushlik", "kechki", "nonushta", "restoran", "kafe",
                         "bozor", "supermarket", "mahsulot", "ovqat", "go'sht", "sabzavot"],
        "kiyim-kechak": ["kiyim", "shim", "ko'ylak", "kurka", "poyabzal",
                         "do'kon", "magazin", "moda", "belbog", "futbolka"],
        "salomatlik":   ["dorixona", "dori", "doktor", "shifoxona", "klinika", "muolaja",
                         "sport", "fitnes", "vitamin", "kasallik", "shifo"],
        "ijara":        ["ijara", "uy", "kvartira", "xona", "kommunal", "gaz", "suv",
                         "elektr", "internet", "oylik"],
        "o'yin-kulgi":  ["kino", "teatr", "konsert", "o'yin", "sayohat", "dam", "bayram",
                         "futbol", "club", "kafe"],
    ]

    /// NaturalLanguage lemmatization
    static func lemmatize(_ word: String) -> String {
        let tagger = NLTagger(tagSchemes: [.lemma])
        tagger.string = word
        var result = word
        tagger.enumerateTags(in: word.startIndex..<word.endIndex,
                             unit: .word, scheme: .lemma, options: []) { tag, _ in
            if let l = tag?.rawValue, !l.isEmpty { result = l.lowercased() }
            return true
        }
        return result
    }

    /// Qidiruv so'zi uchun tegishli kategoriya va kalit so'zlar
    static func context(for query: String) -> (category: String?, keywords: Set<String>) {
        let q = query.lowercased()
        let lemma = lemmatize(q)
        for (cat, kws) in categoryKeywords {
            let hit = cat.contains(q) || q.contains(cat) ||
                      kws.contains(where: { $0.contains(q) || q.contains($0) || $0.contains(lemma) || lemma.contains($0) })
            if hit { return (cat, Set(kws)) }
        }
        return (nil, [])
    }

    /// Tranzaksiya mosligini tekshirish
    static func matches(transaction: Transaction, query: String) -> Bool {
        let q        = query.lowercased()
        let title    = transaction.title?.lowercased() ?? ""
        let category = transaction.category?.lowercased() ?? ""

        if title.contains(q) || category.contains(q) { return true }

        let (relCat, relKWs) = context(for: q)
        if let rc = relCat, category.contains(rc) { return true }
        if relKWs.contains(where: { title.contains($0) || category.contains($0) }) { return true }
        return false
    }

    /// Matnda qidirilgan so'zni Bold + rangda ajratish
    static func highlight(text: String, query: String,
                          font: UIFont,
                          color: UIColor = UIColor(red: 91/255, green: 173/255, blue: 198/255, alpha: 1)) -> NSAttributedString {
        let attr  = NSMutableAttributedString(string: text,
                                              attributes: [.font: font, .foregroundColor: UIColor.label])
        let lower = text.lowercased()
        let q     = query.lowercased()

        // Yordamchi: NSRange ni rangli/qalin qilish
        func apply(nsRange: NSRange, boldFont: UIFont, highlightColor: UIColor) {
            attr.addAttributes([
                .foregroundColor: highlightColor,
                .font: boldFont
            ], range: nsRange)
        }

        let boldFont    = UIFont.systemFont(ofSize: font.pointSize, weight: UIFont.Weight.bold)
        let semiboldFont = UIFont.systemFont(ofSize: font.pointSize, weight: UIFont.Weight.semibold)
        let dimColor    = color.withAlphaComponent(0.75)

        // To'g'ridan-to'g'ri moslik
        var searchStart = lower.startIndex
        while searchStart < lower.endIndex,
              let found = lower.range(of: q, range: searchStart..<lower.endIndex) {
            let nsRange = NSRange(found, in: text)
            apply(nsRange: nsRange, boldFont: boldFont, highlightColor: color)
            searchStart = found.upperBound
        }

        // Aqlli kalit so'z moslik
        let (_, kws) = context(for: q)
        for kw in kws {
            var kwStart = lower.startIndex
            while kwStart < lower.endIndex,
                  let found = lower.range(of: kw, range: kwStart..<lower.endIndex) {
                let nsRange = NSRange(found, in: text)
                apply(nsRange: nsRange, boldFont: semiboldFont, highlightColor: dimColor)
                kwStart = found.upperBound
            }
        }
        return attr
    }
}

// MARK: - DashboardViewController

class DashboardViewController: UIViewController {

    // MARK: - Nav Container
    private let navContainer   = UIView()
    var balanceLabel           = UILabel()
    private let searchIconBtn  = UIButton(type: .system)
    private let plusBtn        = UIButton(type: .system)
    let searchTextField        = UITextField()
    private let closeSearchBtn = UIButton(type: .system)

    // MARK: - Carousel
    private let carouselScrollView  = UIScrollView()
    private let carouselPageControl = UIPageControl()
    private let chartCard           = UIView()
    let pieChartView                = PieChartView()
    let timeSegmentControl          = UISegmentedControl(items: ["Hafta", "Oy", "Yil"])
    private let goalCard            = UIView()

    // Carousel collapse constraint
    private var carouselHeightConstraint: NSLayoutConstraint!

    // MARK: - Scroll + Content
    let scrollView   = UIScrollView()
    let contentView  = UIView()

    let warningContainerView = UIView()
    let speedWarningLabel    = UILabel()

    let tableView = UITableView(frame: .zero, style: .plain)
    var tableViewHeightConstraint: NSLayoutConstraint!

    // MARK: - State
    private var isSearchExpanded = false
    var currentSearchQuery       = ""
    var isWarningExpanded        = false

    // MARK: - Data
    var groupedTransactions: [GroupedTransactions] = []
    var allTransactionsForChart: [Transaction]     = []
    var firebaseListener: ListenerRegistration?

    // MARK: - viewDidLoad

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationController?.isNavigationBarHidden = true

        buildNavBar()
        buildCarousel()
        buildScrollContent()
        activateConstraints()

        tableView.delegate    = self
        tableView.dataSource  = self
        tableView.isScrollEnabled = false
        searchTextField.delegate  = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        guard Auth.auth().currentUser != nil else { navigateToAuth(); return }
        fetchTransactions()
        startFirebaseListener()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        firebaseListener?.remove(); firebaseListener = nil
    }

    private func navigateToAuth() {
        NotificationCenter.default.post(name: Notification.Name("switchToAuth"), object: nil)
    }

    // MARK: - Build: Navigation Bar

    private func buildNavBar() {
        navContainer.backgroundColor = .systemBackground
        navContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navContainer)

        // Separator
        let sep = UIView()
        sep.backgroundColor = UIColor.separator.withAlphaComponent(0.5)
        sep.translatesAutoresizingMaskIntoConstraints = false

        // Balance
        balanceLabel.font = .systemFont(ofSize: 18, weight: .bold)
        balanceLabel.textColor = .label
        balanceLabel.text = "—"
        balanceLabel.translatesAutoresizingMaskIntoConstraints = false

        // Search Icon
        let sConf = UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
        searchIconBtn.setImage(UIImage(systemName: "magnifyingglass", withConfiguration: sConf), for: .normal)
        searchIconBtn.tintColor = .label
        searchIconBtn.translatesAutoresizingMaskIntoConstraints = false
        searchIconBtn.addTarget(self, action: #selector(expandSearch), for: .touchUpInside)

        // Plus Button
        let pConf = UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
        plusBtn.setImage(UIImage(systemName: "plus", withConfiguration: pConf), for: .normal)
        plusBtn.tintColor = .white
        plusBtn.backgroundColor = UIColor(red: 91/255, green: 173/255, blue: 198/255, alpha: 1)
        plusBtn.layer.cornerRadius = 16
        plusBtn.translatesAutoresizingMaskIntoConstraints = false
        plusBtn.addTarget(self, action: #selector(addTapped), for: .touchUpInside)

        // SearchTextField (yashirin)
        searchTextField.placeholder = "Qidirish..."
        searchTextField.backgroundColor = .secondarySystemBackground
        searchTextField.layer.cornerRadius = 12
        searchTextField.returnKeyType = .search
        searchTextField.alpha   = 0
        searchTextField.isHidden = true
        searchTextField.translatesAutoresizingMaskIntoConstraints = false

        let iconBox = UIView(frame: CGRect(x: 0, y: 0, width: 36, height: 36))
        let iconImg = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        iconImg.tintColor = .secondaryLabel
        iconImg.frame = CGRect(x: 10, y: 8, width: 18, height: 18)
        iconImg.contentMode = .scaleAspectFit
        iconBox.addSubview(iconImg)
        searchTextField.leftView = iconBox
        searchTextField.leftViewMode = .always

        // Close (X) Button
        let xConf = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        closeSearchBtn.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: xConf), for: .normal)
        closeSearchBtn.tintColor = .tertiaryLabel
        closeSearchBtn.alpha    = 0
        closeSearchBtn.isHidden = true
        closeSearchBtn.translatesAutoresizingMaskIntoConstraints = false
        closeSearchBtn.addTarget(self, action: #selector(collapseSearch), for: .touchUpInside)

        [sep, balanceLabel, searchIconBtn, plusBtn, searchTextField, closeSearchBtn]
            .forEach { navContainer.addSubview($0) }

        NSLayoutConstraint.activate([
            navContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navContainer.heightAnchor.constraint(equalToConstant: 52),

            balanceLabel.centerYAnchor.constraint(equalTo: navContainer.centerYAnchor),
            balanceLabel.leadingAnchor.constraint(equalTo: navContainer.leadingAnchor, constant: 16),

            plusBtn.centerYAnchor.constraint(equalTo: navContainer.centerYAnchor),
            plusBtn.trailingAnchor.constraint(equalTo: navContainer.trailingAnchor, constant: -16),
            plusBtn.widthAnchor.constraint(equalToConstant: 32),
            plusBtn.heightAnchor.constraint(equalToConstant: 32),

            searchIconBtn.centerYAnchor.constraint(equalTo: navContainer.centerYAnchor),
            searchIconBtn.trailingAnchor.constraint(equalTo: plusBtn.leadingAnchor, constant: -12),
            searchIconBtn.widthAnchor.constraint(equalToConstant: 28),
            searchIconBtn.heightAnchor.constraint(equalToConstant: 28),

            searchTextField.centerYAnchor.constraint(equalTo: navContainer.centerYAnchor),
            searchTextField.leadingAnchor.constraint(equalTo: navContainer.leadingAnchor, constant: 12),
            searchTextField.trailingAnchor.constraint(equalTo: closeSearchBtn.leadingAnchor, constant: -6),
            searchTextField.heightAnchor.constraint(equalToConstant: 36),

            closeSearchBtn.centerYAnchor.constraint(equalTo: navContainer.centerYAnchor),
            closeSearchBtn.trailingAnchor.constraint(equalTo: navContainer.trailingAnchor, constant: -14),
            closeSearchBtn.widthAnchor.constraint(equalToConstant: 28),
            closeSearchBtn.heightAnchor.constraint(equalToConstant: 28),

            sep.bottomAnchor.constraint(equalTo: navContainer.bottomAnchor),
            sep.leadingAnchor.constraint(equalTo: navContainer.leadingAnchor),
            sep.trailingAnchor.constraint(equalTo: navContainer.trailingAnchor),
            sep.heightAnchor.constraint(equalToConstant: 0.5),
        ])
    }

    // MARK: - Build: Carousel

    private func buildCarousel() {
        carouselScrollView.isPagingEnabled = true
        carouselScrollView.showsHorizontalScrollIndicator = false
        carouselScrollView.clipsToBounds = true
        carouselScrollView.delegate = self
        carouselScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(carouselScrollView)

        // Card 1 — Chart
        chartCard.backgroundColor = .secondarySystemBackground
        chartCard.layer.cornerRadius = 20
        chartCard.translatesAutoresizingMaskIntoConstraints = false
        carouselScrollView.addSubview(chartCard)

        pieChartView.backgroundColor = .clear
        pieChartView.noDataText = "Ma'lumot yo'q"
        pieChartView.noDataFont = .systemFont(ofSize: 14)
        pieChartView.noDataTextColor = .secondaryLabel
        pieChartView.holeRadiusPercent = 0.4
        pieChartView.usePercentValuesEnabled = true
        pieChartView.drawEntryLabelsEnabled = false
        pieChartView.legend.horizontalAlignment = .center
        pieChartView.legend.verticalAlignment = .bottom
        pieChartView.legend.orientation = .horizontal
        pieChartView.translatesAutoresizingMaskIntoConstraints = false
        chartCard.addSubview(pieChartView)

        timeSegmentControl.selectedSegmentIndex = 1
        timeSegmentControl.addTarget(self, action: #selector(timeFilterChanged), for: .valueChanged)
        timeSegmentControl.translatesAutoresizingMaskIntoConstraints = false
        chartCard.addSubview(timeSegmentControl)

        // Card 2 — Goal (bo'sh)
        goalCard.backgroundColor = .secondarySystemBackground
        goalCard.layer.cornerRadius = 20
        goalCard.translatesAutoresizingMaskIntoConstraints = false
        carouselScrollView.addSubview(goalCard)

        let goalLabel = UILabel()
        goalLabel.text = "🎯  Maqsadlar yaqinda"
        goalLabel.font = .systemFont(ofSize: 16, weight: .medium)
        goalLabel.textColor = .tertiaryLabel
        goalLabel.textAlignment = .center
        goalLabel.translatesAutoresizingMaskIntoConstraints = false
        goalCard.addSubview(goalLabel)

        NSLayoutConstraint.activate([
            goalLabel.centerXAnchor.constraint(equalTo: goalCard.centerXAnchor),
            goalLabel.centerYAnchor.constraint(equalTo: goalCard.centerYAnchor),
        ])

        // Page Control
        carouselPageControl.numberOfPages = 2
        carouselPageControl.pageIndicatorTintColor = .tertiaryLabel
        carouselPageControl.currentPageIndicatorTintColor = UIColor(red: 91/255, green: 173/255, blue: 198/255, alpha: 1)
        carouselPageControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(carouselPageControl)
    }

    // MARK: - Build: Scroll Content

    private func buildScrollContent() {
        scrollView.translatesAutoresizingMaskIntoConstraints  = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        warningContainerView.layer.cornerRadius = 12
        warningContainerView.translatesAutoresizingMaskIntoConstraints = false

        speedWarningLabel.font = .systemFont(ofSize: 14, weight: .medium)
        speedWarningLabel.numberOfLines = 1
        speedWarningLabel.lineBreakMode = .byTruncatingTail
        speedWarningLabel.translatesAutoresizingMaskIntoConstraints = false

        tableView.backgroundColor = .clear
        tableView.separatorInset  = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        [warningContainerView, tableView].forEach { contentView.addSubview($0) }
        warningContainerView.addSubview(speedWarningLabel)

        let tap = UITapGestureRecognizer(target: self, action: #selector(toggleWarningBanner))
        warningContainerView.addGestureRecognizer(tap)
        warningContainerView.isUserInteractionEnabled = true
    }

    // MARK: - Constraints

    private func activateConstraints() {
        let cardH: CGFloat = 320

        carouselHeightConstraint = carouselScrollView.heightAnchor.constraint(equalToConstant: cardH)

        NSLayoutConstraint.activate([
            carouselScrollView.topAnchor.constraint(equalTo: navContainer.bottomAnchor, constant: 12),
            carouselScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            carouselScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            carouselHeightConstraint,

            carouselPageControl.topAnchor.constraint(equalTo: carouselScrollView.bottomAnchor, constant: 6),
            carouselPageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            carouselPageControl.heightAnchor.constraint(equalToConstant: 20),

            scrollView.topAnchor.constraint(equalTo: carouselPageControl.bottomAnchor, constant: 4),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            warningContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            warningContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            warningContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            speedWarningLabel.topAnchor.constraint(equalTo: warningContainerView.topAnchor, constant: 12),
            speedWarningLabel.bottomAnchor.constraint(equalTo: warningContainerView.bottomAnchor, constant: -12),
            speedWarningLabel.leadingAnchor.constraint(equalTo: warningContainerView.leadingAnchor, constant: 15),
            speedWarningLabel.trailingAnchor.constraint(equalTo: warningContainerView.trailingAnchor, constant: -15),

            tableView.topAnchor.constraint(equalTo: warningContainerView.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])

        tableViewHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 400)
        tableViewHeightConstraint.isActive = true

        // Carousel card constraints — view layout tayyor bo'lgandan keyin
        DispatchQueue.main.async { self.setupCarouselCards(cardH: cardH) }
    }

    private func setupCarouselCards(cardH: CGFloat) {
        let cw = carouselScrollView.bounds.width
        guard cw > 0 else { return }

        carouselScrollView.contentSize = CGSize(width: cw * 2, height: cardH)

        NSLayoutConstraint.activate([
            chartCard.topAnchor.constraint(equalTo: carouselScrollView.topAnchor),
            chartCard.leadingAnchor.constraint(equalTo: carouselScrollView.leadingAnchor),
            chartCard.widthAnchor.constraint(equalToConstant: cw),
            chartCard.heightAnchor.constraint(equalToConstant: cardH),

            pieChartView.topAnchor.constraint(equalTo: chartCard.topAnchor, constant: 12),
            pieChartView.leadingAnchor.constraint(equalTo: chartCard.leadingAnchor, constant: 8),
            pieChartView.trailingAnchor.constraint(equalTo: chartCard.trailingAnchor, constant: -8),
            pieChartView.bottomAnchor.constraint(equalTo: timeSegmentControl.topAnchor, constant: -8),

            timeSegmentControl.bottomAnchor.constraint(equalTo: chartCard.bottomAnchor, constant: -14),
            timeSegmentControl.leadingAnchor.constraint(equalTo: chartCard.leadingAnchor, constant: 16),
            timeSegmentControl.trailingAnchor.constraint(equalTo: chartCard.trailingAnchor, constant: -16),
            timeSegmentControl.heightAnchor.constraint(equalToConstant: 34),

            goalCard.topAnchor.constraint(equalTo: carouselScrollView.topAnchor),
            goalCard.leadingAnchor.constraint(equalTo: chartCard.trailingAnchor),
            goalCard.widthAnchor.constraint(equalToConstant: cw),
            goalCard.heightAnchor.constraint(equalToConstant: cardH),
        ])
    }

    // MARK: - Search Animations

    @objc func expandSearch() {
        guard !isSearchExpanded else { return }
        isSearchExpanded = true

        searchTextField.isHidden = false
        closeSearchBtn.isHidden  = false

        UIView.animate(withDuration: 0.38, delay: 0,
                       usingSpringWithDamping: 0.82, initialSpringVelocity: 0.2,
                       options: .curveEaseInOut) {
            self.balanceLabel.alpha  = 0
            self.searchIconBtn.alpha = 0
            self.plusBtn.alpha       = 0
            self.searchTextField.alpha = 1
            self.closeSearchBtn.alpha  = 1
            self.carouselHeightConstraint.constant = 0
            self.carouselScrollView.alpha           = 0
            self.carouselPageControl.alpha          = 0
            self.warningContainerView.alpha         = 0
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.carouselScrollView.isHidden   = true
            self.carouselPageControl.isHidden  = true
            self.warningContainerView.isHidden = true
            self.searchTextField.becomeFirstResponder()
        }
    }

    @objc func collapseSearch() {
        guard isSearchExpanded else { return }
        isSearchExpanded = false
        currentSearchQuery = ""

        searchTextField.resignFirstResponder()
        searchTextField.text = nil

        carouselScrollView.isHidden   = false
        carouselPageControl.isHidden  = false
        warningContainerView.isHidden = false

        UIView.animate(withDuration: 0.38, delay: 0,
                       usingSpringWithDamping: 0.82, initialSpringVelocity: 0.2,
                       options: .curveEaseInOut) {
            self.balanceLabel.alpha  = 1
            self.searchIconBtn.alpha = 1
            self.plusBtn.alpha       = 1
            self.searchTextField.alpha = 0
            self.closeSearchBtn.alpha  = 0
            self.carouselHeightConstraint.constant = 320
            self.carouselScrollView.alpha           = 1
            self.carouselPageControl.alpha          = 1
            self.warningContainerView.alpha         = 1
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.searchTextField.isHidden = true
            self.closeSearchBtn.isHidden  = true
            self.fetchTransactions()
        }
    }

    // MARK: - Actions

    @objc private func toggleWarningBanner() {
        isWarningExpanded.toggle()
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.speedWarningLabel.numberOfLines = self.isWarningExpanded ? 0 : 1
            self.view.layoutIfNeeded()
        }
    }

    @objc private func addTapped() {
        let addVC = AddTransactionViewController()
        navigationController?.pushViewController(addVC, animated: true)
    }

    @objc func timeFilterChanged() {
        calculateBalance()
        updateChartData()
        groupedTransactions = group(filterTransactionsBySegment(allTransactionsForChart))
        tableView.reloadData()
        DispatchQueue.main.async { self.updateTableViewHeight() }
    }

    func updateTableViewHeight() {
        tableView.layoutIfNeeded()
        tableViewHeightConstraint?.constant = max(tableView.contentSize.height, 60)
    }

    // MARK: - Yordamchi

    func group(_ transactions: [Transaction]) -> [GroupedTransactions] {
        var map: [String: [Transaction]] = [:]
        for t in transactions {
            let k = t.date?.toString() ?? "Noma'lum"
            map[k, default: []].append(t)
        }
        return map.map { GroupedTransactions(date: $0.key, transactions: $0.value) }
                  .sorted { $0.date > $1.date }
    }

    // MARK: - CoreData

    func fetchTransactions() {
        guard let uid = Auth.auth().currentUser?.uid else {
            clearDataAndUI(); navigateToAuth(); return
        }
        let req: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        req.predicate       = NSPredicate(format: "userID == %@", uid)
        req.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        do {
            let fetched = try CoreDataStack.shared.context.fetch(req)
            allTransactionsForChart = fetched
            groupedTransactions     = group(fetched)
            DispatchQueue.main.async { [weak self] in
                self?.calculateBalance()
                self?.updateChartData()
                self?.tableView.reloadData()
                self?.updateTableViewHeight()
            }
        } catch { print("❌ Fetch: \(error.localizedDescription)") }
    }

    func clearDataAndUI() {
        allTransactionsForChart = []; groupedTransactions = []
        DispatchQueue.main.async { [weak self] in
            self?.balanceLabel.text = "0 so'm"
            self?.pieChartView.data = nil
            self?.pieChartView.noDataText = "Ma'lumot yo'q"
            self?.tableView.reloadData()
            self?.updateTableViewHeight()
        }
    }

    // MARK: - Firebase

    func startFirebaseListener() {
        firebaseListener?.remove()
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        firebaseListener = db.collection("transactions")
            .whereField("userID", isEqualTo: uid)
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snap, err in
                if let err = err { print("❌ Listener: \(err.localizedDescription)"); return }
                self?.syncFirebaseToLocalIfNeeded(snapshot: snap)
            }
    }

    private func syncFirebaseToLocalIfNeeded(snapshot: QuerySnapshot?) {
        guard let docs = snapshot?.documents,
              let uid  = Auth.auth().currentUser?.uid else { return }
        let ctx = CoreDataStack.shared.context
        for doc in docs {
            let data  = doc.data(); let docID = doc.documentID
            let req: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            req.predicate = NSPredicate(format: "documentID == %@ AND userID == %@", docID, uid)
            if let ex = try? ctx.fetch(req), !ex.isEmpty { continue }
            let t = Transaction(context: ctx)
            t.documentID = docID; t.userID = uid
            t.title      = data["title"]    as? String
            t.amount     = data["amount"]   as? Double ?? 0
            t.category   = data["category"] as? String
            t.type       = data["type"]     as? String
            if let ts = data["date"] as? Timestamp { t.date = ts.dateValue() }
        }
        CoreDataStack.shared.saveContext()
        fetchTransactions()
    }
}

// MARK: - UIScrollViewDelegate

extension DashboardViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === carouselScrollView else { return }
        let w = carouselScrollView.bounds.width
        guard w > 0 else { return }
        carouselPageControl.currentPage = max(0, min(Int((carouselScrollView.contentOffset.x + w / 2) / w), 1))
    }
}

// MARK: - UITextFieldDelegate (Aqlli Qidiruv)

extension DashboardViewController: UITextFieldDelegate {

    func textFieldDidChangeSelection(_ textField: UITextField) {
        currentSearchQuery = (textField.text ?? "").trimmingCharacters(in: .whitespaces)

        guard !currentSearchQuery.isEmpty else {
            groupedTransactions = group(allTransactionsForChart)
            tableView.reloadData(); updateTableViewHeight(); return
        }

        let filtered = allTransactionsForChart.filter {
            SmartSearchEngine.matches(transaction: $0, query: currentSearchQuery)
        }
        groupedTransactions = group(filtered)
        tableView.reloadData()
        updateTableViewHeight()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder(); return true
    }
}
