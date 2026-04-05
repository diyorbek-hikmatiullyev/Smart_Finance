//
//  AuthViewController.swift
//  SmartFinance
//
//  Created by Diyorbek Xikmatullayev on 28/03/26.
//

//import Foundation
//import UIKit
//import FirebaseAuth
//
//class AuthViewController: UIViewController {
//
//    // 🏗 UI Elementlar
//    let titleLabel = UILabel()
//    let emailTextField = UITextField()
//    let passwordTextField = UITextField()
//    let actionButton = UIButton(type: .system)
//    let toggleButton = UIButton(type: .system)
//    
//    var isLoginMode = true // Rejimni almashtirish uchun
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = .systemBackground
//        setupUI()
//    }
//
//    private func setupUI() {
//        // 1. Title
//        titleLabel.text = "Xush kelibsiz"
//        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
//        
//        // 2. Email Field
//        emailTextField.placeholder = "Email manzilingiz"
//        emailTextField.borderStyle = .roundedRect
//        emailTextField.keyboardType = .emailAddress
//        emailTextField.autocapitalizationType = .none
//
//        // 3. Password Field
//        passwordTextField.placeholder = "Parolingiz"
//        passwordTextField.borderStyle = .roundedRect
//        passwordTextField.isSecureTextEntry = true
//
//        // 4. Action Button (Login/Register)
//        actionButton.setTitle("Kirish", for: .normal)
//        actionButton.backgroundColor = UIColor(red: 91/255, green: 173/255, blue: 198/255, alpha: 1.0)
//        actionButton.setTitleColor(.white, for: .normal)
//        actionButton.layer.cornerRadius = 10
//        actionButton.addTarget(self, action: #selector(handleAction), for: .touchUpInside)
//
//        // 5. Toggle Button
//        toggleButton.setTitle("Hali hisobingiz yo'qmi? Ro'yxatdan o'ting", for: .normal)
//        toggleButton.addTarget(self, action: #selector(toggleMode), for: .touchUpInside)
//
//        // 🟢 StackView (Tartib uchun)
//        let stackView = UIStackView(arrangedSubviews: [titleLabel, emailTextField, passwordTextField, actionButton, toggleButton])
//        stackView.axis = .vertical
//        stackView.spacing = 20
//        stackView.translatesAutoresizingMaskIntoConstraints = false
//        
//        view.addSubview(stackView)
//
//        NSLayoutConstraint.activate([
//            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
//            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
//            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
//            actionButton.heightAnchor.constraint(equalToConstant: 50)
//        ])
//    }
//
//    @objc private func toggleMode() {
//        isLoginMode.toggle()
//        titleLabel.text = isLoginMode ? "Xush kelibsiz" : "Ro'yxatdan o'tish"
//        actionButton.setTitle(isLoginMode ? "Kirish" : "Ro'yxatdan o'tish", for: .normal)
//        let toggleText = isLoginMode ? "Hali hisobingiz yo'qmi? Ro'yxatdan o'ting" : "Hisobingiz bormi? Kirish"
//        toggleButton.setTitle(toggleText, for: .normal)
//    }
//
//    @objc private func handleAction() {
//        guard let email = emailTextField.text, let password = passwordTextField.text else { return }
//
//        if isLoginMode {
//            // KIRISH
//            Auth.auth().signIn(withEmail: email, password: password) { [weak self] _, error in
//                if let error = error {
//                    print("Xato: \(error.localizedDescription)")
//                } else {
//                    self?.dismiss(animated: true) // Dashboardga qaytish
//                }
//            }
//        } else {
//            // RO'YXATDAN O'TISH
//            Auth.auth().createUser(withEmail: email, password: password) { [weak self] _, error in
//                if let error = error {
//                    print("Xato: \(error.localizedDescription)")
//                } else {
//                    self?.dismiss(animated: true)
//                }
//            }
//        }
//    }
//}

import UIKit
import FirebaseAuth
import GoogleSignIn

final class AuthViewController: UIViewController {

