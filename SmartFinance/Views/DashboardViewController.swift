
//import UIKit
//import DGCharts
// 
//// MARK: - DashboardViewController
// 
//class DashboardViewController: UIViewController {
// 
//    let viewModel = DashboardViewModel()
// 
//    var groupedTransactions: [GroupedTransactions] {
//        viewModel.groupedTransactions
//    }
// 
//    var currentSearchQuery: String {
//        viewModel.currentSearchQuery
//    }
// 
//    // MARK: - Top Nav
//    private let navContainer   = UIView()
//    var balanceLabel           = UILabel()
//    private let searchIconBtn  = UIButton(type: .system)
//    private let plusBtn        = UIButton(type: .system)
//    let searchTextField        = UITextField()
//    private let closeSearchBtn = UIButton(type: .system)
// 
//    // MARK: - Carousel
//    let carouselScrollView      = UIScrollView()
//    var carouselPageControl     = UIPageControl()
//    private let chartCard       = UIView()
//    let pieChartView            = PieChartView()
//    let timeSegmentControl      = UISegmentedControl(items: ["Kun", "Oy", "Yil"])
//    var goalCard                = UIView()
// 
//    // MARK: - Chart navigation bar
//    private let navBarView    = UIView()
//    private let prevButton    = UIButton(type: .system)
//    private let nextButton    = UIButton(type: .system)
//    private let navTitleLabel = UILabel()
//    private let todayButton   = UIButton(type: .system)
// 
//    // MARK: - Goal
//    var goalCardView  = GoalCardView()
//    var goalViewModel = GoalViewModel()
//    var smartBanner   = SmartBannerView()
// 
//    // MARK: - Scroll content
//    private var carouselHeightConstraint: NSLayoutConstraint!
//    let scrollView  = UIScrollView()
//    let contentView = UIView()
//    let tableView   = UITableView(frame: .zero, style: .plain)
//    var tableViewHeightConstraint: NSLayoutConstraint!
// 
//    // MARK: - State
//    private var isSearchExpanded = false
// 
//    // MARK: - viewDidLoad
// 
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = .systemBackground
//        navigationController?.isNavigationBarHidden = true
// 
//        viewModel.onStateChanged = { [weak self] in
//            DispatchQueue.main.async { self?.applyViewModelState() }
//        }
//        viewModel.onRequireAuth = { [weak self] in
//            DispatchQueue.main.async { self?.navigateToAuth() }
//        }
// 
//        buildNavBar()
//        buildCarousel()
//        buildScrollContent()
//        activateConstraints()
// 
//        // Goal — eng oxirida
//        setupGoalFeatures()
//        loadGoalData()
// 
//        tableView.delegate    = self
//        tableView.dataSource  = self
//        tableView.isScrollEnabled = false
//        searchTextField.delegate  = self
//    }
//    
//    private var didSetupCards = false
//
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        
//        guard !didSetupCards, carouselScrollView.bounds.width > 50 else { return }
//        didSetupCards = true
//        setupCarouselCards(cardH: 320)
//    }
// 
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        navigationController?.setNavigationBarHidden(true, animated: animated)
//        viewModel.viewWillAppear()
//    }
//    
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        viewModel.viewWillDisappear()
//    }
// 
//    // MARK: - ViewModel state apply
// 
//    private func applyViewModelState() {
//        let filtered = viewModel.transactionsForPeriodCharts
// 
//        let bal = DashboardFinanceCalculator.balanceTextAndColor(filtered: filtered)
//        balanceLabel.text      = bal.text
//        balanceLabel.textColor = bal.color
// 
//        let pie = DashboardFinanceCalculator.buildPieChartData(filteredTransactions: filtered)
//        if let noData = pie.noDataText {
//            pieChartView.data       = nil
//            pieChartView.noDataText = noData
//            pieChartView.setNeedsDisplay()
//        } else if let data = pie.data {
//            pieChartView.data = data
//            pieChartView.data?.notifyDataChanged()
//            pieChartView.notifyDataSetChanged()
//            pieChartView.animate(xAxisDuration: 0.5, yAxisDuration: 0.5, easingOption: .easeInOutQuad)
//        }
// 
//        updateNavBarUI()
//        tableView.reloadData()
//        // ⚡ Performans: layoutIfNeeded o'rniga async bajarish
//        DispatchQueue.main.async { [weak self] in
//            self?.updateTableViewHeight()
//        }
//        refreshGoalUI()
//    }
// 
//    private func navigateToAuth() {
//        NotificationCenter.default.post(name: Notification.Name("switchToAuth"), object: nil)
//    }
// 
//    // MARK: - Build: Top nav bar
// 
//    private func buildNavBar() {
//        navContainer.backgroundColor = .systemBackground
//        navContainer.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(navContainer)
// 
//        let sep = UIView()
//        sep.backgroundColor = UIColor.separator.withAlphaComponent(0.5)
//        sep.translatesAutoresizingMaskIntoConstraints = false
// 
//        balanceLabel.font      = .systemFont(ofSize: 18, weight: .bold)
//        balanceLabel.textColor = .label
//        balanceLabel.text      = "—"
//        balanceLabel.translatesAutoresizingMaskIntoConstraints = false
// 
//        let sConf = UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
//        searchIconBtn.setImage(UIImage(systemName: "magnifyingglass", withConfiguration: sConf), for: .normal)
//        searchIconBtn.tintColor = .label
//        searchIconBtn.translatesAutoresizingMaskIntoConstraints = false
//        searchIconBtn.addTarget(self, action: #selector(expandSearch), for: .touchUpInside)
// 
//        let pConf = UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
//        plusBtn.setImage(UIImage(systemName: "plus", withConfiguration: pConf), for: .normal)
//        plusBtn.tintColor          = .white
//        plusBtn.backgroundColor    = UIColor(red: 91/255, green: 173/255, blue: 198/255, alpha: 1)
//        plusBtn.layer.cornerRadius = 16
//        plusBtn.translatesAutoresizingMaskIntoConstraints = false
//        plusBtn.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
// 
//        searchTextField.placeholder        = "Qidirish..."
//        searchTextField.backgroundColor    = .secondarySystemBackground
//        searchTextField.layer.cornerRadius = 12
//        searchTextField.returnKeyType      = .search
//        searchTextField.alpha              = 0
//        searchTextField.isHidden           = true
//        searchTextField.translatesAutoresizingMaskIntoConstraints = false
//        let iconBox = UIView(frame: CGRect(x: 0, y: 0, width: 36, height: 36))
//        let iconImg = UIImageView(image: UIImage(systemName: "magnifyingglass"))
//        iconImg.tintColor   = .secondaryLabel
//        iconImg.frame       = CGRect(x: 10, y: 8, width: 18, height: 18)
//        iconImg.contentMode = .scaleAspectFit
//        iconBox.addSubview(iconImg)
//        searchTextField.leftView     = iconBox
//        searchTextField.leftViewMode = .always
// 
//        let xConf = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
//        closeSearchBtn.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: xConf), for: .normal)
//        closeSearchBtn.tintColor = .tertiaryLabel
//        closeSearchBtn.alpha     = 0
//        closeSearchBtn.isHidden  = true
//        closeSearchBtn.translatesAutoresizingMaskIntoConstraints = false
//        closeSearchBtn.addTarget(self, action: #selector(collapseSearch), for: .touchUpInside)
// 
//        [sep, balanceLabel, searchIconBtn, plusBtn, searchTextField, closeSearchBtn]
//            .forEach { navContainer.addSubview($0) }
// 
//        NSLayoutConstraint.activate([
//            navContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//            navContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            navContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            navContainer.heightAnchor.constraint(equalToConstant: 52),
// 
//            balanceLabel.centerYAnchor.constraint(equalTo: navContainer.centerYAnchor),
//            balanceLabel.leadingAnchor.constraint(equalTo: navContainer.leadingAnchor, constant: 16),
// 
//            plusBtn.centerYAnchor.constraint(equalTo: navContainer.centerYAnchor),
//            plusBtn.trailingAnchor.constraint(equalTo: navContainer.trailingAnchor, constant: -16),
//            plusBtn.widthAnchor.constraint(equalToConstant: 32),
//            plusBtn.heightAnchor.constraint(equalToConstant: 32),
// 
//            searchIconBtn.centerYAnchor.constraint(equalTo: navContainer.centerYAnchor),
//            searchIconBtn.trailingAnchor.constraint(equalTo: plusBtn.leadingAnchor, constant: -12),
//            searchIconBtn.widthAnchor.constraint(equalToConstant: 28),
//            searchIconBtn.heightAnchor.constraint(equalToConstant: 28),
// 
//            searchTextField.centerYAnchor.constraint(equalTo: navContainer.centerYAnchor),
//            searchTextField.leadingAnchor.constraint(equalTo: navContainer.leadingAnchor, constant: 12),
//            searchTextField.trailingAnchor.constraint(equalTo: closeSearchBtn.leadingAnchor, constant: -6),
//            searchTextField.heightAnchor.constraint(equalToConstant: 36),
// 
//            closeSearchBtn.centerYAnchor.constraint(equalTo: navContainer.centerYAnchor),
//            closeSearchBtn.trailingAnchor.constraint(equalTo: navContainer.trailingAnchor, constant: -14),
//            closeSearchBtn.widthAnchor.constraint(equalToConstant: 28),
//            closeSearchBtn.heightAnchor.constraint(equalToConstant: 28),
// 
//            sep.bottomAnchor.constraint(equalTo: navContainer.bottomAnchor),
//            sep.leadingAnchor.constraint(equalTo: navContainer.leadingAnchor),
//            sep.trailingAnchor.constraint(equalTo: navContainer.trailingAnchor),
//            sep.heightAnchor.constraint(equalToConstant: 0.5),
//        ])
//    }
// 
//    // MARK: - Build: Carousel
// 
//    private func buildCarousel() {
//        carouselScrollView.isPagingEnabled = true
//        carouselScrollView.showsHorizontalScrollIndicator = false
//        carouselScrollView.clipsToBounds = true
//        carouselScrollView.delegate = self
//        carouselScrollView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(carouselScrollView)
// 
//        chartCard.backgroundColor    = .secondarySystemBackground
//        chartCard.layer.cornerRadius = 20
//        chartCard.translatesAutoresizingMaskIntoConstraints = false
//        carouselScrollView.addSubview(chartCard)
// 
//        buildChartNavBar()
// 
//        pieChartView.backgroundColor         = .clear
//        pieChartView.noDataText              = "Ma'lumot yo'q"
//        pieChartView.noDataFont              = .systemFont(ofSize: 14)
//        pieChartView.noDataTextColor         = .secondaryLabel
//        pieChartView.holeRadiusPercent       = 0.4
//        pieChartView.usePercentValuesEnabled = true
//        pieChartView.drawEntryLabelsEnabled  = false
//        pieChartView.legend.horizontalAlignment = .center
//        pieChartView.legend.verticalAlignment   = .bottom
//        pieChartView.legend.orientation         = .horizontal
//        pieChartView.translatesAutoresizingMaskIntoConstraints = false
//        chartCard.addSubview(pieChartView)
// 
//        timeSegmentControl.selectedSegmentIndex = 1
//        timeSegmentControl.addTarget(self, action: #selector(timeFilterChanged), for: .valueChanged)
//        timeSegmentControl.translatesAutoresizingMaskIntoConstraints = false
//        chartCard.addSubview(timeSegmentControl)
// 
//        goalCard.backgroundColor    = .secondarySystemBackground
//        goalCard.layer.cornerRadius = 20
//        goalCard.translatesAutoresizingMaskIntoConstraints = false
//        carouselScrollView.addSubview(goalCard)
// 
//        carouselPageControl.numberOfPages = 2
//        carouselPageControl.pageIndicatorTintColor        = .tertiaryLabel
//        carouselPageControl.currentPageIndicatorTintColor = UIColor(red: 91/255, green: 173/255, blue: 198/255, alpha: 1)
//        carouselPageControl.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(carouselPageControl)
//    }
// 
//    // MARK: - Chart nav bar
// 
//    private func buildChartNavBar() {
//        let accent = UIColor(red: 91/255, green: 173/255, blue: 198/255, alpha: 1)
//        navBarView.backgroundColor = .clear
//        navBarView.translatesAutoresizingMaskIntoConstraints = false
//        chartCard.addSubview(navBarView)
// 
//        let chevConf = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
//        prevButton.setImage(UIImage(systemName: "chevron.left", withConfiguration: chevConf), for: .normal)
//        prevButton.tintColor = accent
//        prevButton.translatesAutoresizingMaskIntoConstraints = false
//        prevButton.addTarget(self, action: #selector(prevTapped), for: .touchUpInside)
// 
//        nextButton.setImage(UIImage(systemName: "chevron.right", withConfiguration: chevConf), for: .normal)
//        nextButton.tintColor = accent
//        nextButton.translatesAutoresizingMaskIntoConstraints = false
//        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
// 
//        navTitleLabel.font          = .systemFont(ofSize: 14, weight: .semibold)
//        navTitleLabel.textColor     = .label
//        navTitleLabel.textAlignment = .center
//        navTitleLabel.translatesAutoresizingMaskIntoConstraints = false
// 
//        todayButton.setTitle("Bugun", for: .normal)
//        todayButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
//        todayButton.tintColor = accent
//        todayButton.isHidden  = true
//        todayButton.translatesAutoresizingMaskIntoConstraints = false
//        todayButton.addTarget(self, action: #selector(todayTapped), for: .touchUpInside)
// 
//        [prevButton, navTitleLabel, nextButton, todayButton].forEach { navBarView.addSubview($0) }
// 
//        NSLayoutConstraint.activate([
//            prevButton.leadingAnchor.constraint(equalTo: navBarView.leadingAnchor, constant: 6),
//            prevButton.centerYAnchor.constraint(equalTo: navBarView.centerYAnchor),
//            prevButton.widthAnchor.constraint(equalToConstant: 32),
//            prevButton.heightAnchor.constraint(equalToConstant: 32),
// 
//            todayButton.trailingAnchor.constraint(equalTo: navBarView.trailingAnchor, constant: -6),
//            todayButton.centerYAnchor.constraint(equalTo: navBarView.centerYAnchor),
//            todayButton.widthAnchor.constraint(equalToConstant: 52),
// 
//            nextButton.trailingAnchor.constraint(equalTo: todayButton.leadingAnchor, constant: -2),
//            nextButton.centerYAnchor.constraint(equalTo: navBarView.centerYAnchor),
//            nextButton.widthAnchor.constraint(equalToConstant: 32),
//            nextButton.heightAnchor.constraint(equalToConstant: 32),
// 
//            navTitleLabel.leadingAnchor.constraint(equalTo: prevButton.trailingAnchor, constant: 4),
//            navTitleLabel.trailingAnchor.constraint(equalTo: nextButton.leadingAnchor, constant: -4),
//            navTitleLabel.centerYAnchor.constraint(equalTo: navBarView.centerYAnchor),
//        ])
//    }
// 
//    func updateNavBarUI() {
//        navTitleLabel.text = viewModel.navigationTitle
// 
//        let canPrev = viewModel.canGoToPrevious
//        prevButton.alpha     = canPrev ? 1.0 : 0.25
//        prevButton.isEnabled = canPrev
// 
//        let canNext = viewModel.canGoToNext
//        nextButton.alpha     = canNext ? 1.0 : 0.25
//        nextButton.isEnabled = canNext
// 
//        todayButton.isHidden = !canNext
//        UIView.transition(with: navTitleLabel, duration: 0.18, options: .transitionCrossDissolve) {}
//    }
// 
//    @objc private func prevTapped() {
//        guard viewModel.canGoToPrevious else { return }
//        UIImpactFeedbackGenerator(style: .light).impactOccurred()
//        viewModel.goToPrevious()
//        animateChartTransition(direction: -1)
//    }
// 
//    @objc private func nextTapped() {
//        guard viewModel.canGoToNext else { return }
//        UIImpactFeedbackGenerator(style: .light).impactOccurred()
//        viewModel.goToNext()
//        animateChartTransition(direction: 1)
//    }
// 
//    @objc private func todayTapped() {
//        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
//        viewModel.goToToday()
//        animateChartTransition(direction: 1)
//    }
// 
//    private func animateChartTransition(direction: CGFloat) {
//        let offset: CGFloat = 28 * direction
//        UIView.animate(withDuration: 0.13, animations: {
//            self.pieChartView.alpha     = 0
//            self.pieChartView.transform = CGAffineTransform(translationX: -offset, y: 0)
//        }) { _ in
//            self.pieChartView.transform = CGAffineTransform(translationX: offset, y: 0)
//            UIView.animate(withDuration: 0.18, delay: 0,
//                           usingSpringWithDamping: 0.85, initialSpringVelocity: 0) {
//                self.pieChartView.alpha     = 1
//                self.pieChartView.transform = .identity
//            }
//        }
//    }
// 
//    // MARK: - Build: Scroll content
// 
//    private func buildScrollContent() {
//        scrollView.translatesAutoresizingMaskIntoConstraints  = false
//        contentView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(scrollView)
//        scrollView.addSubview(contentView)
// 
//        tableView.backgroundColor = .clear
//        tableView.separatorInset  = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
//        tableView.translatesAutoresizingMaskIntoConstraints = false
//        contentView.addSubview(tableView)
// 
//        // ✅ FIX: smartBanner ni ham contentView ga qo'shamiz
//        smartBanner.translatesAutoresizingMaskIntoConstraints = false
//        contentView.addSubview(smartBanner)
//    }
// 
//    // MARK: - Constraints
// 
//    private func activateConstraints() {
//        let cardH: CGFloat = 320
//        carouselHeightConstraint = carouselScrollView.heightAnchor.constraint(equalToConstant: cardH)
// 
//        NSLayoutConstraint.activate([
//            carouselScrollView.topAnchor.constraint(equalTo: navContainer.bottomAnchor, constant: 12),
//            carouselScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
//            carouselScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
//            carouselHeightConstraint,
// 
//            carouselPageControl.topAnchor.constraint(equalTo: carouselScrollView.bottomAnchor, constant: 6),
//            carouselPageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            carouselPageControl.heightAnchor.constraint(equalToConstant: 20),
// 
//            scrollView.topAnchor.constraint(equalTo: carouselPageControl.bottomAnchor, constant: 4),
//            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
// 
//            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
//            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
//            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
//            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
//            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
// 
//            // ✅ FIX: smartBanner contentView ichida, tableView ustida
//            smartBanner.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
//            smartBanner.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//            smartBanner.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
// 
//            // ✅ FIX: tableView smartBanner dan keyin boshlanadi
//            tableView.topAnchor.constraint(equalTo: smartBanner.bottomAnchor, constant: 4),
//            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
//            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
//            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
//        ])
// 
//        tableViewHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 400)
//        tableViewHeightConstraint.isActive = true
// 
////        DispatchQueue.main.async { self.setupCarouselCards(cardH: cardH) }
//    }
// 
//    private func setupCarouselCards(cardH: CGFloat) {
//        let cw = carouselScrollView.bounds.width
//        guard cw > 0 else { return }
//        carouselScrollView.contentSize = CGSize(width: cw * 2, height: cardH)
// 
//        NSLayoutConstraint.activate([
//            chartCard.topAnchor.constraint(equalTo: carouselScrollView.topAnchor),
//            chartCard.leadingAnchor.constraint(equalTo: carouselScrollView.leadingAnchor),
//            chartCard.widthAnchor.constraint(equalToConstant: cw),
//            chartCard.heightAnchor.constraint(equalToConstant: cardH),
// 
//            navBarView.topAnchor.constraint(equalTo: chartCard.topAnchor, constant: 10),
//            navBarView.leadingAnchor.constraint(equalTo: chartCard.leadingAnchor, constant: 4),
//            navBarView.trailingAnchor.constraint(equalTo: chartCard.trailingAnchor, constant: -4),
//            navBarView.heightAnchor.constraint(equalToConstant: 36),
// 
//            pieChartView.topAnchor.constraint(equalTo: navBarView.bottomAnchor, constant: 4),
//            pieChartView.leadingAnchor.constraint(equalTo: chartCard.leadingAnchor, constant: 8),
//            pieChartView.trailingAnchor.constraint(equalTo: chartCard.trailingAnchor, constant: -8),
//            pieChartView.bottomAnchor.constraint(equalTo: timeSegmentControl.topAnchor, constant: -8),
// 
//            timeSegmentControl.bottomAnchor.constraint(equalTo: chartCard.bottomAnchor, constant: -14),
//            timeSegmentControl.leadingAnchor.constraint(equalTo: chartCard.leadingAnchor, constant: 16),
//            timeSegmentControl.trailingAnchor.constraint(equalTo: chartCard.trailingAnchor, constant: -16),
//            timeSegmentControl.heightAnchor.constraint(equalToConstant: 34),
// 
//            goalCard.topAnchor.constraint(equalTo: carouselScrollView.topAnchor),
//            goalCard.leadingAnchor.constraint(equalTo: chartCard.trailingAnchor),
//            goalCard.widthAnchor.constraint(equalToConstant: cw),
//            goalCard.heightAnchor.constraint(equalToConstant: cardH),
//        ])
// 
//        updateNavBarUI()
//    }
// 
//    // MARK: - Search
// 
//    @objc func expandSearch() {
//        guard !isSearchExpanded else { return }
//        isSearchExpanded = true
//        searchTextField.isHidden = false
//        closeSearchBtn.isHidden  = false
// 
//        UIView.animate(withDuration: 0.38, delay: 0,
//                       usingSpringWithDamping: 0.82, initialSpringVelocity: 0.2,
//                       options: .curveEaseInOut) {
//            self.balanceLabel.alpha    = 0
//            self.searchIconBtn.alpha   = 0
//            self.plusBtn.alpha         = 0
//            self.searchTextField.alpha = 1
//            self.closeSearchBtn.alpha  = 1
//            self.carouselHeightConstraint.constant = 0
//            self.carouselScrollView.alpha   = 0
//            self.carouselPageControl.alpha  = 0
//            self.view.layoutIfNeeded()
//        } completion: { _ in
//            self.carouselScrollView.isHidden  = true
//            self.carouselPageControl.isHidden = true
//            self.searchTextField.becomeFirstResponder()
//        }
//    }
// 
//    @objc func collapseSearch() {
//        guard isSearchExpanded else { return }
//        isSearchExpanded = false
//        viewModel.setSearchQuery("")
//        searchTextField.resignFirstResponder()
//        searchTextField.text = nil
// 
//        carouselScrollView.isHidden   = false
//        carouselPageControl.isHidden  = false
// 
//        UIView.animate(withDuration: 0.38, delay: 0,
//                       usingSpringWithDamping: 0.82, initialSpringVelocity: 0.2,
//                       options: .curveEaseInOut) {
//            self.balanceLabel.alpha    = 1
//            self.searchIconBtn.alpha   = 1
//            self.plusBtn.alpha         = 1
//            self.searchTextField.alpha = 0
//            self.closeSearchBtn.alpha  = 0
//            self.carouselHeightConstraint.constant = 320
//            self.carouselScrollView.alpha   = 1
//            self.carouselPageControl.alpha  = 1
//            self.view.layoutIfNeeded()
//        } completion: { _ in
//            self.searchTextField.isHidden = true
//            self.closeSearchBtn.isHidden  = true
//            self.viewModel.reloadFromLocal()
//        }
//    }
// 
//    // MARK: - Actions
// 
//    @objc private func addTapped() {
//        let addVC = AddTransactionViewController()
//        navigationController?.pushViewController(addVC, animated: true)
//    }
// 
//    @objc func timeFilterChanged() {
//        viewModel.setTimeSegmentIndex(timeSegmentControl.selectedSegmentIndex)
//    }
// 
//    // ✅ FIX: layoutIfNeeded olib tashlandi — tez ishlaydi
//    func updateTableViewHeight() {
//        let rows = groupedTransactions.reduce(0) { $0 + $1.transactions.count }
//        let sections = groupedTransactions.count
//        let rowH: CGFloat = 54
//        let headerH: CGFloat = 28
//        let minH: CGFloat = 120
//        let calculatedH = CGFloat(rows) * rowH + CGFloat(sections) * headerH
//        tableViewHeightConstraint?.constant = max(calculatedH, minH)
//    }
//}
// 
//// MARK: - UIScrollViewDelegate
// 
//extension DashboardViewController: UIScrollViewDelegate {
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        guard scrollView === carouselScrollView else { return }
//        let w = carouselScrollView.bounds.width
//        guard w > 0 else { return }
//        carouselPageControl.currentPage = max(0, min(
//            Int((carouselScrollView.contentOffset.x + w / 2) / w), 1
//        ))
//    }
//}
// 
//// MARK: - UITextFieldDelegate
// 
//extension DashboardViewController: UITextFieldDelegate {
//    func textFieldDidChangeSelection(_ textField: UITextField) {
//        viewModel.setSearchQuery(textField.text ?? "")
//    }
//    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        textField.resignFirstResponder(); return true
//    }
//}


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
 
    // MARK: - Search + Filter Panel (carousel yonida emas, pastda alohida)
    private let searchFilterPanel = UIView()
    let searchTextField           = UITextField()
    private let closeSearchBtn    = UIButton(type: .system)
 
    // Filter pill buttons
    private let filterScrollView  = UIScrollView()
    private let filterStack       = UIStackView()
    private let categoryFilterBtn = UIButton(type: .system)
    private let dateFilterBtn     = UIButton(type: .system)
    private let clearFilterBtn    = UIButton(type: .system)
 
    // Filter panel height constraint — animatsiya uchun
    private var filterPanelHeightConstraint: NSLayoutConstraint!
    private var filterPillsHeightConstraint: NSLayoutConstraint!
 
    // MARK: - Carousel
    let carouselScrollView      = UIScrollView()
    var carouselPageControl     = UIPageControl()
    private let chartCard       = UIView()
    let pieChartView            = PieChartView()
    let timeSegmentControl      = UISegmentedControl(items: ["Kun", "Oy", "Yil"])
    var goalCard                = UIView()
 
    // MARK: - Chart navigation bar
    private let navBarView    = UIView()
    private let prevButton    = UIButton(type: .system)
    private let nextButton    = UIButton(type: .system)
    private let navTitleLabel = UILabel()
    private let todayButton   = UIButton(type: .system)
 
    // MARK: - Goal
    var goalCardView  = GoalCardView()
    var goalViewModel = GoalViewModel()
    var smartBanner   = SmartBannerView()
 
    // MARK: - Scroll content
    private var carouselHeightConstraint: NSLayoutConstraint!
    let scrollView  = UIScrollView()
    let contentView = UIView()
    let tableView   = UITableView(frame: .zero, style: .plain)
    var tableViewHeightConstraint: NSLayoutConstraint!
 
    // MARK: - State
    private var isSearchExpanded = false
    private var selectedCategory: String? = nil
    private var startDate: Date? = nil
    private var endDate: Date? = nil
 
    // Accent color
    private let accent = UIColor(red: 91/255, green: 173/255, blue: 198/255, alpha: 1)
 
    private let allCategories = [
        "Oziq-ovqat", "Transport", "Ijara",
        "Kiyim", "O'yin-kulgi", "Salomatlik", "Boshqa"
    ]
 
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
        buildSearchFilterPanel()
        buildCarousel()
        buildScrollContent()
        activateConstraints()
 
        setupGoalFeatures()
        loadGoalData()
 
        tableView.delegate   = self
        tableView.dataSource = self
        tableView.isScrollEnabled = false
        searchTextField.delegate  = self
    }
 
    private var didSetupCards = false
 
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !didSetupCards, carouselScrollView.bounds.width > 50 else { return }
        didSetupCards = true
        setupCarouselCards(cardH: 320)
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
            pieChartView.animate(xAxisDuration: 0.5, yAxisDuration: 0.5, easingOption: .easeInOutQuad)
        }
 
        updateNavBarUI()
        tableView.reloadData()
        DispatchQueue.main.async { [weak self] in
            self?.updateTableViewHeight()
        }
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
        plusBtn.backgroundColor    = accent
        plusBtn.layer.cornerRadius = 16
        plusBtn.translatesAutoresizingMaskIntoConstraints = false
        plusBtn.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
 
        [sep, balanceLabel, searchIconBtn, plusBtn].forEach { navContainer.addSubview($0) }
 
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
 
            sep.bottomAnchor.constraint(equalTo: navContainer.bottomAnchor),
            sep.leadingAnchor.constraint(equalTo: navContainer.leadingAnchor),
            sep.trailingAnchor.constraint(equalTo: navContainer.trailingAnchor),
            sep.heightAnchor.constraint(equalToConstant: 0.5),
        ])
    }
 
    // MARK: - Build: Search + Filter panel
 
    private func buildSearchFilterPanel() {
        searchFilterPanel.backgroundColor = .systemBackground
        searchFilterPanel.isHidden = true
        searchFilterPanel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchFilterPanel)
 
        // ── Search TextField ──────────────────────────────────────
        searchTextField.placeholder = "Qidirish..."
        searchTextField.backgroundColor = .secondarySystemBackground
        searchTextField.layer.cornerRadius = 12
        searchTextField.returnKeyType = .search
        searchTextField.translatesAutoresizingMaskIntoConstraints = false
 
        let iconBox = UIView(frame: CGRect(x: 0, y: 0, width: 36, height: 36))
        let iconImg = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        iconImg.tintColor = .secondaryLabel
        iconImg.frame = CGRect(x: 10, y: 8, width: 18, height: 18)
        iconImg.contentMode = .scaleAspectFit
        iconBox.addSubview(iconImg)
        searchTextField.leftView = iconBox
        searchTextField.leftViewMode = .always
        searchTextField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
 
        let xConf = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        closeSearchBtn.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: xConf), for: .normal)
        closeSearchBtn.tintColor = .tertiaryLabel
        closeSearchBtn.translatesAutoresizingMaskIntoConstraints = false
        closeSearchBtn.addTarget(self, action: #selector(collapseSearch), for: .touchUpInside)
 
        // ── Filter Pills ──────────────────────────────────────────
        filterScrollView.showsHorizontalScrollIndicator = false
        filterScrollView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        filterScrollView.translatesAutoresizingMaskIntoConstraints = false
 
        filterStack.axis = .horizontal
        filterStack.spacing = 8
        filterStack.translatesAutoresizingMaskIntoConstraints = false
 
        // Category pill
        styleFilterPill(categoryFilterBtn, title: "Kategoriya", icon: "tag.fill", active: false)
        categoryFilterBtn.addTarget(self, action: #selector(showCategoryPicker), for: .touchUpInside)
 
        // Date pill
        styleFilterPill(dateFilterBtn, title: "Sana", icon: "calendar", active: false)
        dateFilterBtn.addTarget(self, action: #selector(showDatePicker), for: .touchUpInside)
 
        // Clear pill
        styleFilterPill(clearFilterBtn, title: "Tozalash", icon: "xmark.circle.fill", active: false)
        clearFilterBtn.isHidden = true
        clearFilterBtn.addTarget(self, action: #selector(clearAllFilters), for: .touchUpInside)
 
        [categoryFilterBtn, dateFilterBtn, clearFilterBtn].forEach {
            filterStack.addArrangedSubview($0)
        }
        filterScrollView.addSubview(filterStack)
 
        // Bottom separator
        let sep = UIView()
        sep.backgroundColor = UIColor.separator.withAlphaComponent(0.4)
        sep.translatesAutoresizingMaskIntoConstraints = false
 
        [searchTextField, closeSearchBtn, filterScrollView, sep].forEach {
            searchFilterPanel.addSubview($0)
        }
 
        filterPillsHeightConstraint = filterScrollView.heightAnchor.constraint(equalToConstant: 36)
 
        NSLayoutConstraint.activate([
            searchTextField.topAnchor.constraint(equalTo: searchFilterPanel.topAnchor, constant: 10),
            searchTextField.leadingAnchor.constraint(equalTo: searchFilterPanel.leadingAnchor, constant: 16),
            searchTextField.trailingAnchor.constraint(equalTo: closeSearchBtn.leadingAnchor, constant: -8),
            searchTextField.heightAnchor.constraint(equalToConstant: 40),
 
            closeSearchBtn.centerYAnchor.constraint(equalTo: searchTextField.centerYAnchor),
            closeSearchBtn.trailingAnchor.constraint(equalTo: searchFilterPanel.trailingAnchor, constant: -16),
            closeSearchBtn.widthAnchor.constraint(equalToConstant: 28),
            closeSearchBtn.heightAnchor.constraint(equalToConstant: 28),
 
            filterScrollView.topAnchor.constraint(equalTo: searchTextField.bottomAnchor, constant: 8),
            filterScrollView.leadingAnchor.constraint(equalTo: searchFilterPanel.leadingAnchor),
            filterScrollView.trailingAnchor.constraint(equalTo: searchFilterPanel.trailingAnchor),
            filterPillsHeightConstraint,
 
            filterStack.topAnchor.constraint(equalTo: filterScrollView.topAnchor),
            filterStack.bottomAnchor.constraint(equalTo: filterScrollView.bottomAnchor),
            filterStack.leadingAnchor.constraint(equalTo: filterScrollView.contentLayoutGuide.leadingAnchor),
            filterStack.trailingAnchor.constraint(equalTo: filterScrollView.contentLayoutGuide.trailingAnchor),
            filterStack.heightAnchor.constraint(equalTo: filterScrollView.frameLayoutGuide.heightAnchor),
 
            sep.bottomAnchor.constraint(equalTo: searchFilterPanel.bottomAnchor),
            sep.leadingAnchor.constraint(equalTo: searchFilterPanel.leadingAnchor),
            sep.trailingAnchor.constraint(equalTo: searchFilterPanel.trailingAnchor),
            sep.heightAnchor.constraint(equalToConstant: 0.5),
        ])
 
        // filterPanel bottom = filterScrollView bottom
        filterScrollView.bottomAnchor.constraint(equalTo: searchFilterPanel.bottomAnchor, constant: -8).isActive = true
    }
 
    private func styleFilterPill(_ btn: UIButton, title: String, icon: String, active: Bool) {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.image = UIImage(systemName: icon,
                               withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .medium))
        config.imagePadding = 5
        config.imagePlacement = .leading
        config.baseBackgroundColor = active ? accent : UIColor.secondarySystemBackground
        config.baseForegroundColor = active ? .white : .secondaryLabel
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var a = attrs; a.font = UIFont.systemFont(ofSize: 13, weight: .medium); return a
        }
        btn.configuration = config
        btn.translatesAutoresizingMaskIntoConstraints = false
    }
 
    private func updatePillStyle(_ btn: UIButton, title: String, icon: String, active: Bool) {
        var config = btn.configuration
        config?.title = title
        config?.image = UIImage(systemName: icon,
                                withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .medium))
        config?.baseBackgroundColor = active ? accent : UIColor.secondarySystemBackground
        config?.baseForegroundColor = active ? .white : .secondaryLabel
        btn.configuration = config
 
        if active {
            UIView.animate(withDuration: 0.2) {
                btn.transform = CGAffineTransform(scaleX: 1.04, y: 1.04)
            } completion: { _ in
                UIView.animate(withDuration: 0.15) { btn.transform = .identity }
            }
        }
    }
 
    // MARK: - Build: Carousel
 
    private func buildCarousel() {
        carouselScrollView.isPagingEnabled = true
        carouselScrollView.showsHorizontalScrollIndicator = false
        carouselScrollView.clipsToBounds = true
        carouselScrollView.delegate = self
        carouselScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(carouselScrollView)
 
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
 
        goalCard.backgroundColor    = .secondarySystemBackground
        goalCard.layer.cornerRadius = 20
        goalCard.translatesAutoresizingMaskIntoConstraints = false
        carouselScrollView.addSubview(goalCard)
 
        carouselPageControl.numberOfPages = 2
        carouselPageControl.pageIndicatorTintColor        = .tertiaryLabel
        carouselPageControl.currentPageIndicatorTintColor = accent
        carouselPageControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(carouselPageControl)
    }
 
    // MARK: - Chart nav bar
 
    private func buildChartNavBar() {
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
 
        smartBanner.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(smartBanner)
    }
 
    // MARK: - Constraints
 
    private func activateConstraints() {
        let cardH: CGFloat = 320
        carouselHeightConstraint = carouselScrollView.heightAnchor.constraint(equalToConstant: cardH)
        filterPanelHeightConstraint = searchFilterPanel.heightAnchor.constraint(equalToConstant: 0)
 
        NSLayoutConstraint.activate([
            // Nav
            navContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navContainer.heightAnchor.constraint(equalToConstant: 52),
 
            // Search/Filter panel — nav altında, carousel ustında
            searchFilterPanel.topAnchor.constraint(equalTo: navContainer.bottomAnchor),
            searchFilterPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchFilterPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            filterPanelHeightConstraint,
 
            // Carousel
            carouselScrollView.topAnchor.constraint(equalTo: searchFilterPanel.bottomAnchor, constant: 12),
            carouselScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            carouselScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            carouselHeightConstraint,
 
            carouselPageControl.topAnchor.constraint(equalTo: carouselScrollView.bottomAnchor, constant: 6),
            carouselPageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            carouselPageControl.heightAnchor.constraint(equalToConstant: 20),
 
            // Scroll view (transactions list)
            scrollView.topAnchor.constraint(equalTo: carouselPageControl.bottomAnchor, constant: 4),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
 
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
 
            smartBanner.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            smartBanner.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            smartBanner.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
 
            // Table view — smartBanner dan 10pt past, bo'shliq minimallashtrildi
            tableView.topAnchor.constraint(equalTo: smartBanner.bottomAnchor, constant: 4),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
 
        tableViewHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 400)
        tableViewHeightConstraint.isActive = true
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
 
    // MARK: - Search expand / collapse
 
    @objc func expandSearch() {
        guard !isSearchExpanded else { return }
        isSearchExpanded = true
 
        searchFilterPanel.isHidden = false
 
        // Qayta ochilganda pill ko'rinishlarini tiklash (oldingi filter holati)
        updateFilterPillStyles()
 
        UIView.animate(withDuration: 0.38, delay: 0,
                       usingSpringWithDamping: 0.82, initialSpringVelocity: 0.2,
                       options: .curveEaseInOut) {
            self.balanceLabel.alpha  = 0
            self.searchIconBtn.alpha = 0
            self.plusBtn.alpha       = 0
 
            self.carouselHeightConstraint.constant = 0
            self.carouselScrollView.alpha          = 0
            self.carouselPageControl.alpha         = 0
 
            self.filterPanelHeightConstraint.constant = 103
 
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
 
        // Hamma narsani tozalash — dastlabki holatga qaytarish
        selectedCategory = nil
        startDate        = nil
        endDate          = nil
        viewModel.setSearchQuery("")
        viewModel.setCategoryFilter(nil)
        viewModel.setDateRangeFilter(start: nil, end: nil)
        updateFilterPillStyles()
 
        searchTextField.resignFirstResponder()
        searchTextField.text = nil
 
        carouselScrollView.isHidden  = false
        carouselPageControl.isHidden = false
 
        UIView.animate(withDuration: 0.38, delay: 0,
                       usingSpringWithDamping: 0.82, initialSpringVelocity: 0.2,
                       options: .curveEaseInOut) {
            self.balanceLabel.alpha  = 1
            self.searchIconBtn.alpha = 1
            self.plusBtn.alpha       = 1
 
            self.carouselHeightConstraint.constant = 320
            self.carouselScrollView.alpha          = 1
            self.carouselPageControl.alpha         = 1
 
            self.filterPanelHeightConstraint.constant = 0
 
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.searchFilterPanel.isHidden = true
            self.viewModel.reloadFromLocal()
        }
    }
 
    // MARK: - Search text changed
 
    @objc private func searchTextChanged() {
        let text = searchTextField.text ?? ""
        viewModel.setSearchQuery(text)
    }
 
    // MARK: - Category filter
 
    @objc private func showCategoryPicker() {
        let alert = UIAlertController(title: "Kategoriya tanlang", message: nil, preferredStyle: .actionSheet)
 
        // Barchasi
        alert.addAction(UIAlertAction(title: selectedCategory == nil ? "✓ Barchasi" : "Barchasi", style: .default) { [weak self] _ in
            self?.selectedCategory = nil
            self?.viewModel.setCategoryFilter(nil)
            self?.updateFilterPillStyles()
        })
 
        for cat in allCategories {
            let title = (selectedCategory == cat) ? "✓ \(cat)" : cat
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.selectedCategory = cat
                self?.viewModel.setCategoryFilter(cat)
                self?.updateFilterPillStyles()
            })
        }
 
        alert.addAction(UIAlertAction(title: "Bekor qilish", style: .cancel))
 
        if let popover = alert.popoverPresentationController {
            popover.sourceView = categoryFilterBtn
            popover.sourceRect = categoryFilterBtn.bounds
        }
        present(alert, animated: true)
    }
 
    // MARK: - Date range filter
 
    @objc private func showDatePicker() {
        let vc = DateRangePickerViewController()
        vc.initialStartDate = startDate
        vc.initialEndDate   = endDate
        vc.onConfirm = { [weak self] start, end in
            guard let self = self else { return }
            self.startDate = start
            self.endDate   = end
            self.viewModel.setDateRangeFilter(start: start, end: end)
            self.updateFilterPillStyles()
        }
        vc.modalPresentationStyle = .pageSheet
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
        present(vc, animated: true)
    }
 
    // MARK: - Clear filters
 
    @objc private func clearAllFilters() {
        selectedCategory = nil
        startDate = nil
        endDate   = nil
        viewModel.setCategoryFilter(nil)
        viewModel.setDateRangeFilter(start: nil, end: nil)
        updateFilterPillStyles()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
 
    // MARK: - Update pill styles
 
    private func updateFilterPillStyles() {
        let catActive = selectedCategory != nil
        let catTitle  = catActive ? (selectedCategory ?? "Kategoriya") : "Kategoriya"
        updatePillStyle(categoryFilterBtn, title: catTitle, icon: "tag.fill", active: catActive)
 
        let dateActive = startDate != nil || endDate != nil
        let dateTitle: String
        if let s = startDate, let e = endDate {
            let f = DateFormatter()
            f.dateFormat = "dd.MM"
            dateTitle = "\(f.string(from: s))–\(f.string(from: e))"
        } else if startDate != nil || endDate != nil {
            dateTitle = "Sana ✓"
        } else {
            dateTitle = "Sana"
        }
        updatePillStyle(dateFilterBtn, title: dateTitle, icon: "calendar", active: dateActive)
 
        let anyActive = catActive || dateActive
        clearFilterBtn.isHidden = !anyActive
        if anyActive {
            updatePillStyle(clearFilterBtn, title: "Tozalash", icon: "xmark.circle.fill", active: false)
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
        let rows     = groupedTransactions.reduce(0) { $0 + $1.transactions.count }
        let sections = groupedTransactions.count
        let rowH: CGFloat    = 54
        let headerH: CGFloat = 28
        let minH: CGFloat    = 80
        let calculatedH = CGFloat(rows) * rowH + CGFloat(sections) * headerH
        tableViewHeightConstraint?.constant = max(calculatedH, minH)
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
 
// MARK: - DateRangePickerViewController
 
final class DateRangePickerViewController: UIViewController {
 
    var initialStartDate: Date?
    var initialEndDate: Date?
    var onConfirm: ((Date?, Date?) -> Void)?
 
    private let accent = UIColor(red: 91/255, green: 173/255, blue: 198/255, alpha: 1)
 
    private let startPicker = UIDatePicker()
    private let endPicker   = UIDatePicker()
    private let startSwitch = UISwitch()
    private let endSwitch   = UISwitch()
 
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = "Sana oralig'i"
        setupUI()
    }
 
    private func setupUI() {
        let titleLabel = UILabel()
        titleLabel.text = "Sana oralig'ini tanlang"
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
 
        // ── Start date ────────────────────────────────────────────
        let startCard = makeCard()
        let startLabel = makeRowLabel("Dan (boshlang'ich)")
        startSwitch.isOn = initialStartDate != nil
        startSwitch.onTintColor = accent
        startSwitch.translatesAutoresizingMaskIntoConstraints = false
        startSwitch.addTarget(self, action: #selector(startSwitchChanged), for: .valueChanged)
 
        startPicker.datePickerMode = .date
        startPicker.preferredDatePickerStyle = .compact
        startPicker.tintColor = accent
        startPicker.isEnabled = startSwitch.isOn
        startPicker.alpha     = startSwitch.isOn ? 1 : 0.4
        startPicker.date      = initialStartDate ?? Date()
        startPicker.translatesAutoresizingMaskIntoConstraints = false
 
        let startRow = makeHRow(label: startLabel, control: startSwitch)
        startCard.addSubview(startRow)
        startCard.addSubview(startPicker)
 
        NSLayoutConstraint.activate([
            startRow.topAnchor.constraint(equalTo: startCard.topAnchor, constant: 14),
            startRow.leadingAnchor.constraint(equalTo: startCard.leadingAnchor, constant: 16),
            startRow.trailingAnchor.constraint(equalTo: startCard.trailingAnchor, constant: -16),
 
            startPicker.topAnchor.constraint(equalTo: startRow.bottomAnchor, constant: 10),
            startPicker.leadingAnchor.constraint(equalTo: startCard.leadingAnchor, constant: 16),
            startPicker.bottomAnchor.constraint(equalTo: startCard.bottomAnchor, constant: -14),
        ])
 
        // ── End date ──────────────────────────────────────────────
        let endCard = makeCard()
        let endLabel = makeRowLabel("Gacha (tugash)")
        endSwitch.isOn = initialEndDate != nil
        endSwitch.onTintColor = accent
        endSwitch.translatesAutoresizingMaskIntoConstraints = false
        endSwitch.addTarget(self, action: #selector(endSwitchChanged), for: .valueChanged)
 
        endPicker.datePickerMode = .date
        endPicker.preferredDatePickerStyle = .compact
        endPicker.tintColor = accent
        endPicker.isEnabled = endSwitch.isOn
        endPicker.alpha     = endSwitch.isOn ? 1 : 0.4
        endPicker.date      = initialEndDate ?? Date()
        endPicker.translatesAutoresizingMaskIntoConstraints = false
 
        let endRow = makeHRow(label: endLabel, control: endSwitch)
        endCard.addSubview(endRow)
        endCard.addSubview(endPicker)
 
        NSLayoutConstraint.activate([
            endRow.topAnchor.constraint(equalTo: endCard.topAnchor, constant: 14),
            endRow.leadingAnchor.constraint(equalTo: endCard.leadingAnchor, constant: 16),
            endRow.trailingAnchor.constraint(equalTo: endCard.trailingAnchor, constant: -16),
 
            endPicker.topAnchor.constraint(equalTo: endRow.bottomAnchor, constant: 10),
            endPicker.leadingAnchor.constraint(equalTo: endCard.leadingAnchor, constant: 16),
            endPicker.bottomAnchor.constraint(equalTo: endCard.bottomAnchor, constant: -14),
        ])
 
        // ── Confirm button ────────────────────────────────────────
        let confirmBtn = UIButton(type: .system)
        confirmBtn.setTitle("Qo'llash", for: .normal)
        confirmBtn.setTitleColor(.white, for: .normal)
        confirmBtn.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        confirmBtn.backgroundColor = accent
        confirmBtn.layer.cornerRadius = 14
        confirmBtn.translatesAutoresizingMaskIntoConstraints = false
        confirmBtn.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
 
        let clearBtn = UIButton(type: .system)
        clearBtn.setTitle("Filterni tozalash", for: .normal)
        clearBtn.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        clearBtn.setTitleColor(.systemRed, for: .normal)
        clearBtn.translatesAutoresizingMaskIntoConstraints = false
        clearBtn.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
 
        [titleLabel, startCard, endCard, confirmBtn, clearBtn].forEach { view.addSubview($0) }
 
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
 
            startCard.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            startCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            startCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
 
            endCard.topAnchor.constraint(equalTo: startCard.bottomAnchor, constant: 12),
            endCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            endCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
 
            confirmBtn.topAnchor.constraint(equalTo: endCard.bottomAnchor, constant: 24),
            confirmBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            confirmBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            confirmBtn.heightAnchor.constraint(equalToConstant: 54),
 
            clearBtn.topAnchor.constraint(equalTo: confirmBtn.bottomAnchor, constant: 10),
            clearBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
 
    private func makeCard() -> UIView {
        let v = UIView()
        v.backgroundColor    = .secondarySystemGroupedBackground
        v.layer.cornerRadius = 16
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }
 
    private func makeRowLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 15, weight: .medium)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }
 
    private func makeHRow(label: UILabel, control: UIView) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(label)
        row.addSubview(control)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            control.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            control.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            row.heightAnchor.constraint(equalToConstant: 32),
        ])
        return row
    }
 
    @objc private func startSwitchChanged() {
        startPicker.isEnabled = startSwitch.isOn
        UIView.animate(withDuration: 0.2) {
            self.startPicker.alpha = self.startSwitch.isOn ? 1 : 0.4
        }
    }
 
    @objc private func endSwitchChanged() {
        endPicker.isEnabled = endSwitch.isOn
        UIView.animate(withDuration: 0.2) {
            self.endPicker.alpha = self.endSwitch.isOn ? 1 : 0.4
        }
    }
 
    @objc private func confirmTapped() {
        let start = startSwitch.isOn ? startPicker.date : nil
        let end   = endSwitch.isOn   ? endPicker.date   : nil
        onConfirm?(start, end)
        dismiss(animated: true)
    }
 
    @objc private func clearTapped() {
        onConfirm?(nil, nil)
        dismiss(animated: true)
    }
}
