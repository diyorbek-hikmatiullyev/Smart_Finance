//
//  ProfilViewController.swift
//  SmartFinance
//
//  Created by Diyorbek Xikmatullayev on 30/03/26.
//

//
//  ProfilViewController.swift
//  SmartFinance
//
//  Muallif: Diyorbek Xikmatullayev
//
import UIKit
import FirebaseAuth

// MARK: - ProfilViewController

class ProfilViewController: UIViewController {

    private let profileViewModel = ProfileViewModel()

    // MARK: - Properties

    var transactions: [Transaction] = []
    private let aiCard = UIView()

    // MARK: - UI Elements

    private let profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "person.circle.fill")
        iv.tintColor = UIColor(red: 91/255, green: 173/255, blue: 198/255, alpha: 1)
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 60
        iv.clipsToBounds = true
        iv.isUserInteractionEnabled = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let editPhotoButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Rasmni o'zgartirish", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        btn.tintColor = UIColor(red: 91/255, green: 173/255, blue: 198/255, alpha: 1)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let infoCard = UIView()
    private let nameRow  = ProfileInfoRow(icon: "person.fill",           label: "Ism")
    private let emailRow = ProfileInfoRow(icon: "envelope.fill",         label: "Email")
    private let uidRow   = ProfileInfoRow(icon: "person.badge.key.fill", label: "User ID")
    private let typeRow  = ProfileInfoRow(icon: "shield.fill",           label: "Hisob turi")

    private let logoutButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Chiqish (Logout)", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        btn.backgroundColor = .systemRed
        btn.layer.cornerRadius = 14
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Profil"
        setupUI()
        setupActions()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        populateUserInfo()
        loadTransactions()
    }

    // MARK: - Setup UI

    private func setupUI() {
        infoCard.backgroundColor = .secondarySystemBackground
        infoCard.layer.cornerRadius = 16
        infoCard.translatesAutoresizingMaskIntoConstraints = false

        let divider1 = makeDivider()
        let divider2 = makeDivider()

        [nameRow, divider1, emailRow, divider2, uidRow].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            infoCard.addSubview($0)
        }

        view.addSubview(profileImageView)
        view.addSubview(editPhotoButton)
        view.addSubview(infoCard)
        view.addSubview(typeRow)
        view.addSubview(logoutButton)
        typeRow.translatesAutoresizingMaskIntoConstraints = false

        setupAICard()

        NSLayoutConstraint.activate([
            // Profil rasm
            profileImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 28),
            profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 120),
            profileImageView.heightAnchor.constraint(equalToConstant: 120),

            // Rasm o'zgartirish
            editPhotoButton.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 10),
            editPhotoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // Info karta
            infoCard.topAnchor.constraint(equalTo: editPhotoButton.bottomAnchor, constant: 28),
            infoCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            infoCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            nameRow.topAnchor.constraint(equalTo: infoCard.topAnchor),
            nameRow.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor),
            nameRow.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor),
            nameRow.heightAnchor.constraint(equalToConstant: 56),

            divider1.topAnchor.constraint(equalTo: nameRow.bottomAnchor),
            divider1.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 16),
            divider1.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor),
            divider1.heightAnchor.constraint(equalToConstant: 1),

            emailRow.topAnchor.constraint(equalTo: divider1.bottomAnchor),
            emailRow.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor),
            emailRow.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor),
            emailRow.heightAnchor.constraint(equalToConstant: 56),

            divider2.topAnchor.constraint(equalTo: emailRow.bottomAnchor),
            divider2.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 16),
            divider2.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor),
            divider2.heightAnchor.constraint(equalToConstant: 1),

            uidRow.topAnchor.constraint(equalTo: divider2.bottomAnchor),
            uidRow.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor),
            uidRow.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor),
            uidRow.heightAnchor.constraint(equalToConstant: 56),
            uidRow.bottomAnchor.constraint(equalTo: infoCard.bottomAnchor),

            // Hisob turi
            typeRow.topAnchor.constraint(equalTo: infoCard.bottomAnchor, constant: 12),
            typeRow.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            typeRow.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            typeRow.heightAnchor.constraint(equalToConstant: 44),

            // AI Card
            aiCard.topAnchor.constraint(equalTo: typeRow.bottomAnchor, constant: 20),
            aiCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            aiCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            aiCard.heightAnchor.constraint(equalToConstant: 88),

            // Logout
            logoutButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            logoutButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            logoutButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            logoutButton.heightAnchor.constraint(equalToConstant: 54),
        ])
    }

    private func setupActions() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profileImageTapped))
        profileImageView.addGestureRecognizer(tapGesture)
        editPhotoButton.addTarget(self, action: #selector(profileImageTapped), for: .touchUpInside)
        logoutButton.addTarget(self, action: #selector(handleLogout), for: .touchUpInside)

        let tap = UITapGestureRecognizer(target: self, action: #selector(aiCardTapped))
        aiCard.addGestureRecognizer(tap)
        aiCard.isUserInteractionEnabled = true
    }

    // MARK: - AI Card

    private func setupAICard() {
        let accentColor = UIColor(red: 91/255, green: 173/255, blue: 198/255, alpha: 1)

        aiCard.backgroundColor = accentColor.withAlphaComponent(0.12)
        aiCard.layer.cornerRadius = 18
        aiCard.layer.borderWidth  = 1
        aiCard.layer.borderColor  = accentColor.withAlphaComponent(0.25).cgColor
        aiCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(aiCard)

        // Sol: brain icon badge
        let badgeView = UIView()
        badgeView.backgroundColor = accentColor.withAlphaComponent(0.18)
        badgeView.layer.cornerRadius = 22
        badgeView.translatesAutoresizingMaskIntoConstraints = false

        let iconConf = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        let iconView = UIImageView()
        iconView.image = UIImage(systemName: "brain.head.profile", withConfiguration: iconConf)
        iconView.tintColor = accentColor
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        badgeView.addSubview(iconView)

        // Matnlar
        let titleLbl = UILabel()
        titleLbl.text = "AI Moliyaviy Maslahatchi"
        titleLbl.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLbl.textColor = .label
        titleLbl.translatesAutoresizingMaskIntoConstraints = false

        let subtitleLbl = UILabel()
        subtitleLbl.text = "Xarajatlaringizni tahlil qilib beraman"
        subtitleLbl.font = .systemFont(ofSize: 12, weight: .regular)
        subtitleLbl.textColor = .secondaryLabel
        subtitleLbl.translatesAutoresizingMaskIntoConstraints = false

        // O'q
        let arrowConf = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        let arrowView = UIImageView()
        arrowView.image = UIImage(systemName: "chevron.right", withConfiguration: arrowConf)
        arrowView.tintColor = accentColor
        arrowView.translatesAutoresizingMaskIntoConstraints = false

        // "AI" badge
        let newBadge = UILabel()
        newBadge.text = "AI"
        newBadge.font = .systemFont(ofSize: 10, weight: .bold)
        newBadge.textColor = .white
        newBadge.backgroundColor = accentColor
        newBadge.layer.cornerRadius = 8
        newBadge.clipsToBounds = true
        newBadge.textAlignment = .center
        newBadge.translatesAutoresizingMaskIntoConstraints = false

        [badgeView, titleLbl, subtitleLbl, arrowView, newBadge].forEach { aiCard.addSubview($0) }

        NSLayoutConstraint.activate([
            badgeView.leadingAnchor.constraint(equalTo: aiCard.leadingAnchor, constant: 16),
            badgeView.centerYAnchor.constraint(equalTo: aiCard.centerYAnchor),
            badgeView.widthAnchor.constraint(equalToConstant: 44),
            badgeView.heightAnchor.constraint(equalToConstant: 44),

            iconView.centerXAnchor.constraint(equalTo: badgeView.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: badgeView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),

            titleLbl.leadingAnchor.constraint(equalTo: badgeView.trailingAnchor, constant: 12),
            titleLbl.topAnchor.constraint(equalTo: aiCard.topAnchor, constant: 22),

            subtitleLbl.leadingAnchor.constraint(equalTo: titleLbl.leadingAnchor),
            subtitleLbl.topAnchor.constraint(equalTo: titleLbl.bottomAnchor, constant: 3),

            arrowView.centerYAnchor.constraint(equalTo: aiCard.centerYAnchor),
            arrowView.trailingAnchor.constraint(equalTo: aiCard.trailingAnchor, constant: -16),

            newBadge.bottomAnchor.constraint(equalTo: badgeView.topAnchor, constant: 10),
            newBadge.trailingAnchor.constraint(equalTo: badgeView.trailingAnchor, constant: 6),
            newBadge.widthAnchor.constraint(equalToConstant: 22),
            newBadge.heightAnchor.constraint(equalToConstant: 16),
        ])

        // Press animatsiyasi
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(aiCardPressed(_:)))
        longPress.minimumPressDuration = 0
        aiCard.addGestureRecognizer(longPress)
    }

    @objc private func aiCardPressed(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            UIView.animate(withDuration: 0.12) {
                self.aiCard.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
                self.aiCard.alpha = 0.82
            }
        case .ended, .cancelled:
            UIView.animate(
                withDuration: 0.22,
                delay: 0,
                usingSpringWithDamping: 0.65,
                initialSpringVelocity: 0.5,
                animations: {
                    self.aiCard.transform = .identity
                    self.aiCard.alpha = 1
                }
            )
            if gesture.state == .ended { openAIAdvisor() }
        default:
            break
        }
    }

    @objc private func aiCardTapped() {
        openAIAdvisor()
    }

    private func openAIAdvisor() {
        let vc = AIAdvisorViewController()
        vc.transactions = transactions
        vc.periodLabel  = "joriy oy"
        vc.modalPresentationStyle = .pageSheet
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
        present(vc, animated: true)
    }

    // MARK: - Load Transactions

    private func loadTransactions() {
        transactions = profileViewModel.loadTransactions()
    }

    // MARK: - User Info

    private func populateUserInfo() {
        guard let user = Auth.auth().currentUser else { return }

        nameRow.setValue(user.displayName ?? "—")
        emailRow.setValue(user.email ?? "—")
        uidRow.setValue(String(user.uid.prefix(12)) + "...")

        if user.isAnonymous {
            typeRow.setValue("Mehmon (Anonim)")
            typeRow.setValueColor(.systemOrange)
        } else {
            let providers = user.providerData.map { $0.providerID }
            if providers.contains("google.com") {
                typeRow.setValue("Google hisob")
                typeRow.setValueColor(.systemBlue)
            } else {
                typeRow.setValue("Email/Parol")
                typeRow.setValueColor(.systemGreen)
            }
        }
    }

    // MARK: - Logout

    @objc private func handleLogout() {
        let alert = UIAlertController(
            title: "Chiqish",
            message: "Hisobdan chiqmoqchimisiz?",
            preferredStyle: .actionSheet
        )
        alert.addAction(UIAlertAction(title: "Chiqish", style: .destructive) { [weak self] _ in
            self?.performLogout()
        })
        alert.addAction(UIAlertAction(title: "Bekor qilish", style: .cancel))
        if let popover = alert.popoverPresentationController {
            popover.sourceView = logoutButton
            popover.sourceRect = logoutButton.bounds
        }
        present(alert, animated: true)
    }

    private func performLogout() {
        profileViewModel.clearLocalDataForCurrentUser()
        AuthManager.shared.signOut { [weak self] success in
            guard success else { self?.showErrorAlert(); return }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name("switchToAuth"), object: nil)
            }
        }
    }

    private func showErrorAlert() {
        let alert = UIAlertController(title: "Xato", message: "Chiqishda xatolik yuz berdi.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Photo

    @objc private func profileImageTapped() {
        let picker = UIImagePickerController()
        picker.delegate    = self
        picker.allowsEditing = true
        picker.sourceType  = .photoLibrary
        present(picker, animated: true)
    }

    // MARK: - Helper

    private func makeDivider() -> UIView {
        let v = UIView()
        v.backgroundColor = .separator
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }
}

// MARK: - UIImagePickerControllerDelegate

extension ProfilViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[.editedImage] as? UIImage {
            profileImageView.image = image
            ProfileImageStorage.uploadProfileImage(image: image) { result in
                switch result {
                case .success(let url):   print("✅ Profil rasm URL: \(url)")
                case .failure(let error): print("❌ Rasm yuklash xatosi: \(error.localizedDescription)")
                }
            }
        }
        picker.dismiss(animated: true)
    }
}

// MARK: - ProfileInfoRow

final class ProfileInfoRow: UIView {

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.tintColor = UIColor(red: 91/255, green: 173/255, blue: 198/255, alpha: 1)
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let labelView: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let valueLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .medium)
        l.textColor = .label
        l.textAlignment = .right
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.8
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    init(icon: String, label: String) {
        super.init(frame: .zero)
        iconView.image = UIImage(systemName: icon)
        labelView.text = label
        addSubview(iconView)
        addSubview(labelView)
        addSubview(valueLabel)
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),

            labelView.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            labelView.centerYAnchor.constraint(equalTo: centerYAnchor),

            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            valueLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            valueLabel.leadingAnchor.constraint(equalTo: labelView.trailingAnchor, constant: 8),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func setValue(_ text: String) { valueLabel.text = text }
    func setValueColor(_ color: UIColor) { valueLabel.textColor = color }
}
