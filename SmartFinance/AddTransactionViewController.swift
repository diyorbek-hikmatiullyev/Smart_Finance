
//import UIKit
//
//final class AddTransactionViewController: UIViewController {
//
//    private let viewModel = AddTransactionViewModel()
//
//    let titleField = UITextField()
//    let amountField = UITextField()
//    let typeSegment = UISegmentedControl(items: ["Kirim", "Chiqim"])
//    let categoryButton = UIButton(type: .system)
//    let saveButton = UIButton(type: .system)
//
//    var selectedCategory: String = "Oziq-ovqat"
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = .systemBackground
//        title = "Yangi Tranzaksiya"
//        setupUI()
//        setupCategoryMenu()
//        updateCategoryVisibility()
//
//        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing))
//        view.addGestureRecognizer(tap)
//    }
//
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        navigationController?.setNavigationBarHidden(false, animated: animated)
//    }
//
//    private func setupUI() {
//        titleField.borderStyle = .roundedRect
//        amountField.placeholder = "Miqdori"
//        amountField.borderStyle = .roundedRect
//        amountField.keyboardType = .decimalPad
//
//        typeSegment.selectedSegmentIndex = 1
//        typeSegment.addTarget(self, action: #selector(typeChanged), for: .valueChanged)
//
//        categoryButton.setTitle("Kategoriya: Oziq-ovqat", for: .normal)
//        categoryButton.backgroundColor = .secondarySystemBackground
//        categoryButton.layer.cornerRadius = 8
//        categoryButton.contentHorizontalAlignment = .leading
//        categoryButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
//        categoryButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
//
//        saveButton.setTitle("Saqlash", for: .normal)
//        saveButton.setTitleColor(.white, for: .normal)
//        saveButton.backgroundColor = .systemBlue
//        saveButton.layer.cornerRadius = 10
//        saveButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
//        saveButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
//        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
//
//        let stackView = UIStackView(arrangedSubviews: [typeSegment, titleField, amountField, categoryButton, saveButton])
//        stackView.axis = .vertical
//        stackView.spacing = 15
//        stackView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(stackView)
//
//        NSLayoutConstraint.activate([
//            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
//            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
//            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
//        ])
//    }
//
//    private func setupCategoryMenu() {
//        var actions: [UIAction] = []
//        for category in viewModel.expenseCategories {
//            let action = UIAction(title: category) { [weak self] action in
//                self?.selectedCategory = action.title
//                self?.categoryButton.setTitle("Kategoriya: \(action.title)", for: .normal)
//                if action.title == "Boshqa..." {
//                    self?.titleField.placeholder = "Xarajat nomini kiriting..."
//                    self?.titleField.becomeFirstResponder()
//                }
//            }
//            actions.append(action)
//        }
//        categoryButton.menu = UIMenu(title: "Xarajat kategoriyasi", children: actions)
//        categoryButton.showsMenuAsPrimaryAction = true
//    }
//
//    @objc private func typeChanged() {
//        updateCategoryVisibility()
//    }
//
//    private func updateCategoryVisibility() {
//        let isIncome = (typeSegment.selectedSegmentIndex == 0)
//        categoryButton.isHidden = isIncome
//        titleField.placeholder = isIncome ? "Kirim manbai (Masalan: Oylik)" : "Nomi (Masalan: Tushlik)"
//    }
//
//    @objc private func saveTapped() {
//        guard let titleText = titleField.text, !titleText.isEmpty,
//              let amountText = amountField.text, !amountText.isEmpty else { return }
//
//        let cleanedAmount = amountText.replacingOccurrences(of: " ", with: "")
//            .replacingOccurrences(of: ",", with: ".")
//        let isIncome = (typeSegment.selectedSegmentIndex == 0)
//
//        viewModel.save(
//            title: titleText,
//            cleanedAmountText: cleanedAmount,
//            isIncome: isIncome,
//            selectedCategory: selectedCategory
//        ) { error in
//            if let error = error {
//                print("☁️ Firebase background sync xatosi: \(error.localizedDescription)")
//            } else {
//                print("✅ Bulut bilan muvaffaqiyatli sinxronlandi!")
//            }
//        }
//
//        navigationController?.popViewController(animated: true)
//    }
//}

