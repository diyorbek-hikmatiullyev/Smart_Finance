// AIAdvisorViewController.swift
// SmartFinance
// AI Moliyaviy Maslahatchi — chat interfeysi

import UIKit
import CoreData
import FirebaseAuth

// MARK: - Chat Message Model

struct ChatMessage {
    enum Role { case user, assistant }
    let role: Role
    let text: String
    let timestamp: Date
}

// MARK: - AIAdvisorViewController

final class AIAdvisorViewController: UIViewController {

    // Ma'lumotlar DashboardVC dan uzatiladi
    var transactions: [Transaction] = []
    var periodLabel: String = "joriy oy"

    // MARK: - UI

    // Header
    private let headerView    = UIView()
    private let titleLabel    = UILabel()
    private let subtitleLabel = UILabel()
    private let closeButton   = UIButton(type: .system)
    private let headerDivider = UIView()

    // Quick suggestions
    private let suggestionsStack = UIStackView()
    private let suggestionsScroll = UIScrollView()

    // Chat table
    private let tableView = UITableView(frame: .zero, style: .plain)

    // Input bar
    private let inputBar       = UIView()
    private let textField      = UITextField()
    private let sendButton     = UIButton(type: .system)
    private var inputBarBottomConstraint: NSLayoutConstraint!

    // Loading indicator
    private let typingIndicator = TypingIndicatorView()

    // MARK: - State

    private var messages: [ChatMessage] = []
    private var isLoading = false
    private var summary: FinancialSummary?

    // MARK: - Colors

    private let accentColor = UIColor(red: 91/255, green: 173/255, blue: 198/255, alpha: 1)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        buildUI()
        buildSummary()
        showWelcomeMessage()
        registerKeyboardNotifications()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Build: summary

    private func buildSummary() {
        let filtered = transactions.filter {
            guard let date = $0.date else { return false }
            return Calendar.current.isDate(date, equalTo: Date(), toGranularity: .month)
        }
        summary = AIPromptBuilder.buildSummary(from: filtered, periodLabel: periodLabel)
    }

    // MARK: - Build: UI

    private func buildUI() {
        buildHeader()
        buildSuggestions()
        buildTableView()
        buildInputBar()
        activateConstraints()
    }

