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
 
    // Summa suffix ("so'm") himoyasi uchun
    private let amountSuffix = " so'm"
 
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
        tf.delegate = self
        return tf
    }()
 
    // ✅ Vendor nomi uchun tahrirlash mumkin bo'lgan TextField
    private lazy var vendorField: UITextField = {
        let tf = UITextField()
        tf.borderStyle = .none
        tf.font = .systemFont(ofSize: 17, weight: .medium)
        tf.textColor = .secondaryLabel
        tf.textAlignment = .center
        tf.placeholder = "Do'kon nomi"
        tf.returnKeyType = .done
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.delegate = self
 
        // Pastki chiziq (subtle edit indicator)
        let underline = UIView()
        underline.backgroundColor = UIColor.systemGray4
        underline.translatesAutoresizingMaskIntoConstraints = false
        tf.addSubview(underline)
        NSLayoutConstraint.activate([
            underline.bottomAnchor.constraint(equalTo: tf.bottomAnchor),
            underline.leadingAnchor.constraint(equalTo: tf.leadingAnchor, constant: 20),
            underline.trailingAnchor.constraint(equalTo: tf.trailingAnchor, constant: -20),
            underline.heightAnchor.constraint(equalToConstant: 0.5),
        ])
        return tf
    }()
 
    private lazy var vendorEditHint: UILabel = {
        let l = UILabel()
        l.text = "✏️ Nomni tahrirlash mumkin"
        l.font = .systemFont(ofSize: 11)
        l.textColor = .tertiaryLabel
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
 
        // Keyboard dismiss
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
 
    // MARK: - Sheet Config
    private func setupSheet() {
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 24
 
        if let sheet = sheetPresentationController {
            let smallDetent = UISheetPresentationController.Detent.custom(
                identifier: .init("small")
            ) { _ in return 520 }
 
            sheet.detents = [smallDetent, .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }
    }
 
    // MARK: - UI Setup
    private func setupUI() {
        [handleView, titleLabel, categoryBadge, categoryIconView,
         amountField, vendorField, vendorEditHint,
         categoryPicker, dateLabel, saveButton, cancelButton].forEach { view.addSubview($0) }
 
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
            amountField.heightAnchor.constraint(equalToConstant: 50),
 
            // ✅ Vendor field - tahrirlash mumkin
            vendorField.topAnchor.constraint(equalTo: amountField.bottomAnchor, constant: 4),
            vendorField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            vendorField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            vendorField.heightAnchor.constraint(equalToConstant: 36),
 
            vendorEditHint.topAnchor.constraint(equalTo: vendorField.bottomAnchor, constant: 2),
            vendorEditHint.centerXAnchor.constraint(equalTo: view.centerXAnchor),
 
            dateLabel.topAnchor.constraint(equalTo: vendorEditHint.bottomAnchor, constant: 4),
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
        // ✅ Summa + "so'm" suffix
        amountField.text = "\(Int(expense.amount))\(amountSuffix)"
        vendorField.text = expense.vendorName
        updateCategoryUI(expense.category)
 
        if let idx = ExpenseCategory.allCases.firstIndex(of: expense.category) {
            categoryPicker.selectedSegmentIndex = idx
        }
 
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "uz_UZ")
        dateLabel.text = formatter.string(from: expense.date)
 
        // Summa animatsiyasi
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
 
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
 
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
        // Vendor nomini saqlash
        let vendorText = vendorField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        expense.vendorName = vendorText.isEmpty ? "Noma'lum do'kon" : vendorText
 
        // Summani olish ("so'm" ni tozalab)
        let rawText = amountField.text?
            .replacingOccurrences(of: amountSuffix, with: "")
            .replacingOccurrences(of: " so'm", with: "")
            .replacingOccurrences(of: "so'm", with: "")
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
 
// MARK: - UITextFieldDelegate
 
extension ScanResultBottomSheetVC: UITextFieldDelegate {
 
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
 
    // ✅ Amount field: cursor ni suffix oldiga joylashtirish
    func textFieldDidBeginEditing(_ textField: UITextField) {
        guard textField === amountField else { return }
        // Cursor ni "so'm" dan oldingi pozitsiyaga o'tkazish
        DispatchQueue.main.async {
            self.moveCursorBeforeSuffix(textField)
        }
    }
 
    // ✅ Amount field: "so'm" o'chirilmasligi uchun himoya
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
 
        guard textField === amountField else { return true }
 
        let currentText = textField.text ?? ""
 
        // Suffix pozitsiyasini aniqlash
        let suffixRange = (currentText as NSString).range(of: amountSuffix)
        guard suffixRange.location != NSNotFound else { return true }
 
        // O'chirish yoki kiritish suffix hududiga tegadimi?
        let changeEnd = range.location + range.length
        if range.location >= suffixRange.location || changeEnd > suffixRange.location {
            // Suffix himoyalangan — ruxsat yo'q
            moveCursorBeforeSuffix(textField)
            return false
        }
 
        // Faqat raqam kiritishga ruxsat
        let allowed = CharacterSet.decimalDigits
        if !string.isEmpty && string.unicodeScalars.allSatisfy({ !allowed.contains($0) }) {
            return false
        }
 
        return true
    }
 
    // ✅ Cursor harakat qilganda suffix oldiga qaytarish
    func textFieldDidChangeSelection(_ textField: UITextField) {
        guard textField === amountField else { return }
        moveCursorBeforeSuffix(textField)
    }
 
    // MARK: - Helper: cursor ni suffix oldiga joylashtirish
    private func moveCursorBeforeSuffix(_ textField: UITextField) {
        guard let text = textField.text,
              let suffixStart = text.range(of: amountSuffix)?.lowerBound else { return }
 
        if let selectedRange = textField.selectedTextRange {
            let cursorPos = textField.offset(from: textField.beginningOfDocument,
                                              to: selectedRange.end)
            let suffixOffset = text.distance(from: text.startIndex, to: suffixStart)
 
            if cursorPos > suffixOffset {
                if let newPos = textField.position(from: textField.beginningOfDocument,
                                                    offset: suffixOffset) {
                    textField.selectedTextRange = textField.textRange(from: newPos, to: newPos)
                }
            }
        }
    }
}
