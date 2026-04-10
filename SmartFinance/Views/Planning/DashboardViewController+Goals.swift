// DashboardViewController+Goals.swift
// SmartFinance
// Dashboard'ga byudjet rejasi integratsiyasi
 
import UIKit
 
extension DashboardViewController {
 
    // MARK: - Setup
 
    func setupGoalFeatures() {
        // goalCard ichiga goalCardView ni joylashtirish
        goalCardView.translatesAutoresizingMaskIntoConstraints = false
        goalCard.addSubview(goalCardView)
 
        NSLayoutConstraint.activate([
            goalCardView.topAnchor.constraint(equalTo: goalCard.topAnchor),
            goalCardView.leadingAnchor.constraint(equalTo: goalCard.leadingAnchor),
            goalCardView.trailingAnchor.constraint(equalTo: goalCard.trailingAnchor),
            goalCardView.bottomAnchor.constraint(equalTo: goalCard.bottomAnchor),
        ])
 
        goalCardView.onCreateTapped = { [weak self] in self?.openBudgetPlanVC(editing: false) }
        goalCardView.onEditTapped   = { [weak self] in self?.openBudgetPlanVC(editing: true) }
 
        goalViewModel.onPlanChanged = { [weak self] in
            DispatchQueue.main.async { self?.refreshGoalUI() }
        }
 
        // SmartBanner (ogohlantirishlar chizg'i) — warningContainerView o'rnini bosadi
        smartBanner.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(smartBanner)
 
        NSLayoutConstraint.activate([
            smartBanner.topAnchor.constraint(equalTo: warningContainerView.bottomAnchor, constant: 6),
            smartBanner.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            smartBanner.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        ])
 
        // tableView top-ni smartBanner ga bog'lash
        // (aktivatsiya qilingan constraints-lari mavjud bo'lgani uchun bu yerda yangilash shart emas)
    }
 
    // MARK: - Refresh
 
    func loadGoalData() {
        goalViewModel.load()
    }
 
    func refreshGoalUI() {
        if let plan = goalViewModel.plan, !plan.isExpired {
            // Tranzaksiyalarni sinxronlash
            goalViewModel.syncSpent(transactions: viewModel.allTransactions)
            if let updated = goalViewModel.plan {
                goalCardView.configure(with: updated)
                smartBanner.configure(with: updated)
            }
        } else {
            goalCardView.showEmpty()
            smartBanner.hide()
        }
    }
 
    // MARK: - Open VC
 
    func openBudgetPlanVC(editing: Bool) {
        let vc = BudgetPlanViewController()
        vc.existingPlan = editing ? goalViewModel.plan : nil
        vc.onSave = { [weak self] plan in
            guard let self = self else { return }
            // totalAmount == 0 → delete signal
            if plan.totalAmount == 0 {
                self.goalViewModel.deletePlan()
            } else {
                self.goalViewModel.savePlan(plan)
            }
            self.refreshGoalUI()
        }
        navigationController?.pushViewController(vc, animated: true)
    }
}
 
// MARK: - SmartBannerView (ogohlantirishlar chizg'isi)
 
final class SmartBannerView: UIView {
 
    private let accentColor = UIColor(red: 91/255, green: 173/255, blue: 198/255, alpha: 1)
    private let iconView  = UIImageView()
    private let msgLabel  = UILabel()
    private var heightConstraint: NSLayoutConstraint!
 
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 12
        clipsToBounds = true
 
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
 
        msgLabel.font = .systemFont(ofSize: 13, weight: .medium)
        msgLabel.numberOfLines = 2
        msgLabel.translatesAutoresizingMaskIntoConstraints = false
 
        addSubview(iconView)
        addSubview(msgLabel)
 
        heightConstraint = heightAnchor.constraint(equalToConstant: 0)
        heightConstraint.isActive = true
 
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 18),
            iconView.heightAnchor.constraint(equalToConstant: 18),
 
            msgLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            msgLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            msgLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            msgLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
 
    func configure(with plan: BudgetPlan) {
        let over = plan.categoryLimits.filter { $0.isOverBudget }
        let warn = plan.categoryLimits.filter { $0.percentSpent >= 80 && !$0.isOverBudget }
 
        if !over.isEmpty {
            backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
            iconView.image = UIImage(systemName: "exclamationmark.triangle.fill")?
                .withTintColor(.systemRed, renderingMode: .alwaysOriginal)
            msgLabel.textColor = .systemRed
            let names = over.map { "\($0.categoryName) (\(Int($0.percentSpent))%)" }.joined(separator: ", ")
            msgLabel.text = "Limitdan oshdi: \(names). Xarajatni kamaytiring!"
            show()
        } else if !warn.isEmpty {
            backgroundColor = UIColor.systemOrange.withAlphaComponent(0.1)
            iconView.image = UIImage(systemName: "chart.bar.fill")?
                .withTintColor(.systemOrange, renderingMode: .alwaysOriginal)
            msgLabel.textColor = .systemOrange
            let names = warn.map { "\($0.categoryName) (\(Int($0.percentSpent))%)" }.joined(separator: ", ")
            msgLabel.text = "Limitga yaqin: \(names). Ehtiyot bo'ling!"
            show()
        } else if plan.remainingDays <= 3 {
            backgroundColor = accentColor.withAlphaComponent(0.1)
            iconView.image = UIImage(systemName: "clock.fill")?
                .withTintColor(accentColor, renderingMode: .alwaysOriginal)
            msgLabel.textColor = accentColor
            msgLabel.text = "Byudjet muddati \(plan.remainingDays) kunda tugaydi."
            show()
        } else {
            hide()
        }
    }
 
    func show() {
        UIView.animate(withDuration: 0.3) {
            self.heightConstraint.isActive = false
            self.alpha = 1
        }
    }
 
    func hide() {
        UIView.animate(withDuration: 0.3) {
            self.alpha = 0
            self.heightConstraint.isActive = true
        }
    }
}
