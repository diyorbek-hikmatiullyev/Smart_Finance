
import UIKit
import DGCharts

// MARK: - DashboardViewController

class DashboardViewController: UIViewController {

    let viewModel = DashboardViewModel()

    var groupedTransactions: [GroupedTransactions] {
        viewModel.groupedTransactions
    }

    var currentSearchQuery: String {
        viewModel.currentSearchQuery
    }

    // MARK: - Top Nav
    private let navContainer   = UIView()
    var balanceLabel           = UILabel()
    private let searchIconBtn  = UIButton(type: .system)
    private let plusBtn        = UIButton(type: .system)
    let searchTextField        = UITextField()
    private let closeSearchBtn = UIButton(type: .system)

    // MARK: - Carousel
    let carouselScrollView      = UIScrollView()
     var carouselPageControl = UIPageControl()
    private let chartCard           = UIView()
    let pieChartView                = PieChartView()
    let timeSegmentControl          = UISegmentedControl(items: ["Kun", "Oy", "Yil"])
    var goalCard            = UIView()

    // MARK: - Chart navigation bar
    private let navBarView    = UIView()
    private let prevButton    = UIButton(type: .system)
    private let nextButton    = UIButton(type: .system)
    private let navTitleLabel = UILabel()
    private let todayButton   = UIButton(type: .system)
    
    // MARK: - Goal
    var goalCardView = GoalCardView()
    var goalViewModel = GoalViewModel()
    var smartBanner = SmartBannerView()
    var warningContainerView = UIView()

    // MARK: - Scroll content
    private var carouselHeightConstraint: NSLayoutConstraint!
    let scrollView              = UIScrollView()
    let contentView             = UIView()
    let tableView               = UITableView(frame: .zero, style: .plain)
    var tableViewHeightConstraint: NSLayoutConstraint!

    // MARK: - State
    private var isSearchExpanded = false

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

        // Goal — eng oxirida
        setupGoalFeatures()
        loadGoalData()
        
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

    // MARK: - ViewModel state apply

    private func applyViewModelState() {
        let filtered = viewModel.transactionsForPeriodCharts

        let bal = DashboardFinanceCalculator.balanceTextAndColor(filtered: filtered)
        balanceLabel.text      = bal.text
        balanceLabel.textColor = bal.color

        let pie = DashboardFinanceCalculator.buildPieChartData(filteredTransactions: filtered)
        if let noData = pie.noDataText {
            pieChartView.data       = nil
            pieChartView.noDataText = noData
            pieChartView.setNeedsDisplay()
        } else if let data = pie.data {
            pieChartView.data = data
            pieChartView.data?.notifyDataChanged()
            pieChartView.notifyDataSetChanged()
            pieChartView.setNeedsLayout()
            pieChartView.layoutIfNeeded()
            pieChartView.animate(xAxisDuration: 0.5, yAxisDuration: 0.5, easingOption: .easeInOutQuad)
        }

        updateNavBarUI()
        tableView.reloadData()
        updateTableViewHeight()
        refreshGoalUI()
    }

    private func navigateToAuth() {
        NotificationCenter.default.post(name: Notification.Name("switchToAuth"), object: nil)
    }

    // MARK: - Build: Top nav bar

    private func buildNavBar() {
        navContainer.backgroundColor = .systemBackground
        navContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navContainer)

        let sep = UIView()
        sep.backgroundColor = UIColor.separator.withAlphaComponent(0.5)
        sep.translatesAutoresizingMaskIntoConstraints = false

        balanceLabel.font      = .systemFont(ofSize: 18, weight: .bold)
        balanceLabel.textColor = .label
        balanceLabel.text      = "—"
        balanceLabel.translatesAutoresizingMaskIntoConstraints = false

        let sConf = UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
        searchIconBtn.setImage(UIImage(systemName: "magnifyingglass", withConfiguration: sConf), for: .normal)
        searchIconBtn.tintColor = .label
        searchIconBtn.translatesAutoresizingMaskIntoConstraints = false
        searchIconBtn.addTarget(self, action: #selector(expandSearch), for: .touchUpInside)

        let pConf = UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
        plusBtn.setImage(UIImage(systemName: "plus", withConfiguration: pConf), for: .normal)
        plusBtn.tintColor          = .white
        plusBtn.backgroundColor    = UIColor(red: 91/255, green: 173/255, blue: 198/255, alpha: 1)
        plusBtn.layer.cornerRadius = 16
        plusBtn.translatesAutoresizingMaskIntoConstraints = false
        plusBtn.addTarget(self, action: #selector(addTapped), for: .touchUpInside)

        searchTextField.placeholder        = "Qidirish..."
        searchTextField.backgroundColor    = .secondarySystemBackground
        searchTextField.layer.cornerRadius = 12
        searchTextField.returnKeyType      = .search
        searchTextField.alpha              = 0
        searchTextField.isHidden           = true
        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        let iconBox = UIView(frame: CGRect(x: 0, y: 0, width: 36, height: 36))
        let iconImg = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        iconImg.tintColor   = .secondaryLabel
        iconImg.frame       = CGRect(x: 10, y: 8, width: 18, height: 18)
        iconImg.contentMode = .scaleAspectFit
        iconBox.addSubview(iconImg)
        searchTextField.leftView     = iconBox
        searchTextField.leftViewMode = .always

        let xConf = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        closeSearchBtn.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: xConf), for: .normal)
        closeSearchBtn.tintColor = .tertiaryLabel
        closeSearchBtn.alpha     = 0
        closeSearchBtn.isHidden  = true
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

