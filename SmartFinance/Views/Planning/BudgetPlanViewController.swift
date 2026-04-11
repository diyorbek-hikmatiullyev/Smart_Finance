// BudgetPlanViewController.swift
// SmartFinance

import UIKit

final class BudgetPlanViewController: UIViewController {

    var existingPlan: BudgetPlan?
    var onSave: ((BudgetPlan) -> Void)?

    private let accentColor = UIColor(red: 91/255, green: 173/255, blue: 198/255, alpha: 1)

    // MARK: - State
    private var totalAmount: Double = 0
    private var endDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    private var categoryLimits: [BudgetPlan.CategoryLimit] = []

    // MARK: - UI
    private let scrollView  = UIScrollView()
    private let contentView = UIView()
    private let totalField  = UITextField()
    private let datePicker  = UIDatePicker()
    private let saveButton  = UIButton(type: .system)
    private let deleteButton = UIButton(type: .system)
    private var categoryFields: [UITextField] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = existingPlan == nil ? "Yangi reja" : "Rejani tahrirlash"
        setupUI()
        populateIfEditing()
    }

    // MARK: - Setup UI

    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
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

        // Total amount
        let totalLabel = makeLabel("Umumiy byudjet (so'm)")
        totalField.placeholder = "Masalan: 5000000"
        totalField.keyboardType = .decimalPad
        totalField.backgroundColor = .secondarySystemGroupedBackground
        totalField.layer.cornerRadius = 12
        totalField.layer.borderWidth = 0.5
        totalField.layer.borderColor = UIColor.separator.cgColor
        totalField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        totalField.leftViewMode = .always
        totalField.translatesAutoresizingMaskIntoConstraints = false

        // End date
        let dateLabel = makeLabel("Muddat tugash sanasi")
        datePicker.datePickerMode = .date
        datePicker.minimumDate = Date()
        datePicker.preferredDatePickerStyle = .compact
        datePicker.translatesAutoresizingMaskIntoConstraints = false

        // Category limits
        let catLabel = makeLabel("Kategoriya limitlari (so'm)")
        var catStack = UIStackView()
        catStack = makeCategoryStack()

        // Save button
        saveButton.setTitle("Saqlash", for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        saveButton.backgroundColor = accentColor
        saveButton.layer.cornerRadius = 14
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        // Delete button (faqat editing rejimida)
        deleteButton.setTitle("Rejani o'chirish", for: .normal)
        deleteButton.setTitleColor(.systemRed, for: .normal)
        deleteButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.isHidden = existingPlan == nil
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)

        [totalLabel, totalField, dateLabel, datePicker,
         catLabel, catStack, saveButton, deleteButton].forEach { contentView.addSubview($0) }

        NSLayoutConstraint.activate([
            totalLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
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
    }

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
            label.textColor = .label
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

    private func makeLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text.uppercased()
        l.font = .systemFont(ofSize: 12, weight: .semibold)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }

    // MARK: - Populate existing plan

    private func populateIfEditing() {
        guard let plan = existingPlan else { return }
        totalField.text = "\(Int(plan.totalAmount))"
        datePicker.date = plan.endDate

        for (i, meta) in GoalViewModel.categoryMeta.enumerated() {
            if let limit = plan.categoryLimits.first(where: { $0.categoryName == meta.name }) {
                categoryFields[i].text = limit.limitAmount > 0 ? "\(Int(limit.limitAmount))" : ""
            }
        }
    }

    // MARK: - Actions

    @objc private func saveTapped() {
        guard let totalText = totalField.text,
              let total = Double(totalText), total > 0 else {
            showAlert("Umumiy byudjet summasini kiriting")
            return
        }

        var limits: [BudgetPlan.CategoryLimit] = []
        for (i, meta) in GoalViewModel.categoryMeta.enumerated() {
            let amount = Double(categoryFields[i].text ?? "") ?? 0
            if amount > 0 {
                limits.append(BudgetPlan.CategoryLimit(
                    categoryName: meta.name,
                    limitAmount: amount
                ))
            }
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
            // totalAmount = 0 → delete signal
            let empty = BudgetPlan(totalAmount: 0, endDate: Date())
            self?.onSave?(empty)
            self?.navigationController?.popViewController(animated: true)
        })
        alert.addAction(UIAlertAction(title: "Bekor qilish", style: .cancel))
        present(alert, animated: true)
    }

    private func showAlert(_ msg: String) {
        let a = UIAlertController(title: "Xato", message: msg, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}
