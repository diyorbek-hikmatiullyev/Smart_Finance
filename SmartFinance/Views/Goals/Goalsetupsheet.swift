// GoalSetupSheet.swift
// SmartFinance
// Maqsad qo'yish / tahrirlash bottom sheet

import UIKit

// MARK: - Delegate

protocol GoalSetupSheetDelegate: AnyObject {
    func goalSetupDidSave(targetAmount: Double, note: String?)
    func goalSetupDidDelete()
    func goalSetupDidCancel()
}

// MARK: - GoalSetupSheet

final class GoalSetupSheet: UIViewController {

    // MARK: - Config
    var existingGoal: MonthlyGoal?   // nil = yangi, value = tahrirlash
    weak var delegate: GoalSetupSheetDelegate?

    // MARK: - UI
    private let handleView    = UIView()
    private let titleLabel    = UILabel()
    private let subtitleLabel = UILabel()
    private let amountField   = UITextField()
    private let amountCard    = UIView()
    private let noteField     = UITextField()
    private let suggestStack  = UIStackView()
    private let saveButton    = UIButton(type: .system)
    private let deleteButton  = UIButton(type: .system)
    private let cancelButton  = UIButton(type: .system)

    private let accent = UIColor(red: 91/255, green: 173/255, blue: 198/255, alpha: 1)