    private func buildHeader() {
        headerView.backgroundColor = .systemBackground
        headerView.translatesAutoresizingMaskIntoConstraints = false

        // AI avatar badge
        let avatarView = UIView()
        avatarView.backgroundColor = accentColor.withAlphaComponent(0.15)
        avatarView.layer.cornerRadius = 20
        avatarView.translatesAutoresizingMaskIntoConstraints = false

        let avatarIcon = UIImageView()
        let conf = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        avatarIcon.image = UIImage(systemName: "brain.head.profile", withConfiguration: conf)
        avatarIcon.tintColor = accentColor
        avatarIcon.contentMode = .scaleAspectFit
        avatarIcon.translatesAutoresizingMaskIntoConstraints = false
        avatarView.addSubview(avatarIcon)

        titleLabel.text = "AI Moliyaviy Maslahatchi"
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        subtitleLabel.text = "Xarajatlaringizni tahlil qilaman"
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        let xConf = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: xConf), for: .normal)
        closeButton.tintColor = .tertiaryLabel
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        headerDivider.backgroundColor = UIColor.separator.withAlphaComponent(0.4)
        headerDivider.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(headerView)
        [avatarView, titleLabel, subtitleLabel, closeButton, headerDivider].forEach { headerView.addSubview($0) }

        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            avatarView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor, constant: -6),
            avatarView.widthAnchor.constraint(equalToConstant: 40),
            avatarView.heightAnchor.constraint(equalToConstant: 40),

            avatarIcon.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarIcon.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            avatarIcon.widthAnchor.constraint(equalToConstant: 20),
            avatarIcon.heightAnchor.constraint(equalToConstant: 20),

            titleLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: avatarView.topAnchor, constant: 2),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),

            closeButton.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 28),
            closeButton.heightAnchor.constraint(equalToConstant: 28),

            headerDivider.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            headerDivider.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            headerDivider.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            headerDivider.heightAnchor.constraint(equalToConstant: 0.5),
        ])
    }

    private func buildSuggestions() {
        suggestionsScroll.showsHorizontalScrollIndicator = false
        suggestionsScroll.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        suggestionsScroll.translatesAutoresizingMaskIntoConstraints = false

        suggestionsStack.axis = .horizontal
        suggestionsStack.spacing = 8
        suggestionsStack.translatesAutoresizingMaskIntoConstraints = false
        suggestionsScroll.addSubview(suggestionsStack)

        // (emoji, ko'rsatiladigan matn, AI ga yuboriladigan prompt)
        let suggestions: [(String, String, String)] = [
            ("📊", "Umumiy tahlil",      "Bu oylik moliyaviy vaziyatimni to'liq tahlil qil: daromad, xarajat, balans va eng muhim xulosalarni ayt."),
            ("✂️", "Qanday tejay?",      "Mening xarajatlarimni ko'rib, qaysi kategoriyada eng ko'p tejash mumkin? Aniq miqdorlar bilan ayt."),
            ("🚨", "Xavfli xarajatlar", "Qaysi xarajatlarim me'yordan oshgan yoki moliyaviy xavf tug'dirmoqda? Foiz va raqamlar bilan tushuntir."),
            ("📈", "Kelasi oy rejasi",   "Hozirgi xarajat tezligim asosida kelasi oy uchun optimal byudjet rejasini tuz."),
            ("💰", "Daromad/Xarajat",   "Daromad va xarajat nisbatimni tahlil qil. Idealni qanday ko'rsatib, farqni qanday qisqartirish mumkin?"),
            ("🎯", "Maqsad qo'y",       "Mening moliyaviy ahvolimga qarab, kelasi 3 oyga real tejash maqsadi qo'y va unga erishish yo'lini ko'rsat."),
            ("🏆", "Top xarajatlar",    "Eng katta 3 ta xarajat kategoriyamni tahlil qil va har birida qancha tejash mumkinligini ayt."),
            ("📉", "Balans ogohlantirish", "Balansingiz nima uchun bunday ahvolda? Asosiy sabab va tezkor yechimni ayt."),
        ]

        for (emoji, label, _) in suggestions {
            let btn = makeSuggestionButton(emoji: emoji, label: label)
            suggestionsStack.addArrangedSubview(btn)
        }

        // Prompt map saqlab olish (tag orqali)
        for (i, (_, _, prompt)) in suggestions.enumerated() {
            if let btn = suggestionsStack.arrangedSubviews[i] as? UIButton {
                btn.tag = i
                promptMap[i] = prompt
            }
        }

        view.addSubview(suggestionsScroll)
    }

    // Suggestion prompt lug'ati
    private var promptMap: [Int: String] = [:]

    private func makeSuggestionButton(emoji: String, label: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle("\(emoji)  \(label)", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        btn.tintColor = accentColor
        btn.backgroundColor = accentColor.withAlphaComponent(0.1)
        btn.layer.cornerRadius = 16
        btn.contentEdgeInsets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
        btn.addTarget(self, action: #selector(suggestionTapped(_:)), for: .touchUpInside)
        return btn
    }

    private func buildTableView() {
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle  = .none
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableView.automaticDimension
        tableView.keyboardDismissMode = .interactive
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        tableView.register(UserMessageCell.self,  forCellReuseIdentifier: "UserCell")
        tableView.register(AIMessageCell.self,    forCellReuseIdentifier: "AICell")
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        view.addSubview(typingIndicator)
        typingIndicator.translatesAutoresizingMaskIntoConstraints = false
        typingIndicator.isHidden = true
    }

    private func buildInputBar() {
        inputBar.backgroundColor = .systemBackground
        inputBar.layer.borderWidth = 0.5
        inputBar.layer.borderColor = UIColor.separator.cgColor
        inputBar.translatesAutoresizingMaskIntoConstraints = false

        textField.placeholder = "Savol bering..."
        textField.backgroundColor = UIColor.secondarySystemBackground
        textField.layer.cornerRadius = 20
        textField.leftView  = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.leftViewMode  = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.rightViewMode = .always
        textField.returnKeyType = .send
        textField.delegate = self
        textField.translatesAutoresizingMaskIntoConstraints = false

        let conf = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        sendButton.setImage(UIImage(systemName: "arrow.up.circle.fill", withConfiguration: conf), for: .normal)
        sendButton.tintColor = accentColor
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)

        view.addSubview(inputBar)
        [textField, sendButton].forEach { inputBar.addSubview($0) }

        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: inputBar.topAnchor, constant: 10),
            textField.bottomAnchor.constraint(equalTo: inputBar.bottomAnchor, constant: -10),
            textField.leadingAnchor.constraint(equalTo: inputBar.leadingAnchor, constant: 12),
            textField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            textField.heightAnchor.constraint(equalToConstant: 40),

            sendButton.centerYAnchor.constraint(equalTo: inputBar.centerYAnchor),
            sendButton.trailingAnchor.constraint(equalTo: inputBar.trailingAnchor, constant: -12),
            sendButton.widthAnchor.constraint(equalToConstant: 36),
            sendButton.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    private func activateConstraints() {
        inputBarBottomConstraint = inputBar.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor
        )

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 64),

            suggestionsScroll.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 10),
            suggestionsScroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            suggestionsScroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            suggestionsScroll.heightAnchor.constraint(equalToConstant: 38),

            suggestionsStack.topAnchor.constraint(equalTo: suggestionsScroll.topAnchor),
            suggestionsStack.bottomAnchor.constraint(equalTo: suggestionsScroll.bottomAnchor),
            suggestionsStack.leadingAnchor.constraint(equalTo: suggestionsScroll.contentLayoutGuide.leadingAnchor),
            suggestionsStack.trailingAnchor.constraint(equalTo: suggestionsScroll.contentLayoutGuide.trailingAnchor),
            suggestionsStack.heightAnchor.constraint(equalTo: suggestionsScroll.frameLayoutGuide.heightAnchor),

            tableView.topAnchor.constraint(equalTo: suggestionsScroll.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: typingIndicator.topAnchor),

            typingIndicator.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            typingIndicator.bottomAnchor.constraint(equalTo: inputBar.topAnchor, constant: -8),
            typingIndicator.widthAnchor.constraint(equalToConstant: 60),
            typingIndicator.heightAnchor.constraint(equalToConstant: 28),

            inputBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputBarBottomConstraint,
        ])
    }

    // MARK: - Welcome message

    private func showWelcomeMessage() {
        guard let summary = summary else { return }
        let balanceText = summary.balance >= 0
            ? "✅ Balansingiz musbat — yaxshi!"
            : "⚠️ Balansingiz manfiy — diqqat kerak!"

        let welcome = """
        Salom! Men sizning moliyaviy yordamchingizman. 🤖

        \(summary.periodLabel) davri uchun:
        • Daromad: \(formatSum(summary.totalIncome))
        • Xarajat: \(formatSum(summary.totalExpense))
        \(balanceText)

        Quyidagi tugmalardan birini bosing yoki o'z savolingizni yozing!
        """

        addMessage(ChatMessage(role: .assistant, text: welcome, timestamp: Date()))
    }

    // MARK: - Send logic

    @objc private func sendTapped() {
        let text = (textField.text ?? "").trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, !isLoading else { return }
        sendMessage(text)
    }

    @objc private func suggestionTapped(_ sender: UIButton) {
        guard !isLoading else { return }
        // Ko'rsatiladigan matn (emoji + label)
        guard let displayTitle = sender.title(for: .normal) else { return }
        // AI ga yuboriladigan to'liq prompt
        let aiPrompt = promptMap[sender.tag] ?? displayTitle
        // Chatda foydalanuvchi xabari sifatida qisqa matn ko'rsatiladi
        let shortLabel = displayTitle.trimmingCharacters(in: .whitespaces)
        textField.text = ""
        addMessage(ChatMessage(role: .user, text: shortLabel, timestamp: Date()))
        setLoading(true)

        guard let summary = summary else { setLoading(false); return }
        let placeholderIdx = messages.count
        addMessage(ChatMessage(role: .assistant, text: "", timestamp: Date()))
        var accumulated = ""

        AIFinanceService.shared.getAdvice(
            summary: summary,
            userQuestion: aiPrompt,
            onStream: { [weak self] chunk in
                guard let self = self else { return }
                accumulated += chunk
                self.messages[placeholderIdx] = ChatMessage(role: .assistant, text: accumulated, timestamp: Date())
                self.tableView.reloadRows(at: [IndexPath(row: placeholderIdx, section: 0)], with: .none)
                self.scrollToBottom(animated: false)
            },
            onComplete: { [weak self] result in
                guard let self = self else { return }
                self.setLoading(false)
                if case .failure(let error) = result {
                    self.messages[placeholderIdx] = ChatMessage(role: .assistant, text: "❌ Xatolik: \(error.localizedDescription)", timestamp: Date())
                    self.tableView.reloadRows(at: [IndexPath(row: placeholderIdx, section: 0)], with: .none)
                }
            }
        )
    }

    private func sendMessage(_ text: String) {
        textField.text = ""
        addMessage(ChatMessage(role: .user, text: text, timestamp: Date()))
        setLoading(true)

        guard let summary = summary else { setLoading(false); return }

        // Placeholder AI xabar (stream uchun)
        let placeholderIdx = messages.count
        addMessage(ChatMessage(role: .assistant, text: "", timestamp: Date()))
        var accumulated = ""

        AIFinanceService.shared.getAdvice(
            summary: summary,
            userQuestion: text,
            onStream: { [weak self] chunk in
                guard let self = self else { return }
                accumulated += chunk
                self.messages[placeholderIdx] = ChatMessage(
                    role: .assistant, text: accumulated, timestamp: Date()
                )
                self.tableView.reloadRows(
                    at: [IndexPath(row: placeholderIdx, section: 0)],
                    with: .none
                )
                self.scrollToBottom(animated: false)
            },
            onComplete: { [weak self] result in
                guard let self = self else { return }
                self.setLoading(false)
                if case .failure(let error) = result {
                    self.messages[placeholderIdx] = ChatMessage(
                        role: .assistant,
                        text: "❌ Xatolik: \(error.localizedDescription)",
                        timestamp: Date()
                    )
                    self.tableView.reloadRows(
                        at: [IndexPath(row: placeholderIdx, section: 0)],
                        with: .none
                    )
                }
            }
        )
    }

    // MARK: - Helpers

    private func addMessage(_ message: ChatMessage) {
        messages.append(message)
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.insertRows(at: [indexPath], with: .fade)
        scrollToBottom(animated: true)
    }

    private func scrollToBottom(animated: Bool) {
        guard messages.count > 0 else { return }
        let idx = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: idx, at: .bottom, animated: animated)
    }

    private func setLoading(_ loading: Bool) {
        isLoading = loading
        typingIndicator.isHidden = !loading
        if loading { typingIndicator.startAnimating() }
        else { typingIndicator.stopAnimating() }
        sendButton.isEnabled = !loading
    }

    private func formatSum(_ value: Double) -> String {
        let n = NumberFormatter()
        n.numberStyle = .decimal
        n.groupingSeparator = " "
        n.maximumFractionDigits = 0
        return (n.string(from: NSNumber(value: value)) ?? "\(Int(value))") + " so'm"
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    // MARK: - Keyboard

    private func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification, object: nil
        )
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let info = notification.userInfo,
              let frame = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
              let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        let bottomInset = frame.height - view.safeAreaInsets.bottom
        inputBarBottomConstraint.constant = -bottomInset
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
        scrollToBottom(animated: true)
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        inputBarBottomConstraint.constant = 0
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }
}

