
import UIKit
import FirebaseFirestore
import FirebaseAuth
import CoreData

class AddTransactionViewController: UIViewController {

    let titleField = UITextField()
    let amountField = UITextField()
    let typeSegment = UISegmentedControl(items: ["Kirim", "Chiqim"])
    let categoryButton = UIButton(type: .system)
    let saveButton = UIButton(type: .system)
    
    let expenseCategories = ["Oziq-ovqat", "Transport", "Ijara", "Kiyim-kechak", "O'yin-kulgi", "Salomatlik", "Boshqa..."]
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
        // ✅ Ikkinchi ekranda barni ko'rsatamiz (O'zi standart Back tugma chiqaradi)
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
        for category in expenseCategories {
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
    
//    @objc private func saveTapped() {
//        guard let titleText = titleField.text, !titleText.isEmpty,
//              let amountText = amountField.text, !amountText.isEmpty else {
//            print("❌ Sarlavha yoki summa kiritilmagan!")
//            return
//        }
//        
//        // 🧹 Tozalash (probel va vergullarni to'g'rilash)
//        let cleanedAmountText = amountText.replacingOccurrences(of: " ", with: "")
//                                          .replacingOccurrences(of: ",", with: ".")
//        
//        guard let amount = Double(cleanedAmountText) else {
//            print("❌ Summani raqamga o'girib bo'lmadi: \(amountText)")
//            return
//        }
//        
//        let isIncome = (typeSegment.selectedSegmentIndex == 0)
//        let context = CoreDataStack.shared.context
//        let transaction = Transaction(context: context)
//        
//        let transactionId = UUID()
//        transaction.id = transactionId
//        transaction.title = titleText
//        transaction.amount = amount
//        transaction.date = Date()
//        transaction.type = isIncome ? "Income" : "Expense"
//        
//        let finalCategory = isIncome ? "Kirim" : ((selectedCategory == "Boshqa...") ? titleText : selectedCategory)
//        transaction.category = finalCategory
//        
//        // 1. Core Data-ga saqlash (Telefon xotirasi)
//        CoreDataStack.shared.saveContext()
//        
//        // 2. Firebase Firestore-ga yozish (Bulutli xotira)
//        let db = Firestore.firestore()
//        
//        guard let currentUserID = Auth.auth().currentUser?.uid else {
//            print("Xato: Foydalanuvchi tizimga kirmagan!")
//            return
//        }
//
//        let transactionData: [String: Any] = [
//            "userID": currentUserID,   // 👈 MANA SHU JUDA MUHIM! Har bir xarid egasini tanishi kerak.
//            "id": transactionId.uuidString,
//            "title": titleText,
//            "amount": amount,
//            "category": finalCategory,
//            "date": Timestamp(date: Date()),
//            "type": isIncome ? "Income" : "Expense"
//        ]
//
//        // Endi "transactions" kolleksiyasiga qo'shamiz
//        db.collection("transactions").addDocument(data: transactionData) { error in
//            if let error = error {
//                print("❌ Firebase-ga yozishda xato: \(error.localizedDescription)")
//            } else {
//                print("✅ Ma'lumot foydalanuvchi ID-si (\(currentUserID)) bilan bulutga uchdi!")
//            }
//        }
//        
//        // ✅ Ekranidan orqaga qaytish
//        navigationController?.popViewController(animated: true)
//    }
    
    @objc private func saveTapped() {
        // 1. Ma'lumotlarni tekshirish
        guard let titleText = titleField.text, !titleText.isEmpty,
              let amountText = amountField.text, !amountText.isEmpty else { return }
        
        let cleanedAmount = amountText.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(cleanedAmount) else { return }
        
        let isIncome = (typeSegment.selectedSegmentIndex == 0)
        let currentUserID = Auth.auth().currentUser?.uid ?? ""
        let db = Firestore.firestore()
        
        // 2. Firebase ID-ni internet bo'lmasa ham oldindan yaratib olamiz
        let newDocRef = db.collection("transactions").document()
        let firebaseID = newDocRef.documentID
        let finalCategory = isIncome ? "Kirim" : ((selectedCategory == "Boshqa...") ? titleText : selectedCategory)

        // ------------------------------------------------------
        // 🔥 ENG MUHIM O'ZGARISH SHU YERDA:
        // ------------------------------------------------------
        
        // 3. DARXOL Core Data-ga saqlaymiz (Firebase-ni kutmasdan!)
        let context = CoreDataStack.shared.context
        let transaction = Transaction(context: context)
        
        transaction.documentID = firebaseID
        transaction.id = UUID()
        transaction.title = titleText
        transaction.amount = amount
        transaction.date = Date()
        transaction.type = isIncome ? "Income" : "Expense"
        transaction.category = finalCategory
        transaction.userID = currentUserID
        
        CoreDataStack.shared.saveContext()
        
        // 4. EKRAVNI DARXOL YOPAMIZ (Foydalanuvchi kutib qolmasligi uchun)
        self.navigationController?.popViewController(animated: true)

        // 5. FIREBASE-ga yozishni fonda bajaramiz
        let transactionData: [String: Any] = [
            "userID": currentUserID,
            "documentID": firebaseID,
            "id": transaction.id?.uuidString ?? UUID().uuidString,
            "title": titleText,
            "amount": amount,
            "category": finalCategory,
            "date": Timestamp(date: Date()),
            "type": isIncome ? "Income" : "Expense"
            
        ]

        // setData funksiyasi internet bo'lmasa ham "local cache"ga yozadi
        // va internet kelishi bilan avtomat bulutga yuboradi
        newDocRef.setData(transactionData) { error in
            if let error = error {
                print("☁️ Firebase background sync xatosi: \(error.localizedDescription)")
            } else {
                print("✅ Bulut bilan muvaffaqiyatli sinxronlandi!")
            }
        }
    }
    
}