import UIKit

// MARK: - Currency Model

struct Currency {
    let code: String
    let name: String
    let flag: String
    let rateToUZS: Double  // 1 unit = X UZS
}

// MARK: - AddTransactionViewController

final class AddTransactionViewController: UIViewController {

    private let viewModel = AddTransactionViewModel()

    // MARK: - State
    private var isIncome: Bool = false
    private var selectedCategory: String = "Oziq-ovqat"
    private var selectedCurrency: Currency = Currency(code: "UZS", name: "O'zbek so'mi", flag: "🇺🇿", rateToUZS: 1)
    private var isCurrencyDropdownOpen = false

    private let currencies: [Currency] = [
        Currency(code: "UZS", name: "O'zbek so'mi",   flag: "🇺🇿", rateToUZS: 1),
        Currency(code: "USD", name: "AQSh dollari",    flag: "🇺🇸", rateToUZS: 12850),
        Currency(code: "EUR", name: "Yevro",           flag: "🇪🇺", rateToUZS: 13920),
        Currency(code: "RUB", name: "Rossiya rubli",   flag: "🇷🇺", rateToUZS: 140),
    ]

    private let categories: [(name: String, icon: String, systemIcon: String)] = [
        ("Oziq-ovqat", "🍔", "cart.fill"),
        ("Transport",  "🚗", "car.fill"),
        ("Ijara",      "🏠", "house.fill"),
        ("Kiyim",      "👜", "tshirt.fill"),
        ("O'yin-kulgi","✨", "gamecontroller.fill"),
        ("Salomatlik", "💊", "cross.case.fill"),
        ("Boshqa",     "📦", "square.fill"),
    ]

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // Type toggle
    private let typeContainer = UIView()
    private let incomeButton  = UIButton(type: .system)
    private let expenseButton = UIButton(type: .system)
    private let toggleSlider  = UIView()

    // Amount card
    private let amountCard        = UIView()
    private let currencyButton    = UIButton(type: .system)
    private let amountTextField   = UITextField()
    private let convertedLabel    = UILabel()
    private let currencyDropdown  = UIView()
    private var dropdownRows: [UIButton] = []

    // Name field
    private let nameField = PaddedTextField()

    // Category grid
    private let categoryStack = UIStackView()
    private var categoryButtons: [UIButton] = []

    // Save button
    private let saveButton = UIButton(type: .system)

    // Constraints for animation
    private var dropdownHeightConstraint: NSLayoutConstraint!

    // MARK: - Colors
    private let accentTeal = UIColor(red: 91/255, green: 173/255, blue: 198/255, alpha: 1)
    private let incomeGreen = UIColor(red: 29/255, green: 158/255, blue: 117/255, alpha: 1)
    private let expenseOrange = UIColor(red: 217/255, green: 90/255, blue: 48/255, alpha: 1)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemGroupedBackground
        title = "Yangi tranzaksiya"
        navigationItem.largeTitleDisplayMode = .never

