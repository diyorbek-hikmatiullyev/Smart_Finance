// SmartBannerView.swift
// SmartFinance

import UIKit

// MARK: - Delegate

protocol SmartBannerViewDelegate: AnyObject {
    func smartBannerDidTapAddGoal()
    func smartBannerDidTapAddTransaction()
}

// MARK: - SmartBannerView

final class SmartBannerView: UIView {

    weak var delegate: SmartBannerViewDelegate?

    // MARK: - UI
    private let mainRow     = UIView()
    private let iconLabel   = UILabel()
    private let mainLabel   = UILabel()
    private let chevronView = UIImageView()

    private let expandedView = UIView()
    private let suggestStack = UIStackView()
    private let actionStack  = UIStackView()
    private let goalButton   = UIButton(type: .system)
    private let addButton    = UIButton(type: .system)

    // MARK: - State
    private(set) var isExpanded = false
    private var currentType: SmartBannerType = .safe

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setup() {
        layer.cornerRadius = 14
        clipsToBounds      = true
        translatesAutoresizingMaskIntoConstraints = false

        setupMainRow()
        setupExpandedView()

        let tap = UITapGestureRecognizer(target: self, action: #selector(toggleExpanded))
        mainRow.addGestureRecognizer(tap)
        mainRow.isUserInteractionEnabled = true
    }

    private func setupMainRow() {
        mainRow.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mainRow)

        iconLabel.font = .systemFont(ofSize: 16)
        iconLabel.translatesAutoresizingMaskIntoConstraints = false

        mainLabel.font          = .systemFont(ofSize: 14, weight: .medium)
        mainLabel.numberOfLines = 1
        mainLabel.lineBreakMode = .byTruncatingTail
        mainLabel.translatesAutoresizingMaskIntoConstraints = false

        let chevConf = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        chevronView.image       = UIImage(systemName: "chevron.down", withConfiguration: chevConf)
        chevronView.tintColor   = .secondaryLabel
        chevronView.contentMode = .scaleAspectFit
        chevronView.translatesAutoresizingMaskIntoConstraints = false

        [iconLabel, mainLabel, chevronView].forEach { mainRow.addSubview($0) }

        NSLayoutConstraint.activate([
            mainRow.topAnchor.constraint(equalTo: topAnchor),
            mainRow.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainRow.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainRow.heightAnchor.constraint(equalToConstant: 46),

            iconLabel.leadingAnchor.constraint(equalTo: mainRow.leadingAnchor, constant: 14),
            iconLabel.centerYAnchor.constraint(equalTo: mainRow.centerYAnchor),
            iconLabel.widthAnchor.constraint(equalToConstant: 24),

            chevronView.trailingAnchor.constraint(equalTo: mainRow.trailingAnchor, constant: -14),
            chevronView.centerYAnchor.constraint(equalTo: mainRow.centerYAnchor),
            chevronView.widthAnchor.constraint(equalToConstant: 16),
            chevronView.heightAnchor.constraint(equalToConstant: 16),

            mainLabel.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 8),
            mainLabel.trailingAnchor.constraint(equalTo: chevronView.leadingAnchor, constant: -8),
            mainLabel.centerYAnchor.constraint(equalTo: mainRow.centerYAnchor),
        ])
    }

    private func setupExpandedView() {
        expandedView.translatesAutoresizingMaskIntoConstraints = false
        expandedView.alpha  = 0
        expandedView.isHidden = true
        addSubview(expandedView)

        let sep = UIView()
        sep.backgroundColor = UIColor.separator.withAlphaComponent(0.4)
        sep.translatesAutoresizingMaskIntoConstraints = false
        expandedView.addSubview(sep)

        suggestStack.axis      = .vertical
        suggestStack.spacing   = 8
        suggestStack.translatesAutoresizingMaskIntoConstraints = false
        expandedView.addSubview(suggestStack)

        var goalConfig = UIButton.Configuration.filled()
        goalConfig.title               = "🎯 Maqsad qo'y"
        goalConfig.cornerStyle         = .large
        goalConfig.baseBackgroundColor = UIColor(red: 91/255, green: 173/255, blue: 198/255, alpha: 1)
        goalConfig.buttonSize          = .small
        goalButton.configuration       = goalConfig
        goalButton.addTarget(self, action: #selector(goalTapped), for: .touchUpInside)

        var addConfig = UIButton.Configuration.tinted()
        addConfig.title        = "💰 Daromad qo'sh"
        addConfig.cornerStyle  = .large
        addConfig.buttonSize   = .small
        addButton.configuration = addConfig
        addButton.addTarget(self, action: #selector(addTransactionTapped), for: .touchUpInside)

        actionStack.axis         = .horizontal
        actionStack.spacing      = 10
        actionStack.distribution = .fillEqually
        actionStack.translatesAutoresizingMaskIntoConstraints = false
        [goalButton, addButton].forEach { actionStack.addArrangedSubview($0) }
        expandedView.addSubview(actionStack)

        NSLayoutConstraint.activate([
            expandedView.topAnchor.constraint(equalTo: mainRow.bottomAnchor),
            expandedView.leadingAnchor.constraint(equalTo: leadingAnchor),
            expandedView.trailingAnchor.constraint(equalTo: trailingAnchor),
            expandedView.bottomAnchor.constraint(equalTo: bottomAnchor),

            sep.topAnchor.constraint(equalTo: expandedView.topAnchor),
            sep.leadingAnchor.constraint(equalTo: expandedView.leadingAnchor, constant: 14),
            sep.trailingAnchor.constraint(equalTo: expandedView.trailingAnchor, constant: -14),
            sep.heightAnchor.constraint(equalToConstant: 0.5),

            suggestStack.topAnchor.constraint(equalTo: sep.bottomAnchor, constant: 12),
            suggestStack.leadingAnchor.constraint(equalTo: expandedView.leadingAnchor, constant: 14),
            suggestStack.trailingAnchor.constraint(equalTo: expandedView.trailingAnchor, constant: -14),

            actionStack.topAnchor.constraint(equalTo: suggestStack.bottomAnchor, constant: 14),
            actionStack.leadingAnchor.constraint(equalTo: expandedView.leadingAnchor, constant: 14),
            actionStack.trailingAnchor.constraint(equalTo: expandedView.trailingAnchor, constant: -14),
            actionStack.heightAnchor.constraint(equalToConstant: 38),
            actionStack.bottomAnchor.constraint(equalTo: expandedView.bottomAnchor, constant: -14),
        ])
    }

    // MARK: - Configure

    func configure(with info: SmartBannerInfo) {
        currentType = info.type
        updateColors()

        switch info.type {
        case .danger:  iconLabel.text = "🚨"
        case .warning: iconLabel.text = "⚠️"
        case .safe:    iconLabel.text = "✅"
        }

        mainLabel.text = stripEmoji(from: info.mainMessage)

        suggestStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for suggestion in info.suggestions {
            suggestStack.addArrangedSubview(makeSuggestionRow(text: suggestion))
        }

        chevronView.isHidden = (info.type == .safe && info.suggestions.isEmpty)
    }

    private func stripEmoji(from text: String) -> String {
        let stripped = text.trimmingCharacters(in: .whitespaces)
        let first = stripped.prefix(2)
        if first.contains("🚨") || first.contains("⚠️") || first.contains("✅") {
            return String(stripped.dropFirst(2)).trimmingCharacters(in: .whitespaces)
        }
        return stripped
    }

    private func makeSuggestionRow(text: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let bullet = UIView()
        bullet.backgroundColor    = mainLabel.textColor.withAlphaComponent(0.6)
        bullet.layer.cornerRadius = 3
        bullet.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text          = text
        label.font          = .systemFont(ofSize: 13)
        label.textColor     = mainLabel.textColor
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false

        [bullet, label].forEach { container.addSubview($0) }
        NSLayoutConstraint.activate([
            bullet.topAnchor.constraint(equalTo: label.topAnchor, constant: 5),
            bullet.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            bullet.widthAnchor.constraint(equalToConstant: 6),
            bullet.heightAnchor.constraint(equalToConstant: 6),

            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.leadingAnchor.constraint(equalTo: bullet.trailingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        return container
    }

    private func updateColors() {
        switch currentType {
        case .danger:
            backgroundColor     = UIColor.systemRed.withAlphaComponent(0.12)
            mainLabel.textColor = .systemRed
        case .warning:
            backgroundColor     = UIColor.systemOrange.withAlphaComponent(0.12)
            mainLabel.textColor = UIColor(red: 0.8, green: 0.4, blue: 0.0, alpha: 1)
        case .safe:
            backgroundColor     = UIColor.systemGreen.withAlphaComponent(0.12)
            mainLabel.textColor = .systemGreen
        }
    }

    // MARK: - Toggle

    @objc func toggleExpanded() {
        isExpanded.toggle()
        let imgName = isExpanded ? "chevron.up" : "chevron.down"
        let chevConf = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        chevronView.image = UIImage(systemName: imgName, withConfiguration: chevConf)

        if isExpanded { expandedView.isHidden = false }

        UIView.animate(withDuration: 0.32, delay: 0,
                       usingSpringWithDamping: 0.82, initialSpringVelocity: 0.2) {
            self.expandedView.alpha = self.isExpanded ? 1 : 0
            self.superview?.layoutIfNeeded()
        } completion: { _ in
            if !self.isExpanded { self.expandedView.isHidden = true }
        }
    }

    func collapse() {
        guard isExpanded else { return }
        isExpanded = false
        expandedView.alpha  = 0
        expandedView.isHidden = true
        let chevConf = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        chevronView.image = UIImage(systemName: "chevron.down", withConfiguration: chevConf)
    }

    // MARK: - Actions

    @objc private func goalTapped() {
        collapse()
        delegate?.smartBannerDidTapAddGoal()
    }

    @objc private func addTransactionTapped() {
        collapse()
        delegate?.smartBannerDidTapAddTransaction()
    }
}
