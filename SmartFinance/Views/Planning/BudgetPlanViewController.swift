// BudgetPlanViewController.swift
// SmartFinance

// BudgetPlanViewController.swift
// SmartFinance
import UIKit
 
final class BudgetPlanViewController: UIViewController {
 
    var existingPlan: BudgetPlan?
    var onSave: ((BudgetPlan) -> Void)?
    var currentBalance: Double = 0
 
    private let accentColor = UIColor(red: 91/255, green: 173/255, blue: 198/255, alpha: 1)
 
    private let scrollView   = UIScrollView()
    private let contentView  = UIView()
    private let totalField   = UITextField()
    private let datePicker   = UIDatePicker()
    private let saveButton   = UIButton(type: .system)
    private let deleteButton = UIButton(type: .system)
 
    private let balanceInfoCard   = UIView()
    private let balanceValueLabel = UILabel()
    private let allocationLabel   = UILabel()
    private let remainingLabel    = UILabel()
 
    private var categoryFields: [UITextField] = []
 
    // MARK: - Lifecycle
 
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = existingPlan == nil ? "Yangi reja" : "Rejani tahrirlash"
 
        // ✅ Back button
        setupBackButton()
 
        if currentBalance == 0 { loadBalanceFromCoreData() }
 
        setupUI()
        populateIfEditing()
    }
 
    // MARK: - Back button
 
    private func setupBackButton() {
        let backImage = UIImage(systemName: "chevron.left",
                                withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold))
        let backBtn = UIBarButtonItem(
            image: backImage,
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        backBtn.tintColor = accentColor
        navigationItem.leftBarButtonItem = backBtn
 
        // iOS default back gesture ham ishlashi uchun
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate  = nil
    }
 
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
 
    // MARK: - Load balance
 
    private func loadBalanceFromCoreData() {
        guard let uid = AuthSessionProvider.shared.currentUserID,
              let transactions = try? TransactionRepository.shared.fetchTransactions(forUserID: uid) else { return }
        let income  = transactions.filter { $0.type == "Income"  }.reduce(0) { $0 + $1.amount }
        let expense = transactions.filter { $0.type == "Expense" }.reduce(0) { $0 + $1.amount }
        currentBalance = income - expense
    }
 
    // MARK: - Setup UI
 
    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints  = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
 
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])
 
        setupBalanceInfoCard()
 
        let totalLabel = makeLabel("Byudjet summasi (so'm)")
        totalField.placeholder = "Masalan: 5000000"
        totalField.keyboardType = .decimalPad
        totalField.backgroundColor = .secondarySystemGroupedBackground
        totalField.layer.cornerRadius = 12
        totalField.layer.borderWidth = 0.5
        totalField.layer.borderColor = UIColor.separator.cgColor
        totalField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        totalField.leftViewMode = .always
        totalField.translatesAutoresizingMaskIntoConstraints = false
        totalField.addTarget(self, action: #selector(totalFieldChanged), for: .editingChanged)
 
        let dateLabel = makeLabel("Muddat tugash sanasi")
        datePicker.datePickerMode = .date
        datePicker.minimumDate = Date()
        datePicker.preferredDatePickerStyle = .compact
        datePicker.translatesAutoresizingMaskIntoConstraints = false
 
        let catLabel = makeLabel("Kategoriya limitlari (so'm)")
        let catStack = makeCategoryStack()
 
        saveButton.setTitle("Saqlash", for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        saveButton.backgroundColor = accentColor
        saveButton.layer.cornerRadius = 14
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
 
        deleteButton.setTitle("Rejani o'chirish", for: .normal)
        deleteButton.setTitleColor(.systemRed, for: .normal)
        deleteButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.isHidden = existingPlan == nil
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
 
        [balanceInfoCard, totalLabel, totalField, dateLabel, datePicker,
         catLabel, catStack, saveButton, deleteButton].forEach { contentView.addSubview($0) }
 
        NSLayoutConstraint.activate([
            balanceInfoCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            balanceInfoCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            balanceInfoCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            balanceInfoCard.heightAnchor.constraint(equalToConstant: 72),
 
            totalLabel.topAnchor.constraint(equalTo: balanceInfoCard.bottomAnchor, constant: 20),
            totalLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
 
            totalField.topAnchor.constraint(equalTo: totalLabel.bottomAnchor, constant: 8),
            totalField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            totalField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            totalField.heightAnchor.constraint(equalToConstant: 50),
 
            dateLabel.topAnchor.constraint(equalTo: totalField.bottomAnchor, constant: 20),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
 
            datePicker.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 8),
            datePicker.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
 
            catLabel.topAnchor.constraint(equalTo: datePicker.bottomAnchor, constant: 20),
            catLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
 
            catStack.topAnchor.constraint(equalTo: catLabel.bottomAnchor, constant: 8),
            catStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            catStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
 
            saveButton.topAnchor.constraint(equalTo: catStack.bottomAnchor, constant: 28),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 54),
 
            deleteButton.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 12),
            deleteButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            deleteButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32),
        ])
 
        updateAllocationLabel()
    }
 
    // MARK: - Balance Info Card
 
    private func setupBalanceInfoCard() {
        balanceInfoCard.backgroundColor    = accentColor.withAlphaComponent(0.1)
        balanceInfoCard.layer.cornerRadius = 14
        balanceInfoCard.translatesAutoresizingMaskIntoConstraints = false
 
        let icon = UIImageView()
        icon.image = UIImage(systemName: "info.circle.fill",
                             withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .medium))
        icon.tintColor = accentColor
        icon.translatesAutoresizingMaskIntoConstraints = false
 
        let titleLabel = UILabel()
        titleLabel.text = "Joriy balansingiz"
        titleLabel.font = .systemFont(ofSize: 12)
        titleLabel.textColor = .secondaryLabel
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
 
        balanceValueLabel.text      = formatSum(currentBalance)
        balanceValueLabel.font      = .systemFont(ofSize: 18, weight: .bold)
        balanceValueLabel.textColor = currentBalance >= 0 ? .systemGreen : .systemRed
        balanceValueLabel.translatesAutoresizingMaskIntoConstraints = false
 
        allocationLabel.font = .systemFont(ofSize: 11)
        allocationLabel.textColor = .secondaryLabel
        allocationLabel.textAlignment = .right
        allocationLabel.translatesAutoresizingMaskIntoConstraints = false
 
        remainingLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        remainingLabel.textAlignment = .right
        remainingLabel.translatesAutoresizingMaskIntoConstraints = false
 
        [icon, titleLabel, balanceValueLabel, allocationLabel, remainingLabel]
            .forEach { balanceInfoCard.addSubview($0) }
 
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: balanceInfoCard.leadingAnchor, constant: 14),
            icon.centerYAnchor.constraint(equalTo: balanceInfoCard.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 20),
            icon.heightAnchor.constraint(equalToConstant: 20),
 
            titleLabel.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 10),
            titleLabel.topAnchor.constraint(equalTo: balanceInfoCard.topAnchor, constant: 14),
 
            balanceValueLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            balanceValueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
 
            allocationLabel.trailingAnchor.constraint(equalTo: balanceInfoCard.trailingAnchor, constant: -14),
            allocationLabel.topAnchor.constraint(equalTo: balanceInfoCard.topAnchor, constant: 14),
 
            remainingLabel.trailingAnchor.constraint(equalTo: balanceInfoCard.trailingAnchor, constant: -14),
            remainingLabel.topAnchor.constraint(equalTo: allocationLabel.bottomAnchor, constant: 2),
        ])
    }
 
    // MARK: - Allocation tracker
 
    @objc private func totalFieldChanged() { updateAllocationLabel() }
 
    private func updateAllocationLabel() {
        let budget = Double(totalField.text ?? "") ?? 0
        let allocated = categoryFields.reduce(0.0) { $0 + (Double($1.text ?? "") ?? 0) }
        let remaining = budget - allocated
 
        allocationLabel.text = "Taqsimlangan: \(formatCompact(allocated))"
        remainingLabel.text  = "Qoldi: \(formatCompact(remaining)) so'm"
        remainingLabel.textColor = remaining < 0 ? .systemRed : accentColor
    }
 
    // MARK: - Category stack
 
    private func makeCategoryStack() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        categoryFields.removeAll()
 
        for meta in GoalViewModel.categoryMeta {
            let row = UIView()
            row.translatesAutoresizingMaskIntoConstraints = false
 
            let label = UILabel()
            label.text = meta.name
            label.font = .systemFont(ofSize: 14, weight: .medium)
            label.translatesAutoresizingMaskIntoConstraints = false
 
            let field = UITextField()
            field.placeholder = "0"
            field.keyboardType = .decimalPad
            field.backgroundColor = .secondarySystemGroupedBackground
            field.layer.cornerRadius = 10
            field.layer.borderWidth = 0.5
            field.layer.borderColor = UIColor.separator.cgColor
            field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 1))
            field.leftViewMode = .always
            field.textAlignment = .right
            field.translatesAutoresizingMaskIntoConstraints = false
            field.addTarget(self, action: #selector(categoryFieldChanged(_:)), for: .editingChanged)
            categoryFields.append(field)
 
            row.addSubview(label)
            row.addSubview(field)
            NSLayoutConstraint.activate([
                row.heightAnchor.constraint(equalToConstant: 44),
                label.leadingAnchor.constraint(equalTo: row.leadingAnchor),
                label.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                field.trailingAnchor.constraint(equalTo: row.trailingAnchor),
                field.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                field.widthAnchor.constraint(equalToConstant: 140),
                field.heightAnchor.constraint(equalToConstant: 40),
            ])
            stack.addArrangedSubview(row)
        }
        return stack
    }
 
    @objc private func categoryFieldChanged(_ sender: UITextField) { updateAllocationLabel() }
 
    private func makeLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text.uppercased()
        l.font = .systemFont(ofSize: 12, weight: .semibold)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }
 
    // MARK: - Populate
 
    private func populateIfEditing() {
        guard let plan = existingPlan else { return }
        totalField.text = "\(Int(plan.totalAmount))"
        datePicker.date = plan.endDate
        for (i, meta) in GoalViewModel.categoryMeta.enumerated() {
            if let limit = plan.categoryLimits.first(where: { $0.categoryName == meta.name }),
               limit.limitAmount > 0 {
                categoryFields[i].text = "\(Int(limit.limitAmount))"
            }
        }
        updateAllocationLabel()
    }
 
    // MARK: - Save
 
    @objc private func saveTapped() {
        view.endEditing(true)
 
        guard let totalText = totalField.text,
              let total = Double(totalText), total > 0 else {
            showAlert("Byudjet summasini kiriting", message: "0 dan katta son bo'lishi kerak.")
            return
        }
 
        // ✅ Byudjet joriy balansdan oshmasligi kerak
        if currentBalance > 0 && total > currentBalance {
            showAlert(
                "Byudjet juda katta",
                message: "Joriy balansingiz: \(formatSum(currentBalance))\nByudjet shu summadan oshmasligi kerak."
            )
            return
        }
 
        var limits: [BudgetPlan.CategoryLimit] = []
        var totalAllocated = 0.0
        for (i, meta) in GoalViewModel.categoryMeta.enumerated() {
            let amount = Double(categoryFields[i].text ?? "") ?? 0
            if amount > 0 {
                limits.append(BudgetPlan.CategoryLimit(categoryName: meta.name, limitAmount: amount))
                totalAllocated += amount
            }
        }
 
        // ✅ Kategoriyalar yig'indisi byudjetdan oshmasligi kerak
        if totalAllocated > total {
            showAlert(
                "Kategoriya limiti ortiqcha",
                message: "Kategoriyalar yig'indisi \(formatSum(totalAllocated)) byudjet \(formatSum(total)) dan oshib ketdi."
            )
            return
        }
 
        let plan = BudgetPlan(
            id: existingPlan?.id ?? UUID().uuidString,
            totalAmount: total,
            startDate: existingPlan?.startDate ?? Date(),
            endDate: datePicker.date,
            categoryLimits: limits
        )
        onSave?(plan)
        navigationController?.popViewController(animated: true)
    }
 
    @objc private func deleteTapped() {
        let alert = UIAlertController(title: "O'chirishni tasdiqlang",
                                      message: "Byudjet rejasi o'chiriladi",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "O'chirish", style: .destructive) { [weak self] _ in
            self?.onSave?(BudgetPlan(totalAmount: 0, endDate: Date()))
            self?.navigationController?.popViewController(animated: true)
        })
        alert.addAction(UIAlertAction(title: "Bekor qilish", style: .cancel))
        present(alert, animated: true)
    }
 
    private func showAlert(_ title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
 
    // MARK: - Format
 
    private func formatSum(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal; f.groupingSeparator = " "; f.maximumFractionDigits = 0
        return (f.string(from: NSNumber(value: v)) ?? "\(Int(v))") + " so'm"
    }
 
    private func formatCompact(_ v: Double) -> String {
        if v >= 1_000_000 { return String(format: "%.1f mln", v / 1_000_000) }
        if v >= 1_000     { return String(format: "%.0f ming", v / 1_000) }
        return "\(Int(v))"
    }
}