// MARK: - UITableViewDataSource / Delegate

extension AIAdvisorViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let msg = messages[indexPath.row]
        switch msg.role {
        case .user:
            let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) as! UserMessageCell
            cell.configure(with: msg.text)
            return cell
        case .assistant:
            let cell = tableView.dequeueReusableCell(withIdentifier: "AICell", for: indexPath) as! AIMessageCell
            cell.configure(with: msg.text)
            return cell
        }
    }
}

// MARK: - UITextFieldDelegate

extension AIAdvisorViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendTapped()
        return true
    }
}

// MARK: - UserMessageCell

final class UserMessageCell: UITableViewCell {
    private let bubble = UIView()
    private let label  = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        bubble.backgroundColor = UIColor(red: 91/255, green: 173/255, blue: 198/255, alpha: 1)
        bubble.layer.cornerRadius = 18
        bubble.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner]
        bubble.translatesAutoresizingMaskIntoConstraints = false

        label.font = .systemFont(ofSize: 15)
        label.textColor = .white
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(bubble)
        bubble.addSubview(label)

        NSLayoutConstraint.activate([
            bubble.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubble.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            bubble.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            bubble.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 64),

            label.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 10),
            label.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -10),
            label.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 14),
            label.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -14),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(with text: String) { label.text = text }
}

