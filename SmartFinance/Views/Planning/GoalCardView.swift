// GoalCardView.swift
// SmartFinance
// Byudjet rejasi kartasi — carousel 2-slayd
 
import UIKit
 
final class GoalCardView: UIView {
 
    private let accentColor = UIColor(red: 91/255, green: 173/255, blue: 198/255, alpha: 1)
 
    // MARK: - Empty state
    private let emptyIconView   = UIImageView()
    private let emptyTitleLabel = UILabel()
    private let emptySubLabel   = UILabel()
    private let createButton    = UIButton(type: .system)
 
    // MARK: - Plan state
    private let scrollView    = UIScrollView()
    private let planStack     = UIStackView()
    private let headerView    = UIView()
    private let planTitleLabel = UILabel()
    private let editButton    = UIButton(type: .system)
    private let deadlineLabel = UILabel()
    private let timeBarBg     = UIView()
    private let timeBarFill   = UIView()
    private let balanceLabel  = UILabel()
    private let warningBanner = UIView()
    private let warningLabel  = UILabel()
    private let categoryContainer = UIView()
 
    // timeBarFill width constraint — animate uchun
    private var timeBarFillWidth: NSLayoutConstraint?
 
    var onCreateTapped: (() -> Void)?
    var onEditTapped:   (() -> Void)?
 