        // Chart card
        chartCard.backgroundColor    = .secondarySystemBackground
        chartCard.layer.cornerRadius = 20
        chartCard.translatesAutoresizingMaskIntoConstraints = false
        carouselScrollView.addSubview(chartCard)

        buildChartNavBar()

        pieChartView.backgroundColor         = .clear
        pieChartView.noDataText              = "Ma'lumot yo'q"
        pieChartView.noDataFont              = .systemFont(ofSize: 14)
        pieChartView.noDataTextColor         = .secondaryLabel
        pieChartView.holeRadiusPercent       = 0.4
        pieChartView.usePercentValuesEnabled = true
        pieChartView.drawEntryLabelsEnabled  = false
        pieChartView.legend.horizontalAlignment = .center
        pieChartView.legend.verticalAlignment   = .bottom
        pieChartView.legend.orientation         = .horizontal
        pieChartView.translatesAutoresizingMaskIntoConstraints = false
        chartCard.addSubview(pieChartView)

        timeSegmentControl.selectedSegmentIndex = 1
        timeSegmentControl.addTarget(self, action: #selector(timeFilterChanged), for: .valueChanged)
        timeSegmentControl.translatesAutoresizingMaskIntoConstraints = false
        chartCard.addSubview(timeSegmentControl)

        // Goal card
        goalCard.backgroundColor    = .secondarySystemBackground
        goalCard.layer.cornerRadius = 20
        goalCard.translatesAutoresizingMaskIntoConstraints = false
        carouselScrollView.addSubview(goalCard)

        // Page control
        carouselPageControl.numberOfPages = 2
        carouselPageControl.pageIndicatorTintColor        = .tertiaryLabel
        carouselPageControl.currentPageIndicatorTintColor = UIColor(red: 91/255, green: 173/255, blue: 198/255, alpha: 1)
        carouselPageControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(carouselPageControl)
    }

    // MARK: - Chart nav bar

    private func buildChartNavBar() {
        let accent = UIColor(red: 91/255, green: 173/255, blue: 198/255, alpha: 1)

        navBarView.backgroundColor = .clear
        navBarView.translatesAutoresizingMaskIntoConstraints = false
        chartCard.addSubview(navBarView)

        let chevConf = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)

        prevButton.setImage(UIImage(systemName: "chevron.left", withConfiguration: chevConf), for: .normal)
        prevButton.tintColor = accent
        prevButton.translatesAutoresizingMaskIntoConstraints = false
        prevButton.addTarget(self, action: #selector(prevTapped), for: .touchUpInside)

        nextButton.setImage(UIImage(systemName: "chevron.right", withConfiguration: chevConf), for: .normal)
        nextButton.tintColor = accent
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)

        navTitleLabel.font          = .systemFont(ofSize: 14, weight: .semibold)
        navTitleLabel.textColor     = .label
        navTitleLabel.textAlignment = .center
        navTitleLabel.translatesAutoresizingMaskIntoConstraints = false

        todayButton.setTitle("Bugun", for: .normal)
        todayButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        todayButton.tintColor = accent
        todayButton.isHidden  = true
        todayButton.translatesAutoresizingMaskIntoConstraints = false
        todayButton.addTarget(self, action: #selector(todayTapped), for: .touchUpInside)

        [prevButton, navTitleLabel, nextButton, todayButton].forEach { navBarView.addSubview($0) }

        NSLayoutConstraint.activate([
            prevButton.leadingAnchor.constraint(equalTo: navBarView.leadingAnchor, constant: 6),
            prevButton.centerYAnchor.constraint(equalTo: navBarView.centerYAnchor),
            prevButton.widthAnchor.constraint(equalToConstant: 32),
            prevButton.heightAnchor.constraint(equalToConstant: 32),

            todayButton.trailingAnchor.constraint(equalTo: navBarView.trailingAnchor, constant: -6),
            todayButton.centerYAnchor.constraint(equalTo: navBarView.centerYAnchor),
            todayButton.widthAnchor.constraint(equalToConstant: 52),

            nextButton.trailingAnchor.constraint(equalTo: todayButton.leadingAnchor, constant: -2),
            nextButton.centerYAnchor.constraint(equalTo: navBarView.centerYAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 32),
            nextButton.heightAnchor.constraint(equalToConstant: 32),

            navTitleLabel.leadingAnchor.constraint(equalTo: prevButton.trailingAnchor, constant: 4),
            navTitleLabel.trailingAnchor.constraint(equalTo: nextButton.leadingAnchor, constant: -4),
            navTitleLabel.centerYAnchor.constraint(equalTo: navBarView.centerYAnchor),
        ])
    }