// MARK: - AIMessageCell

final class AIMessageCell: UITableViewCell {
    private let avatarView = UIView()
    private let bubble     = UIView()
    private let label      = UILabel()

    private let accentColor = UIColor(red: 91/255, green: 173/255, blue: 198/255, alpha: 1)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        avatarView.backgroundColor = accentColor.withAlphaComponent(0.12)
        avatarView.layer.cornerRadius = 14
        avatarView.translatesAutoresizingMaskIntoConstraints = false

        let icon = UIImageView()
        let conf = UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        icon.image = UIImage(systemName: "brain.head.profile", withConfiguration: conf)
        icon.tintColor = accentColor
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        avatarView.addSubview(icon)

        bubble.backgroundColor = .secondarySystemBackground
        bubble.layer.cornerRadius = 18
        bubble.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        bubble.translatesAutoresizingMaskIntoConstraints = false

        label.font = .systemFont(ofSize: 15)
        label.textColor = .label
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(avatarView)
        contentView.addSubview(bubble)
        bubble.addSubview(label)

        NSLayoutConstraint.activate([
            avatarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            avatarView.widthAnchor.constraint(equalToConstant: 28),
            avatarView.heightAnchor.constraint(equalToConstant: 28),

            icon.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 15),
            icon.heightAnchor.constraint(equalToConstant: 15),

            bubble.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubble.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            bubble.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 8),
            bubble.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -64),

            label.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 10),
            label.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -10),
            label.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 14),
            label.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -14),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(with text: String) {
        label.text = text.isEmpty ? "..." : text
    }
}

// MARK: - TypingIndicatorView (3 nuqta animatsiya)

final class TypingIndicatorView: UIView {
    private let dots: [UIView] = (0..<3).map { _ in
        let v = UIView()
        v.backgroundColor = UIColor(red: 91/255, green: 173/255, blue: 198/255, alpha: 0.8)
        v.layer.cornerRadius = 5
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.secondarySystemBackground
        layer.cornerRadius = 14

        let stack = UIStackView(arrangedSubviews: dots)
        stack.axis = .horizontal
        stack.spacing = 5
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        dots.forEach {
            $0.widthAnchor.constraint(equalToConstant: 10).isActive = true
            $0.heightAnchor.constraint(equalToConstant: 10).isActive = true
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    func startAnimating() {
        for (i, dot) in dots.enumerated() {
            UIView.animate(
                withDuration: 0.5,
                delay: Double(i) * 0.15,
                options: [.repeat, .autoreverse],
                animations: { dot.alpha = 0.2 }
            )
        }
    }

    func stopAnimating() {
        dots.forEach {
            $0.layer.removeAllAnimations()
            $0.alpha = 1
        }
    }
}
