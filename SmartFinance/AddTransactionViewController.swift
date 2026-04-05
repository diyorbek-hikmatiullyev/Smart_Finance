
import UIKit

final class AddTransactionViewController: UIViewController {

    private let viewModel = AddTransactionViewModel()

    let titleField = UITextField()
    let amountField = UITextField()
    let typeSegment = UISegmentedControl(items: ["Kirim", "Chiqim"])
    let categoryButton = UIButton(type: .system)
    let saveButton = UIButton(type: .system)

    var selectedCategory: String = "Oziq-ovqat"

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Yangi Tranzaksiya"
        setupUI()
        setupCategoryMenu()
        updateCategoryVisibility()

        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tap)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func setupUI() {
        titleField.borderStyle = .roundedRect
        amountField.placeholder = "Miqdori"
        amountField.borderStyle = .roundedRect
        amountField.keyboardType = .decimalPad

        typeSegment.selectedSegmentIndex = 1
        typeSegment.addTarget(self, action: #selector(typeChanged), for: .valueChanged)

        categoryButton.setTitle("Kategoriya: Oziq-ovqat", for: .normal)
        categoryButton.backgroundColor = .secondarySystemBackground
        categoryButton.layer.cornerRadius = 8
        categoryButton.contentHorizontalAlignment = .leading
        categoryButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        categoryButton.heightAnchor.constraint(equalToConstant: 44).isActive = true

        saveButton.setTitle("Saqlash", for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.backgroundColor = .systemBlue
        saveButton.layer.cornerRadius = 10
        saveButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        saveButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        let stackView = UIStackView(arrangedSubviews: [typeSegment, titleField, amountField, categoryButton, saveButton])
        stackView.axis = .vertical
        stackView.spacing = 15
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    private func setupCategoryMenu() {
        var actions: [UIAction] = []
        for category in viewModel.expenseCategories {
            let action = UIAction(title: category) { [weak self] action in
                self?.selectedCategory = action.title
                self?.categoryButton.setTitle("Kategoriya: \(action.title)", for: .normal)
                if action.title == "Boshqa..." {
                    self?.titleField.placeholder = "Xarajat nomini kiriting..."
                    self?.titleField.becomeFirstResponder()
                }
            }
            actions.append(action)
        }
        categoryButton.menu = UIMenu(title: "Xarajat kategoriyasi", children: actions)
        categoryButton.showsMenuAsPrimaryAction = true
    }

    @objc private func typeChanged() {
        updateCategoryVisibility()
    }

    private func updateCategoryVisibility() {
        let isIncome = (typeSegment.selectedSegmentIndex == 0)
        categoryButton.isHidden = isIncome
        titleField.placeholder = isIncome ? "Kirim manbai (Masalan: Oylik)" : "Nomi (Masalan: Tushlik)"
    }

    @objc private func saveTapped() {
        guard let titleText = titleField.text, !titleText.isEmpty,
              let amountText = amountField.text, !amountText.isEmpty else { return }

        let cleanedAmount = amountText.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")
        let isIncome = (typeSegment.selectedSegmentIndex == 0)

        viewModel.save(
            title: titleText,
            cleanedAmountText: cleanedAmount,
            isIncome: isIncome,
            selectedCategory: selectedCategory
        ) { error in
            if let error = error {
                print("☁️ Firebase background sync xatosi: \(error.localizedDescription)")
            } else {
                print("✅ Bulut bilan muvaffaqiyatli sinxronlandi!")
            }
        }

        navigationController?.popViewController(animated: true)
    }
}
