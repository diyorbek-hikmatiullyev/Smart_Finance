// GoalCardView.swift
// SmartFinance
// Carousel 2-slide: Oylik maqsad progress card

import UIKit

// MARK: - Delegate

protocol GoalCardViewDelegate: AnyObject {
    func goalCardDidTapAdd()
    func goalCardDidTapEdit()
    func goalCardDidTapDelete()
}

// MARK: - GoalCardView

final class GoalCardView: UIView {

    weak var delegate: GoalCardViewDelegate?

    // MARK: - UI

    // Empty state
    private let emptyStack      = UIStackView()
    private let emptyIconView   = UIImageView()
    private let emptyTitleLabel = UILabel()
    private let emptySubLabel   = UILabel()
    private let addButton       = UIButton(type: .system)

    // Goal state
    private let goalStack       = UIStackView()
    private let headerStack     = UIStackView()
    private let monthLabel      = UILabel()
    private let menuButton      = UIButton(type: .system)
    private let targetLabel     = UILabel()
    private let progressBar     = GoalProgressBar()
    private let statsStack      = UIStackView()
    private let savedLabel      = UILabel()
    private let remainLabel     = UILabel()
    private let daysLabel       = UILabel()
    private let dailyLabel      = UILabel()
    private let completedBadge  = UIView()

    // MARK: - Colors
    private let accent = UIColor(red: 91/255, green: 173/255, blue: 198/255, alpha: 1)

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setup() {
        backgroundColor    = .secondarySystemBackground
        layer.cornerRadius = 20
        clipsToBounds      = true

        setupEmptyState()
        setupGoalState()
        showEmpty()
    }

    // MARK: - Empty State

    private func setupEmptyState() {
        let iconConf = UIImage.SymbolConfiguration(pointSize: 36, weight: .light)
        emptyIconView.image       = UIImage(systemName: "target", withConfiguration: iconConf)
        emptyIconView.tintColor   = accent.withAlphaComponent(0.6)
        emptyIconView.contentMode = .scaleAspectFit

        emptyTitleLabel.text      = "Oylik maqsad yo'q"
        emptyTitleLabel.font      = .systemFont(ofSize: 16, weight: .semibold)
        emptyTitleLabel.textColor = .label
        emptyTitleLabel.textAlignment = .center

        emptySubLabel.text          = "Tejash maqsadi qo'ying va\nprogress kuzating"
        emptySubLabel.font          = .systemFont(ofSize: 13, weight: .regular)
        emptySubLabel.textColor     = .secondaryLabel
        emptySubLabel.textAlignment = .center
        emptySubLabel.numberOfLines = 2

        var btnConfig = UIButton.Configuration.filled()
        btnConfig.title           = "+ Maqsad qo'shish"
        btnConfig.cornerStyle     = .large
        btnConfig.baseBackgroundColor = accent
        btnConfig.buttonSize      = .medium
        addButton.configuration   = btnConfig
        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)

        emptyStack.axis      = .vertical
        emptyStack.spacing   = 10
        emptyStack.alignment = .center
        emptyStack.translatesAutoresizingMaskIntoConstraints = false
        [emptyIconView, emptyTitleLabel, emptySubLabel, addButton].forEach {
            emptyStack.addArrangedSubview($0)
        }
        emptyStack.setCustomSpacing(18, after: emptySubLabel)