    // MARK: - Init
 
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor    = .secondarySystemBackground
        layer.cornerRadius = 20
        clipsToBounds      = true
        setupEmptyState()
        setupPlanState()
        showEmptyState()
    }
    required init?(coder: NSCoder) { fatalError() }
 
    // MARK: - Empty
 
    private func setupEmptyState() {
        let conf = UIImage.SymbolConfiguration(pointSize: 32, weight: .light)
        emptyIconView.image = UIImage(systemName: "chart.pie", withConfiguration: conf)
        emptyIconView.tintColor = accentColor.withAlphaComponent(0.5)
        emptyIconView.contentMode = .scaleAspectFit
        emptyIconView.translatesAutoresizingMaskIntoConstraints = false
 
        emptyTitleLabel.text = "Byudjet rejasi yo'q"
        emptyTitleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        emptyTitleLabel.textAlignment = .center
        emptyTitleLabel.translatesAutoresizingMaskIntoConstraints = false
 
        emptySubLabel.text = "Kategoriyalar bo'yicha\npul taqsimotini aniqlang"
        emptySubLabel.font = .systemFont(ofSize: 13)
        emptySubLabel.textColor = .secondaryLabel
        emptySubLabel.textAlignment = .center
        emptySubLabel.numberOfLines = 2
        emptySubLabel.translatesAutoresizingMaskIntoConstraints = false
 
        var cfg = UIButton.Configuration.filled()
        cfg.title = "Reja tuzish"
        cfg.image = UIImage(systemName: "plus.circle.fill",
                            withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .medium))
        cfg.imagePadding = 6
        cfg.imagePlacement = .leading
        cfg.baseBackgroundColor = accentColor
        cfg.baseForegroundColor = .white
        cfg.cornerStyle = .large
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20)
        createButton.configuration = cfg
        createButton.translatesAutoresizingMaskIntoConstraints = false
        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
 
        [emptyIconView, emptyTitleLabel, emptySubLabel, createButton].forEach { addSubview($0) }
 
        NSLayoutConstraint.activate([
            emptyIconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            emptyIconView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -52),
            emptyIconView.widthAnchor.constraint(equalToConstant: 52),
            emptyIconView.heightAnchor.constraint(equalToConstant: 52),
 
            emptyTitleLabel.topAnchor.constraint(equalTo: emptyIconView.bottomAnchor, constant: 12),
            emptyTitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
 
            emptySubLabel.topAnchor.constraint(equalTo: emptyTitleLabel.bottomAnchor, constant: 6),
            emptySubLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
 
            createButton.topAnchor.constraint(equalTo: emptySubLabel.bottomAnchor, constant: 18),
            createButton.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
    }
 
    // MARK: - Plan state setup
 
    private func setupPlanState() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
 
        planStack.axis    = .vertical
        planStack.spacing = 8
        planStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(planStack)
 
        setupHeader()
        setupWarningBanner()
 
        categoryContainer.translatesAutoresizingMaskIntoConstraints = false
 
        planStack.addArrangedSubview(headerView)
        planStack.addArrangedSubview(warningBanner)
        planStack.addArrangedSubview(categoryContainer)
 
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
 
            planStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 14),
            planStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 14),
            planStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -14),
            planStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -14),
            planStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -28),
        ])
    }
 
    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
 
        planTitleLabel.text = "Byudjet rejasi"
        planTitleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        planTitleLabel.translatesAutoresizingMaskIntoConstraints = false
 
        let penConf = UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        editButton.setImage(UIImage(systemName: "pencil.circle.fill", withConfiguration: penConf), for: .normal)
        editButton.tintColor = accentColor
        editButton.translatesAutoresizingMaskIntoConstraints = false
        editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
 
        deadlineLabel.font = .systemFont(ofSize: 11)
        deadlineLabel.textColor = .secondaryLabel
        deadlineLabel.translatesAutoresizingMaskIntoConstraints = false
 
        balanceLabel.font = .systemFont(ofSize: 11, weight: .medium)
        balanceLabel.textColor = .secondaryLabel
        balanceLabel.textAlignment = .right
        balanceLabel.translatesAutoresizingMaskIntoConstraints = false
 
        // Time progress bar
        timeBarBg.backgroundColor = UIColor.systemGray5
        timeBarBg.layer.cornerRadius = 3
        timeBarBg.clipsToBounds = true
        timeBarBg.translatesAutoresizingMaskIntoConstraints = false
 
        timeBarFill.backgroundColor = accentColor.withAlphaComponent(0.7)
        timeBarFill.layer.cornerRadius = 3
        timeBarFill.translatesAutoresizingMaskIntoConstraints = false
        timeBarBg.addSubview(timeBarFill)
 
        [planTitleLabel, editButton, deadlineLabel, balanceLabel, timeBarBg]
            .forEach { headerView.addSubview($0) }
 
        // timeBarFill constraints — width proportional
        timeBarFillWidth = timeBarFill.widthAnchor.constraint(equalTo: timeBarBg.widthAnchor, multiplier: 0)
 
        NSLayoutConstraint.activate([
            planTitleLabel.topAnchor.constraint(equalTo: headerView.topAnchor),
            planTitleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
 
            editButton.centerYAnchor.constraint(equalTo: planTitleLabel.centerYAnchor),
            editButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            editButton.widthAnchor.constraint(equalToConstant: 24),
            editButton.heightAnchor.constraint(equalToConstant: 24),
 
            balanceLabel.centerYAnchor.constraint(equalTo: planTitleLabel.centerYAnchor),
            balanceLabel.trailingAnchor.constraint(equalTo: editButton.leadingAnchor, constant: -6),
 
            deadlineLabel.topAnchor.constraint(equalTo: planTitleLabel.bottomAnchor, constant: 2),
            deadlineLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
 
            timeBarBg.topAnchor.constraint(equalTo: deadlineLabel.bottomAnchor, constant: 8),
            timeBarBg.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            timeBarBg.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            timeBarBg.heightAnchor.constraint(equalToConstant: 5),
            timeBarBg.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -2),
 
            timeBarFill.topAnchor.constraint(equalTo: timeBarBg.topAnchor),
            timeBarFill.leadingAnchor.constraint(equalTo: timeBarBg.leadingAnchor),
            timeBarFill.bottomAnchor.constraint(equalTo: timeBarBg.bottomAnchor),
            timeBarFillWidth!,
        ])
    }
 
    private func setupWarningBanner() {
        warningBanner.layer.cornerRadius = 10
        warningBanner.translatesAutoresizingMaskIntoConstraints = false
 
        warningLabel.font = .systemFont(ofSize: 12, weight: .medium)
        warningLabel.numberOfLines = 2
        warningLabel.translatesAutoresizingMaskIntoConstraints = false
        warningBanner.addSubview(warningLabel)
 
        NSLayoutConstraint.activate([
            warningLabel.topAnchor.constraint(equalTo: warningBanner.topAnchor, constant: 8),
            warningLabel.bottomAnchor.constraint(equalTo: warningBanner.bottomAnchor, constant: -8),
            warningLabel.leadingAnchor.constraint(equalTo: warningBanner.leadingAnchor, constant: 10),
            warningLabel.trailingAnchor.constraint(equalTo: warningBanner.trailingAnchor, constant: -10),
        ])
    }
 
    // MARK: - Configure
 
    func configure(with plan: BudgetPlan) {
        showPlanState()
 
        // Header
        let df = DateFormatter()
        df.dateFormat = "d MMM"
        df.locale = Locale(identifier: "uz_UZ")
        deadlineLabel.text = "\(plan.remainingDays) kun qoldi · \(df.string(from: plan.endDate)) gacha"
        balanceLabel.text  = "Taqsimlanmagan: \(formatCompact(plan.unallocated)) so'm"
        balanceLabel.textColor = plan.unallocated < 0 ? .systemRed : .secondaryLabel
 
        // Time bar — multiplier o'zgartirib bo'lmaydi, shuning uchun constraint almashtirish
        let pct = CGFloat(min(plan.timeProgressPercent, 100)) / 100
        timeBarFillWidth?.isActive = false
        timeBarFillWidth = timeBarFill.widthAnchor.constraint(equalTo: timeBarBg.widthAnchor, multiplier: max(pct, 0.01))
        timeBarFillWidth?.isActive = true
 
        // Warning banner
        let overCategories = plan.categoryLimits.filter { $0.isOverBudget }
        let warnCategories = plan.categoryLimits.filter { $0.percentSpent >= 80 && !$0.isOverBudget }
 
        if !overCategories.isEmpty {
            warningBanner.isHidden = false
            warningBanner.backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
            warningLabel.textColor = .systemRed
            let names = overCategories.map { $0.categoryName }.joined(separator: ", ")
            warningLabel.text = "⚠️ Limitdan oshdi: \(names)"
        } else if !warnCategories.isEmpty {
            warningBanner.isHidden = false
            warningBanner.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.1)
            warningLabel.textColor = .systemOrange
            let names = warnCategories.map { "\($0.categoryName) (\(Int($0.percentSpent))%)" }.joined(separator: ", ")
            warningLabel.text = "📊 Limitga yaqin: \(names)"
        } else {
            warningBanner.isHidden = true
        }
 
        // Category rows
        categoryContainer.subviews.forEach { $0.removeFromSuperview() }
        let catStack = UIStackView()
        catStack.axis    = .vertical
        catStack.spacing = 6
        catStack.translatesAutoresizingMaskIntoConstraints = false
        categoryContainer.addSubview(catStack)
 
        NSLayoutConstraint.activate([
            catStack.topAnchor.constraint(equalTo: categoryContainer.topAnchor),
            catStack.leadingAnchor.constraint(equalTo: categoryContainer.leadingAnchor),
            catStack.trailingAnchor.constraint(equalTo: categoryContainer.trailingAnchor),
            catStack.bottomAnchor.constraint(equalTo: categoryContainer.bottomAnchor),
        ])
 
        for limit in plan.categoryLimits {
            catStack.addArrangedSubview(makeCategoryRow(limit: limit))
        }
 
        layoutIfNeeded()
    }
 
    // MARK: - Category row
    // ✅ FIX: Progress bar width — Auto Layout multiplier bilan to'g'ri hisoblash
 
    private func makeCategoryRow(limit: BudgetPlan.CategoryLimit) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
 
        let meta = GoalViewModel.categoryMeta.first { $0.name == limit.categoryName }
        let iconConf = UIImage.SymbolConfiguration(pointSize: 11, weight: .medium)
 
        // Icon
        let iconView = UIImageView()
        iconView.image = UIImage(systemName: meta?.icon ?? "square.fill", withConfiguration: iconConf)
        iconView.tintColor = accentColor
        iconView.translatesAutoresizingMaskIntoConstraints = false
 
        // Name
        let nameLabel = UILabel()
        nameLabel.text = limit.categoryName
        nameLabel.font = .systemFont(ofSize: 12, weight: .medium)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
 
        // Percent badge
        let pct = Int(min(limit.percentSpent, 100))
        let pctLabel = UILabel()
        pctLabel.text = "\(pct)%"
        pctLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        pctLabel.textColor = limit.isOverBudget ? .systemRed : (pct >= 80 ? .systemOrange : accentColor)
        pctLabel.translatesAutoresizingMaskIntoConstraints = false
 
        // Amount right side
        let amtLabel = UILabel()
        amtLabel.text = "\(formatCompact(limit.spent)) / \(formatCompact(limit.limitAmount))"
        amtLabel.font = .systemFont(ofSize: 11)
        amtLabel.textColor = .secondaryLabel
        amtLabel.textAlignment = .right
        amtLabel.translatesAutoresizingMaskIntoConstraints = false
 
        // Progress bar background
        let barBg = UIView()
        barBg.backgroundColor    = UIColor.systemGray5
        barBg.layer.cornerRadius = 3
        barBg.clipsToBounds      = true
        barBg.translatesAutoresizingMaskIntoConstraints = false
 
        // Progress bar fill
        let barFill = UIView()
        let fillColor: UIColor = limit.isOverBudget ? .systemRed : (pct >= 80 ? .systemOrange : accentColor)
        barFill.backgroundColor    = fillColor
        barFill.layer.cornerRadius = 3
        barFill.translatesAutoresizingMaskIntoConstraints = false
        barBg.addSubview(barFill)
 
        [iconView, nameLabel, pctLabel, amtLabel, barBg].forEach { container.addSubview($0) }
 
        // ✅ Fill fraction — 0.01 minimum shunday bo'lmasa constraint muammo
        let fraction = CGFloat(min(limit.percentSpent, 100)) / 100.0
        let safeFraction = max(fraction, 0.0)
 
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 46),
 
            // Top row: icon + name + pct | amt
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iconView.topAnchor.constraint(equalTo: container.topAnchor, constant: 6),
            iconView.widthAnchor.constraint(equalToConstant: 14),
            iconView.heightAnchor.constraint(equalToConstant: 14),
 
            nameLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 5),
            nameLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
 
            pctLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 5),
            pctLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
 
            amtLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            amtLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
 
            // Progress bar
            barBg.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            barBg.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            barBg.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -2),
            barBg.heightAnchor.constraint(equalToConstant: 6),
 
            // ✅ Fill — to'g'ri multiplier bilan
            barFill.topAnchor.constraint(equalTo: barBg.topAnchor),
            barFill.leadingAnchor.constraint(equalTo: barBg.leadingAnchor),
            barFill.bottomAnchor.constraint(equalTo: barBg.bottomAnchor),
            barFill.widthAnchor.constraint(equalTo: barBg.widthAnchor, multiplier: safeFraction),
        ])
 
        return container
    }
 
    // MARK: - State switching
 
    private func showEmptyState() {
        emptyIconView.isHidden   = false
        emptyTitleLabel.isHidden = false
        emptySubLabel.isHidden   = false
        createButton.isHidden    = false
        scrollView.isHidden      = true
    }
 
    private func showPlanState() {
        emptyIconView.isHidden   = true
        emptyTitleLabel.isHidden = true
        emptySubLabel.isHidden   = true
        createButton.isHidden    = true
        scrollView.isHidden      = false
    }
 
    func showEmpty() { showEmptyState() }
 
    // MARK: - Actions
    @objc private func createTapped() { onCreateTapped?() }
    @objc private func editTapped()   { onEditTapped?() }
 
    // MARK: - Format
    private func formatCompact(_ value: Double) -> String {
        if value >= 1_000_000 { return String(format: "%.1f mln", value / 1_000_000) }
        if value >= 1_000     { return String(format: "%.0f ming", value / 1_000) }
        return "\(Int(value))"
    }
}
