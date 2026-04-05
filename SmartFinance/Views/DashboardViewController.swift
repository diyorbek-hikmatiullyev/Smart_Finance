import UIKit
import DGCharts

// MARK: - DashboardViewController

class DashboardViewController: UIViewController {

    let viewModel = DashboardViewModel()

    /// Jadval manbasi (extensionlar uchun)
    var groupedTransactions: [GroupedTransactions] {
        viewModel.groupedTransactions
    }

    var currentSearchQuery: String {
        viewModel.currentSearchQuery
    }

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
    var isWarningExpanded        = false

    // MARK: - viewDidLoad

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationController?.isNavigationBarHidden = true

        viewModel.onStateChanged = { [weak self] in
            DispatchQueue.main.async { self?.applyViewModelState() }
        }
        viewModel.onRequireAuth = { [weak self] in
            DispatchQueue.main.async { self?.navigateToAuth() }
        }

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
        viewModel.viewWillAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.viewWillDisappear()
    }

    /// Faqat UI: balans, diagramma, jadval (ma'lumot ViewModel / Repository da).
    private func applyViewModelState() {
        let filtered = viewModel.transactionsForPeriodCharts
        let bal = DashboardFinanceCalculator.balanceTextAndColor(filtered: filtered)
        balanceLabel.text = bal.text
        balanceLabel.textColor = bal.color

        if let style = DashboardFinanceCalculator.speedWarningStyle(filtered: filtered) {
            speedWarningLabel.text = style.message
            warningContainerView.backgroundColor = style.containerBackground
            speedWarningLabel.textColor = style.labelColor
        }

        let pie = DashboardFinanceCalculator.buildPieChartData(filteredTransactions: filtered)
        if let noData = pie.noDataText {
            pieChartView.data = nil
            pieChartView.noDataText = noData
            pieChartView.setNeedsDisplay()
        } else if let data = pie.data {
            pieChartView.data = data
            pieChartView.data?.notifyDataChanged()
            pieChartView.notifyDataSetChanged()
            pieChartView.setNeedsLayout()
            pieChartView.layoutIfNeeded()
            pieChartView.animate(xAxisDuration: 0.6, yAxisDuration: 0.6, easingOption: .easeInOutQuad)
        }

        tableView.reloadData()
        updateTableViewHeight()
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
        viewModel.setSearchQuery("")

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
            self.viewModel.reloadFromLocal()
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
        viewModel.setTimeSegmentIndex(timeSegmentControl.selectedSegmentIndex)
    }

    func updateTableViewHeight() {
        tableView.layoutIfNeeded()
        tableViewHeightConstraint?.constant = max(tableView.contentSize.height, 60)
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
        viewModel.setSearchQuery(textField.text ?? "")
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder(); return true
    }
}