    // MARK: - UI Elementlar

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // Logo / Title
    private let logoImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "dollarsign.circle.fill")
        iv.tintColor = UIColor(red: 91/255, green: 173/255, blue: 198/255, alpha: 1)
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "SmartFinance"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Xush kelibsiz"
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()

    // Email
    private let emailTextField = AuthTextField(placeholder: "Email manzil", keyboardType: .emailAddress)

    // Parol
    private let passwordTextField = AuthTextField(placeholder: "Parol", isSecure: true)
    private let passwordToggleButton = EyeToggleButton()

    // Parolni tasdiqlash (faqat Register rejimida ko'rinadi)
    private let confirmPasswordTextField = AuthTextField(placeholder: "Parolni tasdiqlang", isSecure: true)
    private let confirmPasswordToggleButton = EyeToggleButton()

    // Parol murakkabligi ko'rsatkichi
    private let passwordStrengthLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        label.isHidden = true
        return label
    }()

    // Forgot Password
    private let forgotPasswordButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Parolni unutdingizmi?", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        btn.contentHorizontalAlignment = .right
        return btn
    }()

    // Asosiy tugma
    private let actionButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Kirish", for: .normal)
        btn.backgroundColor = UIColor(red: 91/255, green: 173/255, blue: 198/255, alpha: 1)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        btn.layer.cornerRadius = 14
        return btn
    }()

    // Loading indicator
    private let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .medium)
        ai.color = .white
        ai.hidesWhenStopped = true
        return ai
    }()

    // Toggle (Login <-> Register)
    private let toggleButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Hisobingiz yo'qmi? Ro'yxatdan o'ting", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14)
        return btn
    }()

    // Divider
    private let dividerView = DividerView(text: "yoki")

    // Google Sign-In
    private let googleButton: UIButton = {
        let btn = UIButton(type: .system)
        var config = UIButton.Configuration.bordered()
        config.title = "Google orqali davom etish"
        config.image = UIImage(systemName: "globe")
        config.imagePlacement = .leading
        config.imagePadding = 8
        config.baseBackgroundColor = .systemBackground
        config.baseForegroundColor = .label
        btn.configuration = config
        btn.layer.cornerRadius = 14
        btn.layer.borderWidth = 1
        btn.layer.borderColor = UIColor.systemGray4.cgColor
        return btn
    }()

    // Guest
    private let guestButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Mehmon sifatida kirish", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        btn.setTitleColor(.secondaryLabel, for: .normal)
        return btn
    }()

    // MARK: - State
    private var isLoginMode = true {
        didSet { updateUIForMode(animated: true) }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupScrollView()
        setupLayout()
        setupActions()
        setupKeyboardDismiss()
        updateUIForMode(animated: false)
    }

    // MARK: - Setup

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
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    private func setupLayout() {
        // Eye tugmalarini text fieldlarga o'rnatish
        passwordTextField.rightView = passwordToggleButton
        passwordTextField.rightViewMode = .always

        confirmPasswordTextField.rightView = confirmPasswordToggleButton
        confirmPasswordTextField.rightViewMode = .always

        // Activity indicator-ni actionButton ichiga joylashtiramiz
        actionButton.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.trailingAnchor.constraint(equalTo: actionButton.trailingAnchor, constant: -16),
            activityIndicator.centerYAnchor.constraint(equalTo: actionButton.centerYAnchor)
        ])

        // Logo Stack
        let logoStack = UIStackView(arrangedSubviews: [logoImageView, titleLabel, subtitleLabel])
        logoStack.axis = .vertical
        logoStack.spacing = 8
        logoStack.alignment = .center
        logoImageView.heightAnchor.constraint(equalToConstant: 70).isActive = true
        logoImageView.widthAnchor.constraint(equalToConstant: 70).isActive = true

        // Confirm password + forgot password wrapper
        let confirmWrapper = UIStackView(arrangedSubviews: [confirmPasswordTextField, confirmPasswordToggleButton])
        // Note: confirmPasswordTextField zarur emas bu yerda — allaqachon rightView ga o'rnatildi

        // Forgotten password — faqat login rejimida ko'rinadi
        let forgotWrapper = UIView()
        forgotWrapper.addSubview(forgotPasswordButton)
        forgotPasswordButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            forgotPasswordButton.topAnchor.constraint(equalTo: forgotWrapper.topAnchor),
            forgotPasswordButton.bottomAnchor.constraint(equalTo: forgotWrapper.bottomAnchor),
            forgotPasswordButton.trailingAnchor.constraint(equalTo: forgotWrapper.trailingAnchor),
            forgotWrapper.heightAnchor.constraint(equalToConstant: 20)
        ])

        // Main form stack
        let formStack = UIStackView(arrangedSubviews: [
            emailTextField,
            passwordTextField,
            passwordStrengthLabel,
            confirmPasswordTextField,
            forgotWrapper,
            actionButton,
            toggleButton
        ])
        formStack.axis = .vertical
        formStack.spacing = 14
        formStack.setCustomSpacing(6, after: passwordTextField)   // strength label yakini
        formStack.setCustomSpacing(20, after: toggleButton)

        // Height constraints
        emailTextField.heightAnchor.constraint(equalToConstant: 52).isActive = true
        passwordTextField.heightAnchor.constraint(equalToConstant: 52).isActive = true
        confirmPasswordTextField.heightAnchor.constraint(equalToConstant: 52).isActive = true
        actionButton.heightAnchor.constraint(equalToConstant: 54).isActive = true
        googleButton.heightAnchor.constraint(equalToConstant: 54).isActive = true

        // Social stack
        let socialStack = UIStackView(arrangedSubviews: [dividerView, googleButton, guestButton])
        socialStack.axis = .vertical
        socialStack.spacing = 16

        // Full content stack
        let mainStack = UIStackView(arrangedSubviews: [logoStack, formStack, socialStack])
        mainStack.axis = .vertical
        mainStack.spacing = 28
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -28),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }

    private func setupActions() {
        actionButton.addTarget(self, action: #selector(handleAction), for: .touchUpInside)
        toggleButton.addTarget(self, action: #selector(handleToggle), for: .touchUpInside)
        googleButton.addTarget(self, action: #selector(handleGoogleSignIn), for: .touchUpInside)
        guestButton.addTarget(self, action: #selector(handleGuestSignIn), for: .touchUpInside)
        forgotPasswordButton.addTarget(self, action: #selector(handleForgotPassword), for: .touchUpInside)

        // Eye toggle
        passwordToggleButton.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
        confirmPasswordToggleButton.addTarget(self, action: #selector(toggleConfirmPasswordVisibility), for: .touchUpInside)

        // Parol kuchini real-time tekshirish
        passwordTextField.addTarget(self, action: #selector(passwordDidChange), for: .editingChanged)
    }

    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    // MARK: - Mode Switching

    private func updateUIForMode(animated: Bool) {
        let changes = {
            self.confirmPasswordTextField.isHidden = self.isLoginMode
            self.passwordStrengthLabel.isHidden = self.isLoginMode
            self.forgotPasswordButton.isHidden = !self.isLoginMode

            let title = self.isLoginMode ? "Kirish" : "Ro'yxatdan o'tish"
            self.actionButton.setTitle(title, for: .normal)
            self.subtitleLabel.text = self.isLoginMode ? "Xush kelibsiz" : "Yangi hisob yaratish"

            let toggleText = self.isLoginMode
                ? "Hisobingiz yo'qmi? Ro'yxatdan o'ting"
                : "Allaqachon hisobingiz bormi? Kirish"
            self.toggleButton.setTitle(toggleText, for: .normal)
        }

        if animated {
            UIView.animate(withDuration: 0.3, animations: changes)
        } else {
            changes()
        }
    }

    // MARK: - Yordamchi funksiyalar

    private func setLoading(_ loading: Bool) {
        if loading {
            activityIndicator.startAnimating()
            actionButton.setTitle("", for: .normal)
            actionButton.isEnabled = false
            googleButton.isEnabled = false
            guestButton.isEnabled = false
        } else {
            activityIndicator.stopAnimating()
            let title = isLoginMode ? "Kirish" : "Ro'yxatdan o'tish"
            actionButton.setTitle(title, for: .normal)
            actionButton.isEnabled = true
            googleButton.isEnabled = true
            guestButton.isEnabled = true
        }
    }

    private func showAlert(title: String, message: String, isSuccess: Bool = false, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let icon = isSuccess ? "✅" : "❌"
        alert.title = "\(icon) \(title)"
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completion?() })
        present(alert, animated: true)
    }

    private func navigateToMainApp() {
        // NotificationCenter orqali SceneDelegate ga xabar yuboramiz
        // Bu usul windowScene.delegate cast xatolarini oldini oladi
        NotificationCenter.default.post(name: .switchToMainApp, object: nil)
    }

    // MARK: - Actions

    @objc private func handleToggle() {
        isLoginMode.toggle()
        // Fiellarni tozalash
        passwordTextField.text = ""
        confirmPasswordTextField.text = ""
        passwordStrengthLabel.isHidden = true
    }

    @objc private func togglePasswordVisibility() {
        passwordTextField.isSecureTextEntry.toggle()
        let imageName = passwordTextField.isSecureTextEntry ? "eye" : "eye.slash"
        passwordToggleButton.setImage(UIImage(systemName: imageName), for: .normal)
    }

    @objc private func toggleConfirmPasswordVisibility() {
        confirmPasswordTextField.isSecureTextEntry.toggle()
        let imageName = confirmPasswordTextField.isSecureTextEntry ? "eye" : "eye.slash"
        confirmPasswordToggleButton.setImage(UIImage(systemName: imageName), for: .normal)
    }

    @objc private func passwordDidChange() {
        guard !isLoginMode, let text = passwordTextField.text, !text.isEmpty else {
            passwordStrengthLabel.isHidden = true
            return
        }
        passwordStrengthLabel.isHidden = false
        let (strength, color) = passwordStrength(text)
        passwordStrengthLabel.text = "Parol kuchi: \(strength)"
        passwordStrengthLabel.textColor = color
    }

    private func passwordStrength(_ password: String) -> (String, UIColor) {
        var score = 0
        if password.count >= 8 { score += 1 }
        if password.range(of: "[A-Z]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[0-9]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil { score += 1 }

        switch score {
        case 0...1: return ("Juda kuchsiz 🔴", .systemRed)
        case 2:     return ("O'rta 🟡", .systemOrange)
        case 3:     return ("Yaxshi 🟢", .systemGreen)
        default:    return ("A'lo 💪", .systemBlue)
        }
    }

    @objc private func handleAction() {
        guard let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              let password = passwordTextField.text,
              !email.isEmpty, !password.isEmpty else {
            showAlert(title: "Xato", message: "Email va parolni to'liq kiriting.")
            return
        }

        setLoading(true)

        if isLoginMode {
            // --- Kirish ---
            AuthManager.shared.signIn(email: email, password: password) { [weak self] result in
                DispatchQueue.main.async {
                    self?.setLoading(false)
                    switch result {
                    case .success:
                        self?.navigateToMainApp()
                    case .failure(let error):
                        self?.showAlert(title: "Kirish xatosi", message: error.localizedDescription)
                    }
                }
            }
        } else {
            // --- Ro'yxatdan o'tish ---
            let confirmPassword = confirmPasswordTextField.text ?? ""
            AuthManager.shared.signUp(email: email, password: password, confirmPassword: confirmPassword) { [weak self] result in
                DispatchQueue.main.async {
                    self?.setLoading(false)
                    switch result {
                    case .success:
                        self?.showAlert(title: "Muvaffaqiyat", message: "Hisob muvaffaqiyatli yaratildi!", isSuccess: true) {
                            self?.navigateToMainApp()
                        }
                    case .failure(let error):
                        self?.showAlert(title: "Ro'yxatdan o'tish xatosi", message: error.localizedDescription)
                    }
                }
            }
        }
    }

    @objc private func handleForgotPassword() {
        // Email kiritish uchun alert
        let alert = UIAlertController(
            title: "Parolni tiklash",
            message: "Email manzilingizni kiriting. Tiklash havolasi yuboriladi.",
            preferredStyle: .alert
        )
        alert.addTextField { tf in
            tf.placeholder = "Email manzilingiz"
            tf.keyboardType = .emailAddress
            tf.autocapitalizationType = .none
            tf.text = self.emailTextField.text // Agar email kiritilgan bo'lsa
        }
        alert.addAction(UIAlertAction(title: "Bekor qilish", style: .cancel))
        alert.addAction(UIAlertAction(title: "Yuborish", style: .default) { [weak self] _ in
            guard let email = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !email.isEmpty else {
                self?.showAlert(title: "Xato", message: "Email manzil kiritilmadi.")
                return
            }
            AuthManager.shared.resetPassword(email: email) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self?.showAlert(
                            title: "Yuborildi",
                            message: "\(email) manziliga parolni tiklash havolasi yuborildi. Spam papkasini ham tekshiring.",
                            isSuccess: true
                        )
                    case .failure(let error):
                        self?.showAlert(title: "Xato", message: error.localizedDescription)
                    }
                }
            }
        })
        present(alert, animated: true)
    }

    @objc private func handleGoogleSignIn() {
        setLoading(true)
        AuthManager.shared.signInWithGoogle(presentingVC: self) { [weak self] result in
            DispatchQueue.main.async {
                self?.setLoading(false)
                switch result {
                case .success(let user):
                    let isLinked = user.providerData.count > 1
                    if isLinked {
                        self?.showAlert(title: "Muvaffaqiyat", message: "Mehmon hisobingiz Google bilan bog'landi!", isSuccess: true) {
                            self?.navigateToMainApp()
                        }
                    } else {
                        self?.navigateToMainApp()
                    }
                case .failure(let error):
                    self?.showAlert(title: "Google Sign-In xatosi", message: error.localizedDescription)
                }
            }
        }
    }

    @objc private func handleGuestSignIn() {
        setLoading(true)
        AuthManager.shared.signInAnonymously { [weak self] result in
            DispatchQueue.main.async {
                self?.setLoading(false)
                switch result {
                case .success:
                    self?.navigateToMainApp()
                case .failure(let error):
                    self?.showAlert(title: "Mehmon kirish xatosi", message: error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - Yordamchi UI komponentlar

/// Standart text field (styling markazlashtirilgan)
final class AuthTextField: UITextField {
    init(placeholder: String, keyboardType: UIKeyboardType = .default, isSecure: Bool = false) {
        super.init(frame: .zero)
        self.placeholder = placeholder
        self.keyboardType = keyboardType
        self.isSecureTextEntry = isSecure
        self.autocapitalizationType = .none
        self.autocorrectionType = .no
        self.borderStyle = .none
        self.layer.cornerRadius = 12
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.systemGray4.cgColor
        self.backgroundColor = .secondarySystemBackground
        // Padding
        self.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        self.leftViewMode = .always
        self.font = .systemFont(ofSize: 16)
    }
    required init?(coder: NSCoder) { fatalError() }
}

/// Ko'z tugmasi (password visibility)
final class EyeToggleButton: UIButton {
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        setImage(UIImage(systemName: "eye"), for: .normal)
        tintColor = .systemGray
    }
    required init?(coder: NSCoder) { fatalError() }
}

/// "yoki" ajratuvchi chiziq
final class DividerView: UIView {
    init(text: String) {
        super.init(frame: .zero)
        let leftLine = UIView(); leftLine.backgroundColor = .systemGray4
        let rightLine = UIView(); rightLine.backgroundColor = .systemGray4
        let label = UILabel()
        label.text = text
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 13)

        [leftLine, label, rightLine].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        NSLayoutConstraint.activate([
            leftLine.leadingAnchor.constraint(equalTo: leadingAnchor),
            leftLine.centerYAnchor.constraint(equalTo: centerYAnchor),
            leftLine.heightAnchor.constraint(equalToConstant: 1),

            label.leadingAnchor.constraint(equalTo: leftLine.trailingAnchor, constant: 12),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),

            rightLine.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 12),
            rightLine.trailingAnchor.constraint(equalTo: trailingAnchor),
            rightLine.centerYAnchor.constraint(equalTo: centerYAnchor),
            rightLine.heightAnchor.constraint(equalToConstant: 1),
            leftLine.widthAnchor.constraint(equalTo: rightLine.widthAnchor)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
}

// MARK: - Notification Names (AuthViewController va SceneDelegate o'rtasidagi aloqa)
extension Notification.Name {
    static let switchToMainApp = Notification.Name("switchToMainApp")
    static let switchToAuth    = Notification.Name("switchToAuth")
}
