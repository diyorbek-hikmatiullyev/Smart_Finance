// ScanResultBottomSheetVC.swift
// SmartFinance
// QR skan natijasini ko'rsatuvchi Bottom Sheet (iOS 15+ UISheetPresentationController)

import UIKit

// MARK: - Model

struct ScannedExpense {
    var amount: Double
    var vendorName: String
    var category: ExpenseCategory
    var date: Date
    var rawURL: String
}

// MARK: - Delegate

protocol ScanResultDelegate: AnyObject {
    func didConfirmExpense(_ expense: ScannedExpense)
    func didCancelScan()
}

// MARK: - ViewController

final class ScanResultBottomSheetVC: UIViewController {

    // MARK: - Properties
    var expense: ScannedExpense
    weak var delegate: ScanResultDelegate?

    // MARK: - UI Elements

    private let handleView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemGray4
        v.layer.cornerRadius = 2.5
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Chek topildi ✓"
        l.font = .systemFont(ofSize: 20, weight: .bold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var categoryBadge: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 32
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var categoryIconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .white
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private lazy var amountField: UITextField = {
        let tf = UITextField()
        tf.borderStyle = .none
        tf.keyboardType = .decimalPad
        tf.font = .systemFont(ofSize: 36, weight: .heavy)
        tf.textAlignment = .center
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private lazy var vendorLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17, weight: .medium)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var categoryPicker: UISegmentedControl = {
        let items = ExpenseCategory.allCases.map { $0.rawValue }
        let sc = UISegmentedControl(items: items)
        sc.translatesAutoresizingMaskIntoConstraints = false
        sc.addTarget(self, action: #selector(categoryChanged), for: .valueChanged)
        return sc
    }()

    private lazy var dateLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = .tertiaryLabel
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var saveButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Saqlash"
        config.cornerStyle = .large
        config.baseBackgroundColor = .systemBlue
        config.buttonSize = .large
        let btn = UIButton(configuration: config)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        return btn
    }()

    private lazy var cancelButton: UIButton = {
        var config = UIButton.Configuration.gray()
        config.title = "Bekor qilish"
        config.cornerStyle = .large
        config.buttonSize = .large
        let btn = UIButton(configuration: config)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        return btn
    }()

    // MARK: - Init
    init(expense: ScannedExpense) {
        self.expense = expense
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSheet()
        setupUI()
        populateData()
    }

    // MARK: - Sheet Config
    private func setupSheet() {
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 24

        if let sheet = sheetPresentationController {
            let smallDetent = UISheetPresentationController.Detent.custom(
                identifier: .init("small")
            ) { _ in return 460 }

            sheet.detents = [smallDetent, .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }
    }

    // MARK: - UI Setup
    private func setupUI() {
        [handleView, titleLabel, categoryBadge, categoryIconView,
         amountField, vendorLabel, categoryPicker,
         dateLabel, saveButton, cancelButton].forEach { view.addSubview($0) }

        NSLayoutConstraint.activate([
            handleView.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            handleView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            handleView.widthAnchor.constraint(equalToConstant: 40),
            handleView.heightAnchor.constraint(equalToConstant: 5),

            categoryBadge.topAnchor.constraint(equalTo: handleView.bottomAnchor, constant: 20),
            categoryBadge.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            categoryBadge.widthAnchor.constraint(equalToConstant: 64),
            categoryBadge.heightAnchor.constraint(equalToConstant: 64),

            categoryIconView.centerXAnchor.constraint(equalTo: categoryBadge.centerXAnchor),
            categoryIconView.centerYAnchor.constraint(equalTo: categoryBadge.centerYAnchor),
            categoryIconView.widthAnchor.constraint(equalToConstant: 30),
            categoryIconView.heightAnchor.constraint(equalToConstant: 30),

            titleLabel.topAnchor.constraint(equalTo: categoryBadge.bottomAnchor, constant: 12),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            amountField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            amountField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            amountField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            vendorLabel.topAnchor.constraint(equalTo: amountField.bottomAnchor, constant: 4),
            vendorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            dateLabel.topAnchor.constraint(equalTo: vendorLabel.bottomAnchor, constant: 4),
            dateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            categoryPicker.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 20),
            categoryPicker.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            categoryPicker.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            saveButton.topAnchor.constraint(equalTo: categoryPicker.bottomAnchor, constant: 24),
            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            saveButton.heightAnchor.constraint(equalToConstant: 54),

            cancelButton.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 8),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            cancelButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            cancelButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    private func populateData() {
        amountField.text = String(format: "%.0f so'm", expense.amount)
        vendorLabel.text = expense.vendorName
        updateCategoryUI(expense.category)

        if let idx = ExpenseCategory.allCases.firstIndex(of: expense.category) {
            categoryPicker.selectedSegmentIndex = idx
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "uz_UZ")
        dateLabel.text = formatter.string(from: expense.date)

        // Summa kirib kelish animatsiyasi
        amountField.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        UIView.animate(withDuration: 0.5, delay: 0.1,
                       usingSpringWithDamping: 0.6,
                       initialSpringVelocity: 0.8) {
            self.amountField.transform = .identity
        }
    }

    private func updateCategoryUI(_ category: ExpenseCategory) {
        categoryBadge.backgroundColor = category.color
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .semibold)
        categoryIconView.image = UIImage(systemName: category.icon, withConfiguration: config)

        UIView.animate(withDuration: 0.3) {
            self.categoryBadge.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        } completion: { _ in
            UIView.animate(withDuration: 0.2) {
                self.categoryBadge.transform = .identity
            }
        }
    }

    // MARK: - Actions

    @objc private func categoryChanged(_ sender: UISegmentedControl) {
        let selected = ExpenseCategory.allCases[sender.selectedSegmentIndex]
        expense.category = selected
        updateCategoryUI(selected)
    }

    @objc private func saveTapped() {
        guard validateAndUpdate() else { return }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        UIView.animate(withDuration: 0.15) {
            self.saveButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        } completion: { _ in
            UIView.animate(withDuration: 0.15) {
                self.saveButton.transform = .identity
            }
            self.delegate?.didConfirmExpense(self.expense)
            self.dismiss(animated: true)
        }
    }

    @objc private func cancelTapped() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        delegate?.didCancelScan()
        dismiss(animated: true)
    }

    // MARK: - Validation

    @discardableResult
    private func validateAndUpdate() -> Bool {
        let rawText = amountField.text?
            .replacingOccurrences(of: " so'm", with: "")
            .replacingOccurrences(of: " ", with: "")
            ?? ""

        guard let amount = Double(rawText), amount > 0 else {
            shakeField(amountField)
            showValidationError("Iltimos, to'g'ri summa kiriting")
            return false
        }

        guard amount < 100_000_000 else {
            showValidationError("Summa 100 mln so'mdan oshmasligi kerak")
            return false
        }

        expense.amount = amount
        return true
    }

    private func shakeField(_ field: UITextField) {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.5
        animation.values = [-10, 10, -8, 8, -5, 5, 0]
        field.layer.add(animation, forKey: "shake")
        field.layer.borderColor = UIColor.systemRed.cgColor
        field.layer.borderWidth = 1.5
        field.layer.cornerRadius = 8
    }

    private func showValidationError(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.amountField.layer.borderWidth = 0
        })
        present(alert, animated: true)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