        setupScrollView()
        setupTypeToggle()
        setupAmountCard()
        setupNameField()
        setupCategorySection()
        setupSaveButton()
        activateConstraints()
        updateTypeUI(animated: false)

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        amountTextField.addTarget(self, action: #selector(amountChanged), for: .editingChanged)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Setup: Scroll

    private func setupScrollView() {
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
    }

    // MARK: - Setup: Type Toggle

    private func setupTypeToggle() {
        typeContainer.backgroundColor = UIColor.secondarySystemGroupedBackground
        typeContainer.layer.cornerRadius = 16
        typeContainer.translatesAutoresizingMaskIntoConstraints = false

        toggleSlider.layer.cornerRadius = 12
        toggleSlider.translatesAutoresizingMaskIntoConstraints = false

        func configBtn(_ btn: UIButton, title: String, icon: String) {
            var config = UIButton.Configuration.plain()
            config.title = title
            config.image = UIImage(systemName: icon, withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .medium))
            config.imagePadding = 6
            config.imagePlacement = .leading
            btn.configuration = config
            btn.layer.cornerRadius = 12
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.addTarget(self, action: #selector(typeChanged(_:)), for: .touchUpInside)
        }

        configBtn(incomeButton,  title: "Kirim",  icon: "arrow.down.circle.fill")
        configBtn(expenseButton, title: "Chiqim", icon: "arrow.up.circle.fill")
        incomeButton.tag  = 0
        expenseButton.tag = 1

        [toggleSlider, incomeButton, expenseButton].forEach { typeContainer.addSubview($0) }
        contentView.addSubview(typeContainer)
    }

    // MARK: - Setup: Amount Card

    private func setupAmountCard() {
        amountCard.backgroundColor = UIColor.secondarySystemGroupedBackground
        amountCard.layer.cornerRadius = 24
        amountCard.translatesAutoresizingMaskIntoConstraints = false

        // Currency button
        currencyButton.backgroundColor = UIColor.tertiarySystemGroupedBackground
        currencyButton.layer.cornerRadius = 16
        currencyButton.layer.borderWidth = 0.5
        currencyButton.layer.borderColor = UIColor.separator.cgColor
        currencyButton.translatesAutoresizingMaskIntoConstraints = false
        currencyButton.addTarget(self, action: #selector(toggleCurrencyDropdown), for: .touchUpInside)
        updateCurrencyButton()

        // Amount field
        amountTextField.placeholder = "0"
        amountTextField.font = .systemFont(ofSize: 48, weight: .bold)
        amountTextField.textAlignment = .center
        amountTextField.keyboardType = .decimalPad
        amountTextField.borderStyle = .none
        amountTextField.backgroundColor = .clear
        amountTextField.translatesAutoresizingMaskIntoConstraints = false

        // Converted label
        convertedLabel.font = .systemFont(ofSize: 14, weight: .regular)
        convertedLabel.textColor = .tertiaryLabel
        convertedLabel.textAlignment = .center
        convertedLabel.text = " "
        convertedLabel.translatesAutoresizingMaskIntoConstraints = false

        // Currency Dropdown
        currencyDropdown.backgroundColor = UIColor.secondarySystemGroupedBackground
        currencyDropdown.layer.cornerRadius = 16
        currencyDropdown.layer.borderWidth = 0.5
        currencyDropdown.layer.borderColor = UIColor.separator.cgColor
        currencyDropdown.clipsToBounds = true
        currencyDropdown.translatesAutoresizingMaskIntoConstraints = false

        let dropdownStack = UIStackView()
        dropdownStack.axis = .vertical
        dropdownStack.translatesAutoresizingMaskIntoConstraints = false

        for (i, currency) in currencies.enumerated() {
            let row = makeCurrencyRow(currency: currency, index: i)
            dropdownStack.addArrangedSubview(row)
            if i < currencies.count - 1 {
                let sep = UIView()
                sep.backgroundColor = UIColor.separator.withAlphaComponent(0.3)
                sep.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
                dropdownStack.addArrangedSubview(sep)
            }
        }

        currencyDropdown.addSubview(dropdownStack)
        NSLayoutConstraint.activate([
            dropdownStack.topAnchor.constraint(equalTo: currencyDropdown.topAnchor),
            dropdownStack.leadingAnchor.constraint(equalTo: currencyDropdown.leadingAnchor),
            dropdownStack.trailingAnchor.constraint(equalTo: currencyDropdown.trailingAnchor),
            dropdownStack.bottomAnchor.constraint(equalTo: currencyDropdown.bottomAnchor),
        ])

        [currencyButton, amountTextField, convertedLabel, currencyDropdown].forEach { amountCard.addSubview($0) }
        contentView.addSubview(amountCard)
    }

    private func makeCurrencyRow(currency: Currency, index: Int) -> UIButton {
        let btn = UIButton(type: .system)
        btn.tag = index
        btn.addTarget(self, action: #selector(currencySelected(_:)), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.heightAnchor.constraint(equalToConstant: 56).isActive = true

        let flagLabel = UILabel()
        flagLabel.text = currency.flag
        flagLabel.font = .systemFont(ofSize: 24)
        flagLabel.translatesAutoresizingMaskIntoConstraints = false

        let codeLabel = UILabel()
        codeLabel.text = currency.code
        codeLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        codeLabel.textColor = .label
        codeLabel.translatesAutoresizingMaskIntoConstraints = false

        let nameLabel = UILabel()
        nameLabel.text = currency.name
        nameLabel.font = .systemFont(ofSize: 12, weight: .regular)
        nameLabel.textColor = .secondaryLabel
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        let textStack = UIStackView(arrangedSubviews: [codeLabel, nameLabel])
        textStack.axis = .vertical
        textStack.spacing = 1
        textStack.translatesAutoresizingMaskIntoConstraints = false

        let rateLabel = UILabel()
        if currency.code == "UZS" {
            rateLabel.text = "asosiy"
            rateLabel.textColor = accentTeal
        } else {
            let formatted = formatSum(currency.rateToUZS)
            rateLabel.text = "1 = \(formatted) so'm"
            rateLabel.textColor = .secondaryLabel
        }
        rateLabel.font = .systemFont(ofSize: 12, weight: .regular)
        rateLabel.translatesAutoresizingMaskIntoConstraints = false

        [flagLabel, textStack, rateLabel].forEach { btn.addSubview($0) }

        NSLayoutConstraint.activate([
            flagLabel.leadingAnchor.constraint(equalTo: btn.leadingAnchor, constant: 16),
            flagLabel.centerYAnchor.constraint(equalTo: btn.centerYAnchor),

            textStack.leadingAnchor.constraint(equalTo: flagLabel.trailingAnchor, constant: 12),
            textStack.centerYAnchor.constraint(equalTo: btn.centerYAnchor),

            rateLabel.trailingAnchor.constraint(equalTo: btn.trailingAnchor, constant: -16),
            rateLabel.centerYAnchor.constraint(equalTo: btn.centerYAnchor),
        ])

        dropdownRows.append(btn)
        return btn
    }

    private func updateCurrencyButton() {
        var config = UIButton.Configuration.plain()
        config.title = "\(selectedCurrency.flag)  \(selectedCurrency.code)"
        let chevron = UIImage(systemName: isCurrencyDropdownOpen ? "chevron.up" : "chevron.down",
                              withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold))
        config.image = chevron
        config.imagePlacement = .trailing
        config.imagePadding = 6
        config.baseForegroundColor = .label
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 12)
        currencyButton.configuration = config
        currencyButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
    }

    // MARK: - Setup: Name Field

    private func setupNameField() {
        nameField.placeholder = "Nomi (masalan: Tushlik, Oylik...)"
        nameField.font = .systemFont(ofSize: 16)
        nameField.backgroundColor = UIColor.secondarySystemGroupedBackground
        nameField.layer.cornerRadius = 16
        nameField.layer.borderWidth = 0.5
        nameField.layer.borderColor = UIColor.separator.cgColor
        nameField.translatesAutoresizingMaskIntoConstraints = false
        nameField.returnKeyType = .done
        nameField.delegate = self
        contentView.addSubview(nameField)
    }

    // MARK: - Setup: Category

    private func setupCategorySection() {
        let sectionLabel = UILabel()
        sectionLabel.text = "Kategoriya"
        sectionLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        sectionLabel.textColor = .secondaryLabel
        sectionLabel.textTransform(uppercase: true)
        sectionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(sectionLabel)

        let row1 = UIStackView()
        let row2 = UIStackView()
        [row1, row2].forEach {
            $0.axis = .horizontal
            $0.spacing = 10
            $0.distribution = .fillEqually
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        categoryStack.axis = .vertical
        categoryStack.spacing = 10
        categoryStack.translatesAutoresizingMaskIntoConstraints = false
        categoryStack.addArrangedSubview(row1)
        categoryStack.addArrangedSubview(row2)
        contentView.addSubview(categoryStack)

        for (index, cat) in categories.enumerated() {
            let btn = makeCategoryButton(cat: cat, index: index)
            categoryButtons.append(btn)
            if index < 4 { row1.addArrangedSubview(btn) }
            else         { row2.addArrangedSubview(btn) }
        }

        // Store label ref
        objc_setAssociatedObject(self, &AssocKeys.sectionLabel, sectionLabel, .OBJC_ASSOCIATION_RETAIN)
        selectCategory(index: 0)
    }

    private func makeCategoryButton(cat: (name: String, icon: String, systemIcon: String), index: Int) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.tag = index
        btn.addTarget(self, action: #selector(categoryTapped(_:)), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.heightAnchor.constraint(equalToConstant: 72).isActive = true
        btn.layer.cornerRadius = 16
        btn.backgroundColor = UIColor.secondarySystemGroupedBackground
        btn.layer.borderWidth = 1
        btn.layer.borderColor = UIColor.clear.cgColor

        let emojiLabel = UILabel()
        emojiLabel.text = cat.icon
        emojiLabel.font = .systemFont(ofSize: 24)
        emojiLabel.textAlignment = .center
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false

        let nameLabel = UILabel()
        nameLabel.text = cat.name
        nameLabel.font = .systemFont(ofSize: 11, weight: .medium)
        nameLabel.textColor = .secondaryLabel
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 2
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        btn.addSubview(emojiLabel)
        btn.addSubview(nameLabel)

        NSLayoutConstraint.activate([
            emojiLabel.topAnchor.constraint(equalTo: btn.topAnchor, constant: 12),
            emojiLabel.centerXAnchor.constraint(equalTo: btn.centerXAnchor),

            nameLabel.topAnchor.constraint(equalTo: emojiLabel.bottomAnchor, constant: 4),
            nameLabel.leadingAnchor.constraint(equalTo: btn.leadingAnchor, constant: 4),
            nameLabel.trailingAnchor.constraint(equalTo: btn.trailingAnchor, constant: -4),
        ])

        return btn
    }

    // MARK: - Setup: Save Button

    private func setupSaveButton() {
        saveButton.setTitle("Saqlash", for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        saveButton.layer.cornerRadius = 18
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        contentView.addSubview(saveButton)
    }

    // MARK: - Constraints

    private func activateConstraints() {
        let sectionLabel = objc_getAssociatedObject(self, &AssocKeys.sectionLabel) as? UILabel
        let pad: CGFloat = 20

        dropdownHeightConstraint = currencyDropdown.heightAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            // Type toggle
            typeContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            typeContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            typeContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            typeContainer.heightAnchor.constraint(equalToConstant: 52),

            incomeButton.topAnchor.constraint(equalTo: typeContainer.topAnchor, constant: 4),
            incomeButton.bottomAnchor.constraint(equalTo: typeContainer.bottomAnchor, constant: -4),
            incomeButton.leadingAnchor.constraint(equalTo: typeContainer.leadingAnchor, constant: 4),
            incomeButton.widthAnchor.constraint(equalTo: typeContainer.widthAnchor, multiplier: 0.5, constant: -6),

            expenseButton.topAnchor.constraint(equalTo: typeContainer.topAnchor, constant: 4),
            expenseButton.bottomAnchor.constraint(equalTo: typeContainer.bottomAnchor, constant: -4),
            expenseButton.trailingAnchor.constraint(equalTo: typeContainer.trailingAnchor, constant: -4),
            expenseButton.leadingAnchor.constraint(equalTo: incomeButton.trailingAnchor, constant: 4),

            // Amount card
            amountCard.topAnchor.constraint(equalTo: typeContainer.bottomAnchor, constant: 16),
            amountCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            amountCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),

            currencyButton.topAnchor.constraint(equalTo: amountCard.topAnchor, constant: 16),
            currencyButton.centerXAnchor.constraint(equalTo: amountCard.centerXAnchor),
            currencyButton.heightAnchor.constraint(equalToConstant: 34),

            amountTextField.topAnchor.constraint(equalTo: currencyButton.bottomAnchor, constant: 8),
            amountTextField.leadingAnchor.constraint(equalTo: amountCard.leadingAnchor, constant: 16),
            amountTextField.trailingAnchor.constraint(equalTo: amountCard.trailingAnchor, constant: -16),
            amountTextField.heightAnchor.constraint(equalToConstant: 64),

            convertedLabel.topAnchor.constraint(equalTo: amountTextField.bottomAnchor, constant: 2),
            convertedLabel.leadingAnchor.constraint(equalTo: amountCard.leadingAnchor, constant: 16),
            convertedLabel.trailingAnchor.constraint(equalTo: amountCard.trailingAnchor, constant: -16),

            dropdownHeightConstraint,
            currencyDropdown.topAnchor.constraint(equalTo: convertedLabel.bottomAnchor, constant: 12),
            currencyDropdown.leadingAnchor.constraint(equalTo: amountCard.leadingAnchor, constant: 12),
            currencyDropdown.trailingAnchor.constraint(equalTo: amountCard.trailingAnchor, constant: -12),
            currencyDropdown.bottomAnchor.constraint(equalTo: amountCard.bottomAnchor, constant: -16),

            // Name field
            nameField.topAnchor.constraint(equalTo: amountCard.bottomAnchor, constant: 16),
            nameField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            nameField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            nameField.heightAnchor.constraint(equalToConstant: 54),

            // Category section label
            (sectionLabel?.topAnchor.constraint(equalTo: nameField.bottomAnchor, constant: 24))!,
            (sectionLabel?.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad))!,

            // Category stack
            categoryStack.topAnchor.constraint(equalTo: (sectionLabel?.bottomAnchor ?? nameField.bottomAnchor), constant: 8),
            categoryStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            categoryStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),

            // Save button
            saveButton.topAnchor.constraint(equalTo: categoryStack.bottomAnchor, constant: 28),
            saveButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            saveButton.heightAnchor.constraint(equalToConstant: 56),
            saveButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),
        ])
    }

    // MARK: - Type UI

    private func updateTypeUI(animated: Bool) {
        let color = isIncome ? incomeGreen : accentTeal
        let changes = {
            self.toggleSlider.backgroundColor = .white
            if self.isIncome {
                self.toggleSlider.frame = self.incomeButton.frame
                self.incomeButton.tintColor = self.incomeGreen
                self.incomeButton.setTitleColor(self.incomeGreen, for: .normal)
                self.expenseButton.tintColor = .secondaryLabel
                self.expenseButton.setTitleColor(.secondaryLabel, for: .normal)
            } else {
                self.toggleSlider.frame = self.expenseButton.frame
                self.expenseButton.tintColor = self.accentTeal
                self.expenseButton.setTitleColor(self.accentTeal, for: .normal)
                self.incomeButton.tintColor = .secondaryLabel
                self.incomeButton.setTitleColor(.secondaryLabel, for: .normal)
            }
            self.saveButton.backgroundColor = color
            self.amountTextField.textColor = color
        }
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0,
                           usingSpringWithDamping: 0.85, initialSpringVelocity: 0.2,
                           animations: changes)
        } else {
            view.layoutIfNeeded()
            changes()
        }
    }

    // MARK: - Category

    private func selectCategory(index: Int) {
        for (i, btn) in categoryButtons.enumerated() {
            let isSelected = i == index
            UIView.animate(withDuration: 0.2) {
                btn.backgroundColor = isSelected
                    ? (self.isIncome ? self.incomeGreen : self.accentTeal).withAlphaComponent(0.12)
                    : UIColor.secondarySystemGroupedBackground
                btn.layer.borderColor = isSelected
                    ? (self.isIncome ? self.incomeGreen : self.accentTeal).withAlphaComponent(0.6).cgColor
                    : UIColor.clear.cgColor
            }
            if let nameLabel = btn.subviews.compactMap({ $0 as? UILabel }).last {
                nameLabel.textColor = isSelected
                    ? (isIncome ? incomeGreen : accentTeal)
                    : .secondaryLabel
            }
        }
        selectedCategory = categories[index].name
    }

    // MARK: - Amount / Conversion

    @objc private func amountChanged() {
        guard selectedCurrency.code != "UZS" else {
            convertedLabel.text = " "
            return
        }
        let raw = Double(amountTextField.text?.replacingOccurrences(of: ",", with: ".") ?? "") ?? 0
        let inUZS = raw * selectedCurrency.rateToUZS
        convertedLabel.text = "≈ \(formatSum(inUZS)) so'm"
    }

    private func formatSum(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = " "
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }

    // MARK: - Actions

    @objc private func typeChanged(_ sender: UIButton) {
        isIncome = (sender.tag == 0)
        updateTypeUI(animated: true)
        nameField.placeholder = isIncome
            ? "Kirim manbai (masalan: Oylik...)"
            : "Xarajat nomi (masalan: Tushlik...)"
        // Refresh category colors
        for (i, btn) in categoryButtons.enumerated() {
            if btn.layer.borderColor != UIColor.clear.cgColor {
                selectCategory(index: i)
                break
            }
        }
    }

    @objc private func toggleCurrencyDropdown() {
        isCurrencyDropdownOpen.toggle()
        updateCurrencyButton()

        let rowHeight: CGFloat = 56
        let sepCount  = CGFloat(currencies.count - 1) * 0.5
        let totalH    = CGFloat(currencies.count) * rowHeight + sepCount

        UIView.animate(withDuration: 0.35, delay: 0,
                       usingSpringWithDamping: 0.85, initialSpringVelocity: 0.2) {
            self.dropdownHeightConstraint.constant = self.isCurrencyDropdownOpen ? totalH : 0
            self.currencyDropdown.alpha = self.isCurrencyDropdownOpen ? 1 : 0
            self.view.layoutIfNeeded()
        }
    }

    @objc private func currencySelected(_ sender: UIButton) {
        selectedCurrency = currencies[sender.tag]
        isCurrencyDropdownOpen = false
        updateCurrencyButton()

        UIView.animate(withDuration: 0.3) {
            self.dropdownHeightConstraint.constant = 0
            self.currencyDropdown.alpha = 0
            self.view.layoutIfNeeded()
        }
        amountChanged()
    }

    @objc private func categoryTapped(_ sender: UIButton) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        selectCategory(index: sender.tag)
    }

    @objc private func saveTapped() {
        guard let titleText = nameField.text, !titleText.isEmpty,
              let amountText = amountTextField.text, !amountText.isEmpty else {
            shakeInvalidFields()
            return
        }

        let cleanedAmount = amountText.replacingOccurrences(of: " ", with: "")
                                      .replacingOccurrences(of: ",", with: ".")
        guard let rawAmount = Double(cleanedAmount), rawAmount > 0 else {
            shakeInvalidFields()
            return
        }

        // Convert to UZS if needed
        let amountInUZS = rawAmount * selectedCurrency.rateToUZS

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        // Animate save button
        UIView.animate(withDuration: 0.12) {
            self.saveButton.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        } completion: { _ in
            UIView.animate(withDuration: 0.2, delay: 0,
                           usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5) {
                self.saveButton.transform = .identity
            }
        }

        viewModel.save(
            title: titleText,
            cleanedAmountText: String(amountInUZS),
            isIncome: isIncome,
            selectedCategory: selectedCategory
        ) { error in
            if let error = error {
                print("☁️ Xato: \(error.localizedDescription)")
            }
        }

        navigationController?.popViewController(animated: true)
    }

    private func shakeInvalidFields() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        let fields: [UIView] = [amountTextField, nameField].filter {
            if let tf = $0 as? UITextField { return tf.text?.isEmpty ?? true }
            return false
        }
        for field in fields {
            let anim = CAKeyframeAnimation(keyPath: "transform.translation.x")
            anim.timingFunction = CAMediaTimingFunction(name: .linear)
            anim.duration = 0.45
            anim.values = [-10, 10, -8, 8, -5, 5, 0]
            field.layer.add(anim, forKey: "shake")
        }
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
        if isCurrencyDropdownOpen {
            isCurrencyDropdownOpen = false
            updateCurrencyButton()
            UIView.animate(withDuration: 0.25) {
                self.dropdownHeightConstraint.constant = 0
                self.currencyDropdown.alpha = 0
                self.view.layoutIfNeeded()
            }
        }
    }
}

// MARK: - UITextFieldDelegate

extension AddTransactionViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - PaddedTextField

final class PaddedTextField: UITextField {
    private let padding = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    override func textRect(forBounds bounds: CGRect) -> CGRect { bounds.inset(by: padding) }
    override func editingRect(forBounds bounds: CGRect) -> CGRect { bounds.inset(by: padding) }
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect { bounds.inset(by: padding) }
}

// MARK: - UILabel Extension

extension UILabel {
    func textTransform(uppercase: Bool) {
        if uppercase, let t = text { text = t.uppercased() }
    }
}

// MARK: - Associated Object Keys

private enum AssocKeys {
    static var sectionLabel = "sectionLabel"
}