    // MARK: - NavBar UI

    func updateNavBarUI() {
        navTitleLabel.text = viewModel.navigationTitle

        let canPrev = viewModel.canGoToPrevious
        prevButton.alpha     = canPrev ? 1.0 : 0.25
        prevButton.isEnabled = canPrev

        let canNext = viewModel.canGoToNext
        nextButton.alpha     = canNext ? 1.0 : 0.25
        nextButton.isEnabled = canNext

        todayButton.isHidden = !canNext
        UIView.transition(with: navTitleLabel, duration: 0.18, options: .transitionCrossDissolve) {}
    }

    // MARK: - Navigation actions

    @objc private func prevTapped() {
        guard viewModel.canGoToPrevious else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        viewModel.goToPrevious()
        animateChartTransition(direction: -1)
    }

    @objc private func nextTapped() {
        guard viewModel.canGoToNext else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        viewModel.goToNext()
        animateChartTransition(direction: 1)
    }

    @objc private func todayTapped() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        viewModel.goToToday()
        animateChartTransition(direction: 1)
    }

    private func animateChartTransition(direction: CGFloat) {
        let offset: CGFloat = 28 * direction
        UIView.animate(withDuration: 0.13, animations: {
            self.pieChartView.alpha     = 0
            self.pieChartView.transform = CGAffineTransform(translationX: -offset, y: 0)
        }) { _ in
            self.pieChartView.transform = CGAffineTransform(translationX: offset, y: 0)
            UIView.animate(withDuration: 0.18, delay: 0,
                           usingSpringWithDamping: 0.85, initialSpringVelocity: 0) {
                self.pieChartView.alpha     = 1
                self.pieChartView.transform = .identity
            }
        }
    }

    // MARK: - Build: Scroll content

    private func buildScrollContent() {
        scrollView.translatesAutoresizingMaskIntoConstraints  = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        tableView.backgroundColor = .clear
        tableView.separatorInset  = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(tableView)
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

            tableView.topAnchor.constraint(equalTo: smartBanner.bottomAnchor, constant: 4),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])

        tableViewHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 400)
        tableViewHeightConstraint.isActive = true

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

            navBarView.topAnchor.constraint(equalTo: chartCard.topAnchor, constant: 10),
            navBarView.leadingAnchor.constraint(equalTo: chartCard.leadingAnchor, constant: 4),
            navBarView.trailingAnchor.constraint(equalTo: chartCard.trailingAnchor, constant: -4),
            navBarView.heightAnchor.constraint(equalToConstant: 36),

            pieChartView.topAnchor.constraint(equalTo: navBarView.bottomAnchor, constant: 4),
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

        updateNavBarUI()
    }

    // MARK: - Search

    @objc func expandSearch() {
        guard !isSearchExpanded else { return }
        isSearchExpanded = true
        searchTextField.isHidden = false
        closeSearchBtn.isHidden  = false

        UIView.animate(withDuration: 0.38, delay: 0,
                       usingSpringWithDamping: 0.82, initialSpringVelocity: 0.2,
                       options: .curveEaseInOut) {
            self.balanceLabel.alpha    = 0
            self.searchIconBtn.alpha   = 0
            self.plusBtn.alpha         = 0
            self.searchTextField.alpha = 1
            self.closeSearchBtn.alpha  = 1
            self.carouselHeightConstraint.constant = 0
            self.carouselScrollView.alpha   = 0
            self.carouselPageControl.alpha  = 0
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.carouselScrollView.isHidden  = true
            self.carouselPageControl.isHidden = true
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

        UIView.animate(withDuration: 0.38, delay: 0,
                       usingSpringWithDamping: 0.82, initialSpringVelocity: 0.2,
                       options: .curveEaseInOut) {
            self.balanceLabel.alpha    = 1
            self.searchIconBtn.alpha   = 1
            self.plusBtn.alpha         = 1
            self.searchTextField.alpha = 0
            self.closeSearchBtn.alpha  = 0
            self.carouselHeightConstraint.constant = 320
            self.carouselScrollView.alpha   = 1
            self.carouselPageControl.alpha  = 1
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.searchTextField.isHidden = true
            self.closeSearchBtn.isHidden  = true
            self.viewModel.reloadFromLocal()
        }
    }

    // MARK: - Actions

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
        carouselPageControl.currentPage = max(0, min(
            Int((carouselScrollView.contentOffset.x + w / 2) / w), 1
        ))
    }
}

// MARK: - UITextFieldDelegate

extension DashboardViewController: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        viewModel.setSearchQuery(textField.text ?? "")
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder(); return true
    }
}