        addSubview(emptyStack)
        NSLayoutConstraint.activate([
            emptyStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            emptyStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            emptyStack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 20),
            emptyStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20),
            emptyIconView.widthAnchor.constraint(equalToConstant: 52),
            emptyIconView.heightAnchor.constraint(equalToConstant: 52),
        ])
    }

    // MARK: - Goal State

    private func setupGoalState() {
        // Header: oy nomi + menu tugmasi
        monthLabel.font      = .systemFont(ofSize: 15, weight: .semibold)
        monthLabel.textColor = .label

        let menuConf = UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)
        menuButton.setImage(UIImage(systemName: "ellipsis.circle", withConfiguration: menuConf), for: .normal)
        menuButton.tintColor = .secondaryLabel
        menuButton.addTarget(self, action: #selector(menuTapped), for: .touchUpInside)

        headerStack.axis         = .horizontal
        headerStack.distribution = .equalSpacing
        headerStack.alignment    = .center
        [monthLabel, menuButton].forEach { headerStack.addArrangedSubview($0) }

        // Target label
        targetLabel.font      = .systemFont(ofSize: 28, weight: .heavy)
        targetLabel.textColor = accent
        targetLabel.textAlignment = .center

        // Progress bar
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.heightAnchor.constraint(equalToConstant: 14).isActive = true

        // Stats: 2x2 grid
        savedLabel.textAlignment = .left
        remainLabel.textAlignment = .right
        daysLabel.textAlignment  = .left
        dailyLabel.textAlignment = .right

        [savedLabel, remainLabel, daysLabel, dailyLabel].forEach {
            $0.font      = .systemFont(ofSize: 12, weight: .medium)
            $0.textColor = .secondaryLabel
            $0.numberOfLines = 1
        }

        let topStats = UIStackView(arrangedSubviews: [savedLabel, remainLabel])
        topStats.axis = .horizontal; topStats.distribution = .equalSpacing

        let botStats = UIStackView(arrangedSubviews: [daysLabel, dailyLabel])
        botStats.axis = .horizontal; botStats.distribution = .equalSpacing

        statsStack.axis    = .vertical
        statsStack.spacing = 4
        [topStats, botStats].forEach { statsStack.addArrangedSubview($0) }

        // Completed badge
        let checkConf = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        let checkImg  = UIImageView(image: UIImage(systemName: "checkmark.circle.fill", withConfiguration: checkConf))
        checkImg.tintColor = .white
        checkImg.translatesAutoresizingMaskIntoConstraints = false

        let badgeLabel = UILabel()
        badgeLabel.text      = "Maqsadga yetildi! 🎉"
        badgeLabel.font      = .systemFont(ofSize: 13, weight: .semibold)
        badgeLabel.textColor = .white
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false

        completedBadge.backgroundColor    = UIColor.systemGreen
        completedBadge.layer.cornerRadius = 12
        completedBadge.isHidden           = true
        completedBadge.translatesAutoresizingMaskIntoConstraints = false
        [checkImg, badgeLabel].forEach { completedBadge.addSubview($0) }
        NSLayoutConstraint.activate([
            checkImg.leadingAnchor.constraint(equalTo: completedBadge.leadingAnchor, constant: 12),
            checkImg.centerYAnchor.constraint(equalTo: completedBadge.centerYAnchor),
            checkImg.widthAnchor.constraint(equalToConstant: 18),
            checkImg.heightAnchor.constraint(equalToConstant: 18),
            badgeLabel.leadingAnchor.constraint(equalTo: checkImg.trailingAnchor, constant: 6),
            badgeLabel.trailingAnchor.constraint(equalTo: completedBadge.trailingAnchor, constant: -12),
            badgeLabel.centerYAnchor.constraint(equalTo: completedBadge.centerYAnchor),
            completedBadge.heightAnchor.constraint(equalToConstant: 36),
        ])

        // Main goal stack
        goalStack.axis      = .vertical
        goalStack.spacing   = 12
        goalStack.alignment = .fill
        goalStack.translatesAutoresizingMaskIntoConstraints = false
        [headerStack, targetLabel, progressBar, statsStack, completedBadge]
            .forEach { goalStack.addArrangedSubview($0) }

        addSubview(goalStack)
        NSLayoutConstraint.activate([
            goalStack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            goalStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            goalStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            goalStack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -20),
        ])
    }

    // MARK: - Configure

    func configure(with progress: GoalProgress?) {
        if let progress = progress {
            showGoal(progress: progress)
        } else {
            showEmpty()
        }
    }

    private func showEmpty() {
        emptyStack.isHidden = false
        goalStack.isHidden  = true
    }

    private func showGoal(progress: GoalProgress) {
        emptyStack.isHidden = true
        goalStack.isHidden  = false

        monthLabel.text  = "\(progress.goal.monthName) maqsadi"
        targetLabel.text = "\(formatSum(progress.goal.targetAmount)) so'm"

        // Progress bar animatsiya bilan
        progressBar.setProgress(CGFloat(progress.progressRatio), animated: true)

        // Stats
        savedLabel.text  = "✅ \(formatSum(progress.currentSaved)) tejaldi"
        remainLabel.text = "\(formatSum(progress.remaining)) qoldi"
        daysLabel.text   = "📅 \(progress.daysLeftInMonth) kun qoldi"

        if progress.dailySavingNeeded > 0 {
            dailyLabel.text = "Kuniga ~\(formatSum(progress.dailySavingNeeded)) so'm"
        } else {
            dailyLabel.text = ""
        }

        // Completed badge
        completedBadge.isHidden = !progress.isCompleted

        // Progress foiz rangi
        let color: UIColor
        switch progress.progressPercent {
        case 0..<30:   color = .systemRed
        case 30..<70:  color = .systemOrange
        case 70..<100: color = .systemYellow
        default:       color = .systemGreen
        }
        progressBar.progressColor = color
        targetLabel.textColor     = progress.isCompleted ? .systemGreen : accent
    }

    // MARK: - Actions

    @objc private func addTapped() {
        delegate?.goalCardDidTapAdd()
    }

    @objc private func menuTapped() {
        delegate?.goalCardDidTapEdit()
    }

    // MARK: - Helper

    private func formatSum(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle       = .decimal
        f.groupingSeparator = " "
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }
}