    // Tez tanlash summalar
    private let quickAmounts: [Double] = [100_000, 300_000, 500_000, 1_000_000]

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupSheet()
        setupUI()
        populateIfEditing()

        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        amountField.becomeFirstResponder()
    }

    // MARK: - Sheet config

    private func setupSheet() {
        if let sheet = sheetPresentationController {
            let smallDetent = UISheetPresentationController.Detent.custom(
                identifier: .init("goal")
            ) { _ in return 480 }
            sheet.detents               = [smallDetent, .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
    }

    // MARK: - UI Setup

    private func setupUI() {
        // Handle
        handleView.backgroundColor    = .systemGray4
        handleView.layer.cornerRadius = 2.5
        handleView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(handleView)

        // Title
        titleLabel.text = existingGoal == nil ? "Oylik maqsad qo'yish" : "Maqsadni tahrirlash"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        // Subtitle
        let calendar  = Calendar.current
        let now       = Date()
        let formatter = DateFormatter()
        formatter.locale     = Locale(identifier: "uz_UZ")
        formatter.dateFormat = "MMMM yyyy"
        let monthStr  = formatter.string(from: now)
        subtitleLabel.text      = "\(monthStr) uchun tejash maqsadi"
        subtitleLabel.font      = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subtitleLabel)

        // Amount Card
        amountCard.backgroundColor    = .secondarySystemBackground
        amountCard.layer.cornerRadius = 20
        amountCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(amountCard)

        amountField.placeholder    = "0"
        amountField.font           = .systemFont(ofSize: 40, weight: .heavy)
        amountField.textAlignment  = .center
        amountField.keyboardType   = .decimalPad
        amountField.borderStyle    = .none
        amountField.backgroundColor = .clear
        amountField.textColor      = accent
        amountField.translatesAutoresizingMaskIntoConstraints = false
        amountCard.addSubview(amountField)

        let somLabel = UILabel()
        somLabel.text      = "so'm"
        somLabel.font      = .systemFont(ofSize: 16, weight: .medium)
        somLabel.textColor = .secondaryLabel
        somLabel.textAlignment = .center
        somLabel.translatesAutoresizingMaskIntoConstraints = false
        amountCard.addSubview(somLabel)

        NSLayoutConstraint.activate([
            amountField.topAnchor.constraint(equalTo: amountCard.topAnchor, constant: 20),
            amountField.leadingAnchor.constraint(equalTo: amountCard.leadingAnchor, constant: 16),
            amountField.trailingAnchor.constraint(equalTo: amountCard.trailingAnchor, constant: -16),
            amountField.heightAnchor.constraint(equalToConstant: 56),
            somLabel.topAnchor.constraint(equalTo: amountField.bottomAnchor, constant: 4),
            somLabel.centerXAnchor.constraint(equalTo: amountCard.centerXAnchor),
            somLabel.bottomAnchor.constraint(equalTo: amountCard.bottomAnchor, constant: -16),
        ])

        // Quick amount buttons
        suggestStack.axis         = .horizontal
        suggestStack.spacing      = 10
        suggestStack.distribution = .fillEqually
        suggestStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(suggestStack)

        for amount in quickAmounts {
            let btn = makeQuickBtn(amount: amount)
            suggestStack.addArrangedSubview(btn)
        }

        // Note field
        noteField.placeholder        = "Izoh (ixtiyoriy)"
        noteField.font               = .systemFont(ofSize: 15)
        noteField.backgroundColor    = .secondarySystemBackground
        noteField.layer.cornerRadius = 14
        noteField.leftView           = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        noteField.leftViewMode       = .always
        noteField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(noteField)

        // Save button
        var saveConfig = UIButton.Configuration.filled()
        saveConfig.title              = existingGoal == nil ? "Saqlash" : "Yangilash"
        saveConfig.cornerStyle        = .large
        saveConfig.baseBackgroundColor = accent
        saveConfig.buttonSize         = .large
        saveButton.configuration      = saveConfig
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        view.addSubview(saveButton)

        // Delete button (faqat tahrirlashda)
        deleteButton.setTitle("Maqsadni o'chirish", for: .normal)
        deleteButton.setTitleColor(.systemRed, for: .normal)
        deleteButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.isHidden = (existingGoal == nil)
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        view.addSubview(deleteButton)

        // Cancel button
        cancelButton.setTitle("Bekor qilish", for: .normal)
        cancelButton.setTitleColor(.secondaryLabel, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 15)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        view.addSubview(cancelButton)

        // Constraints
        NSLayoutConstraint.activate([
            handleView.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            handleView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            handleView.widthAnchor.constraint(equalToConstant: 40),
            handleView.heightAnchor.constraint(equalToConstant: 5),

            titleLabel.topAnchor.constraint(equalTo: handleView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            amountCard.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            amountCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            amountCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            suggestStack.topAnchor.constraint(equalTo: amountCard.bottomAnchor, constant: 14),
            suggestStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            suggestStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            suggestStack.heightAnchor.constraint(equalToConstant: 38),

            noteField.topAnchor.constraint(equalTo: suggestStack.bottomAnchor, constant: 14),
            noteField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            noteField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            noteField.heightAnchor.constraint(equalToConstant: 48),

            saveButton.topAnchor.constraint(equalTo: noteField.bottomAnchor, constant: 20),
            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 54),

            deleteButton.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 12),
            deleteButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            deleteButton.heightAnchor.constraint(equalToConstant: 40),

            cancelButton.topAnchor.constraint(equalTo: deleteButton.bottomAnchor, constant: 4),
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cancelButton.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    private func makeQuickBtn(amount: Double) -> UIButton {
        let btn = UIButton(type: .system)
        let text = amount >= 1_000_000
            ? "\(Int(amount / 1_000_000))M"
            : "\(Int(amount / 1_000))K"
        btn.setTitle(text, for: .normal)
        btn.titleLabel?.font       = .systemFont(ofSize: 13, weight: .semibold)
        btn.tintColor              = accent
        btn.backgroundColor        = accent.withAlphaComponent(0.1)
        btn.layer.cornerRadius     = 10
        btn.layer.borderWidth      = 1
        btn.layer.borderColor      = accent.withAlphaComponent(0.25).cgColor
        btn.addTarget(self, action: #selector(quickAmountTapped(_:)), for: .touchUpInside)
        // amount ni saqlash uchun
        btn.accessibilityValue     = "\(amount)"
        return btn
    }

    // MARK: - Populate (tahrirlash holatida)

    private func populateIfEditing() {
        guard let goal = existingGoal else { return }
        let f = NumberFormatter()
        f.numberStyle       = .decimal
        f.groupingSeparator = " "
        f.maximumFractionDigits = 0
        amountField.text = f.string(from: NSNumber(value: goal.targetAmount))
        noteField.text   = goal.note
    }

    // MARK: - Actions

    @objc private func quickAmountTapped(_ sender: UIButton) {
        guard let valueStr = sender.accessibilityValue,
              let amount   = Double(valueStr) else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let f = NumberFormatter()
        f.numberStyle       = .decimal
        f.groupingSeparator = " "
        f.maximumFractionDigits = 0
        amountField.text = f.string(from: NSNumber(value: amount))

        // Button press animatsiyasi
        UIView.animate(withDuration: 0.1) {
            sender.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        } completion: { _ in
            UIView.animate(withDuration: 0.15) { sender.transform = .identity }
        }
    }

    @objc private func saveTapped() {
        let rawText = amountField.text?
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".") ?? ""
        guard let amount = Double(rawText), amount > 0 else {
            shakeField(); return
        }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        delegate?.goalSetupDidSave(targetAmount: amount, note: noteField.text)
        dismiss(animated: true)
    }

    @objc private func deleteTapped() {
        let alert = UIAlertController(
            title: "Maqsadni o'chirish",
            message: "Bu oylik maqsad o'chiriladi. Davom etasizmi?",
            preferredStyle: .actionSheet
        )
        alert.addAction(UIAlertAction(title: "O'chirish", style: .destructive) { [weak self] _ in
            self?.delegate?.goalSetupDidDelete()
            self?.dismiss(animated: true)
        })
        alert.addAction(UIAlertAction(title: "Bekor qilish", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func cancelTapped() {
        delegate?.goalSetupDidCancel()
        dismiss(animated: true)
    }

    private func shakeField() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        let anim = CAKeyframeAnimation(keyPath: "transform.translation.x")
        anim.timingFunction = CAMediaTimingFunction(name: .linear)
        anim.duration       = 0.4
        anim.values         = [-10, 10, -8, 8, -5, 5, 0]
        amountField.layer.add(anim, forKey: "shake")
        amountField.layer.borderColor = UIColor.systemRed.cgColor
        amountField.layer.borderWidth = 1.5
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.amountField.layer.borderWidth = 0
        }
    }
}
