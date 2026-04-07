// DashboardViewController+Goals.swift
// SmartFinance
// DashboardViewController ga GoalCard + SmartBanner integratsiyasi

import UIKit

// MARK: - GoalCard Delegate

extension DashboardViewController: GoalCardViewDelegate {

    func goalCardDidTapAdd() {
        openGoalSetup(existingGoal: nil)
    }

    func goalCardDidTapEdit() {
        openGoalSetup(existingGoal: goalViewModel.currentGoal)
    }

    func goalCardDidTapDelete() {
        let alert = UIAlertController(
            title: "Maqsadni o'chirish",
            message: "Bu oylik maqsadni o'chirishni tasdiqlaysizmi?",
            preferredStyle: .actionSheet
        )
        alert.addAction(UIAlertAction(title: "O'chirish", style: .destructive) { [weak self] _ in
            self?.goalViewModel.deleteGoal { error in
                DispatchQueue.main.async {
                    if error == nil {
                        self?.refreshGoalUI()
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                }
            }
        })
        alert.addAction(UIAlertAction(title: "Bekor qilish", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - GoalSetupSheet Delegate

extension DashboardViewController: GoalSetupSheetDelegate {

    func goalSetupDidSave(targetAmount: Double, note: String?) {
        goalViewModel.saveGoal(targetAmount: targetAmount, note: note) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    let a = UIAlertController(title: "Xato", message: error.localizedDescription, preferredStyle: .alert)
                    a.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(a, animated: true)
                } else {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    self?.refreshGoalUI()
                }
            }
        }
    }

    func goalSetupDidDelete() {
        goalViewModel.deleteGoal { [weak self] error in
            DispatchQueue.main.async {
                if error == nil {
                    self?.refreshGoalUI()
                }
            }
        }
    }

    func goalSetupDidCancel() {}
}

// MARK: - SmartBanner Delegate

extension DashboardViewController: SmartBannerViewDelegate {

    func smartBannerDidTapAddGoal() {
        let cw = carouselScrollView.bounds.width
        carouselScrollView.setContentOffset(CGPoint(x: cw, y: 0), animated: true)
        carouselPageControl.currentPage = 1
        openGoalSetup(existingGoal: nil)
    }

    func smartBannerDidTapAddTransaction() {
        let addVC = AddTransactionViewController()
        navigationController?.pushViewController(addVC, animated: true)
    }
}

// MARK: - Goal UI yangilash

extension DashboardViewController {

    func setupGoalFeatures() {
        // GoalCardView ni goalCard ichiga joylashtirish
        goalCardView.translatesAutoresizingMaskIntoConstraints = false
        goalCardView.delegate = self
        goalCard.addSubview(goalCardView)
        NSLayoutConstraint.activate([
            goalCardView.topAnchor.constraint(equalTo: goalCard.topAnchor),
            goalCardView.leadingAnchor.constraint(equalTo: goalCard.leadingAnchor),
            goalCardView.trailingAnchor.constraint(equalTo: goalCard.trailingAnchor),
            goalCardView.bottomAnchor.constraint(equalTo: goalCard.bottomAnchor),
        ])

        // SmartBanner ni warningContainerView o'rniga ishlatish
        smartBanner.delegate = self
        smartBanner.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(smartBanner)
        NSLayoutConstraint.activate([
            smartBanner.topAnchor.constraint(equalTo: warningContainerView.topAnchor),
            smartBanner.leadingAnchor.constraint(equalTo: warningContainerView.leadingAnchor),
            smartBanner.trailingAnchor.constraint(equalTo: warningContainerView.trailingAnchor),
            smartBanner.bottomAnchor.constraint(equalTo: warningContainerView.bottomAnchor),
        ])
        warningContainerView.isHidden = true

        // GoalViewModel callback
        goalViewModel.onStateChanged = { [weak self] in
            DispatchQueue.main.async { self?.refreshGoalUI() }
        }
    }

    func loadGoalData() {
        goalViewModel.loadGoal(transactions: viewModel.allTransactions)
    }

    func refreshGoalUI() {
        let transactions = viewModel.allTransactions
        goalViewModel.recalculate(transactions: transactions)
        goalCardView.configure(with: goalViewModel.progress)

        let bannerInfo = goalViewModel.smartBannerInfo(transactions: transactions)
        smartBanner.configure(with: bannerInfo)
    }

    func openGoalSetup(existingGoal: MonthlyGoal?) {
        let sheet = GoalSetupSheet()
        sheet.existingGoal = existingGoal
        sheet.delegate     = self
        sheet.modalPresentationStyle = .pageSheet
        if let sheetCtrl = sheet.sheetPresentationController {
            let detent = UISheetPresentationController.Detent.custom(
                identifier: .init("goalInput")
            ) { _ in return 500 }
            sheetCtrl.detents = [detent, .large()]
            sheetCtrl.prefersGrabberVisible = true
            sheetCtrl.preferredCornerRadius = 24
        }
        present(sheet, animated: true)
    }
}