// MARK: - GoalProgressBar

final class GoalProgressBar: UIView {

    var progressColor: UIColor = UIColor(red: 91/255, green: 173/255, blue: 198/255, alpha: 1) {
        didSet { fillView.backgroundColor = progressColor }
    }

    private let trackView = UIView()
    private let fillView  = UIView()
    private let labelView = UILabel()
    private var fillWidthConstraint: NSLayoutConstraint?
    private var currentRatio: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 7
        clipsToBounds      = true

        trackView.backgroundColor = UIColor.systemGray5
        trackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(trackView)

        fillView.backgroundColor = progressColor
        fillView.layer.cornerRadius = 7
        fillView.translatesAutoresizingMaskIntoConstraints = false
        trackView.addSubview(fillView)

        NSLayoutConstraint.activate([
            trackView.topAnchor.constraint(equalTo: topAnchor),
            trackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            trackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trackView.trailingAnchor.constraint(equalTo: trailingAnchor),

            fillView.topAnchor.constraint(equalTo: trackView.topAnchor),
            fillView.bottomAnchor.constraint(equalTo: trackView.bottomAnchor),
            fillView.leadingAnchor.constraint(equalTo: trackView.leadingAnchor),
        ])

        fillWidthConstraint = fillView.widthAnchor.constraint(equalToConstant: 0)
        fillWidthConstraint?.isActive = true
    }

    required init?(coder: NSCoder) { fatalError() }

    func setProgress(_ ratio: CGFloat, animated: Bool) {
        currentRatio = ratio
        layoutIfNeeded()
        let targetWidth = bounds.width * ratio

        if animated {
            UIView.animate(withDuration: 0.8, delay: 0.1,
                           usingSpringWithDamping: 0.75, initialSpringVelocity: 0.3) {
                self.fillWidthConstraint?.constant = targetWidth
                self.layoutIfNeeded()
            }
        } else {
            fillWidthConstraint?.constant = targetWidth
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // bounds o'zgarganda progress ni qayta hisoblash
        fillWidthConstraint?.constant = bounds.width * currentRatio
    }
}

