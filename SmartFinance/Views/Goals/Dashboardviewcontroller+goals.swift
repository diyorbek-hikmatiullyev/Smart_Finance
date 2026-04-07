// DashboardViewController+Goals.swift
// SmartFinance
// DashboardViewController ga GoalCard + SmartBanner integratsiyasi

import UIKit

// MARK: - GoalCard Delegate

extension DashboardViewController: GoalCardViewDelegate {

    func goalCardDidTapAdd(_ card: GoalCardView) {
        openGoalSetup(existingGoal: nil)
    }

    func goalCardDidTapEdit(_ card: GoalCardView) {
        openGoalSetup(existingGoal: goalViewModel.currentGoal)
    }

    func goalCardDidTapDelete(_ card: GoalCardView) {
        let alert = UIAlertController(
            title: "Maqsadni o'chirish",
            message: "Bu oylik maqsadni o'chirishni tasdiqlaysizmi?",
            preferredStyle: .actionSheet
        )
        alert.addAction(UIAlertAction(title: "O'chirish", style: .destructive) { [weak self] _ in
            self?.goalViewModel.deleteGoal { error in
                DispatchQueue.main.async {
                    if error == nil {
                        self?.updateGoalsUI()
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                }
            }
        })
        alert.addAction(UIAlertAction(title: "Bekor qilish", style: .cancel))
        if let popover = alert.popoverPresentationController {
            popover.sourceView = card
            popover.sourceRect = card.bounds
        }
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
                    self?.updateGoalsUI()
                }
            }
        }
    }

    func goalSetupDidCancel() {}
}

// MARK: - SmartBanner Delegate

extension DashboardViewController: SmartBannerViewDelegate {

    func smartBannerDidTapGoal(_ banner: SmartBannerView) {
        let cw = carouselScrollView.bounds.width
        carouselScrollView.setContentOffset(CGPoint(x: cw, y: 0), animated: true)
        carouselPageControl.currentPage = 1
    }

    func smartBannerDidTapAddExpense(_ banner: SmartBannerView) {
        let addVC = AddTransactionViewController()
        navigationController?.pushViewController(addVC, animated: true)
    }
}

// MARK: - Goal UI yangilash

extension DashboardViewController {

    func updateGoalsUI() {
        goalViewModel.transactions = viewModel.transactionsForPeriodCharts
        goalCardView.configure(viewModel: goalViewModel)
        smartBanner.configure(viewModel: goalViewModel)
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

