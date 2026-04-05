
//import Foundation
//import UIKit
//import CoreData
//import FirebaseFirestore
//
//extension DashboardViewController: UITableViewDelegate, UITableViewDataSource {
//    
//    // MARK: - UITableViewDataSource (Majburiy metodlar)
//    
//    func numberOfSections(in tableView: UITableView) -> Int {
//        return groupedTransactions.count
//    }
//
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return groupedTransactions[section].transactions.count
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        
//        // 1. "cell" identifikatori bilan xotirada bo'sh cell bormi ko'ramiz
//        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
//        
//        // 2. Agar bo'sh bo'lsa yoki pastki yozuvi (detailTextLabel) bo'lmasa, yangidan yaratamiz
//        // MUHIM: style: .subtitle bo'lishi shart!
//        if cell == nil || cell?.detailTextLabel == nil {
//            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
//        }
//        
//        let transaction = groupedTransactions[indexPath.section].transactions[indexPath.row]
//        
//        // Asosiy matn (Nomi)
//        cell?.textLabel?.text = transaction.title ?? "Nomsiz"
//        cell?.textLabel?.font = .systemFont(ofSize: 16, weight: .medium)
//        
//        // Pastki matn (Summa va Kirim/Chiqim belgisi)
//        let sign = transaction.type == "Income" ? "+" : "-"
//        cell?.detailTextLabel?.text = "\(sign)\(Int(transaction.amount)) so'm"
//        cell?.detailTextLabel?.font = .systemFont(ofSize: 14, weight: .regular)
//        
//        // Rangi: Income (Kirim) bo'lsa yashil, bo'lmasa qizil
//        if transaction.type == "Income" {
//            cell?.detailTextLabel?.textColor = .systemGreen
//        } else {
//            cell?.detailTextLabel?.textColor = .systemRed
//        }
//        
//        return cell ?? UITableViewCell()
//    }
//    
//    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        return groupedTransactions[section].date
//    }
//    
//    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
//        if let header = view as? UITableViewHeaderFooterView {
//            header.textLabel?.font = .systemFont(ofSize: 14, weight: .bold)
//            header.textLabel?.textColor = .secondaryLabel
//        }
//    }
//
//    // MARK: - Swipe Actions (Delete & Edit)
//
//    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
//        
//        // 🗑 O'chirish
//        let deleteAction = UIContextualAction(style: .destructive, title: "O'chirish") { [weak self] (_, _, completionHandler) in
//            let transaction = self?.groupedTransactions[indexPath.section].transactions[indexPath.row]
//            
//            if let transaction = transaction {
//                // 1. Firebase dan o'chirish
//                if let docID = transaction.documentID {
//                    Firestore.firestore().collection("transactions").document(docID).delete { error in
//                        if let error = error { print("❌ Firebase delete error: \(error.localizedDescription)") }
//                    }
//                }
//                
//                // 2. Core Data dan o'chirish
//                CoreDataStack.shared.context.delete(transaction)
//                CoreDataStack.shared.saveContext()
//                
//                // 3. UI ni yangilash
//                self?.fetchTransactions()
//            }
//            completionHandler(true)
//        }
//        deleteAction.image = UIImage(systemName: "trash.fill")
//        
//        // ✏️ Tahrirlash
//        let editAction = UIContextualAction(style: .normal, title: "Tahrirlash") { [weak self] (_, _, completionHandler) in
//            self?.editTransaction(at: indexPath)
//            completionHandler(true)
//        }
//        editAction.image = UIImage(systemName: "pencil")
//        editAction.backgroundColor = .systemOrange
//        
//        let config = UISwipeActionsConfiguration(actions: [deleteAction, editAction])
//        config.performsFirstActionWithFullSwipe = false
//        return config
//    }
//
//    // MARK: - Tahrirlash mantiqi (Alert Controller bilan)
//    
//    private func editTransaction(at indexPath: IndexPath) {
//        let transaction = groupedTransactions[indexPath.section].transactions[indexPath.row]
//        let alert = UIAlertController(title: "Tahrirlash", message: "Yangi ma'lumotlarni kiriting", preferredStyle: .alert)
//        
//        alert.addTextField { $0.text = transaction.title; $0.placeholder = "Nomi" }
//        alert.addTextField { $0.text = "\(Int(transaction.amount))"; $0.placeholder = "Miqdori"; $0.keyboardType = .decimalPad }
//        
//        let saveAction = UIAlertAction(title: "Saqlash", style: .default) { [weak self] _ in
//            guard let titleText = alert.textFields?[0].text, !titleText.isEmpty,
//                  let amountText = alert.textFields?[1].text, let amount = Double(amountText) else { return }
//            
//            // 1. Firebase da yangilash
//            if let docID = transaction.documentID {
//                let updateData: [String: Any] = [
//                    "title": titleText,
//                    "amount": amount
//                ]
//                Firestore.firestore().collection("transactions").document(docID).updateData(updateData) { error in
//                    if let error = error { print("❌ Firebase update error: \(error.localizedDescription)") }
//                }
//            }
//            
//            // 2. Core Data da yangilash
//            transaction.title = titleText
//            transaction.amount = amount
//            CoreDataStack.shared.saveContext()
//            
//            // 3. UI ni yangilash
//            self?.fetchTransactions()
//        }
//        
//        alert.addAction(saveAction)
//        alert.addAction(UIAlertAction(title: "Bekor qilish", style: .cancel))
//        present(alert, animated: true)
//    }
//}


import UIKit

extension DashboardViewController: UITableViewDelegate, UITableViewDataSource {

    // MARK: - DataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        groupedTransactions.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        groupedTransactions[section].transactions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil || cell?.detailTextLabel == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        }

        let transaction = groupedTransactions[indexPath.section].transactions[indexPath.row]
        let baseFont    = UIFont.systemFont(ofSize: 16, weight: .medium)
        let title       = transaction.title ?? "Nomsiz"

        // Agar qidiruv faol bo'lsa — Highlight, aks holda oddiy matn
        if !currentSearchQuery.isEmpty {
            let highlightColor = UIColor(red: 91/255, green: 173/255, blue: 198/255, alpha: 1)
            cell?.textLabel?.attributedText = SmartSearchEngine.highlight(
                text: title, query: currentSearchQuery,
                font: baseFont, color: highlightColor
            )
        } else {
            cell?.textLabel?.attributedText = nil
            cell?.textLabel?.text = title
            cell?.textLabel?.font = baseFont
        }

        // Summa
        let sign = transaction.type == "Income" ? "+" : "-"
        cell?.detailTextLabel?.text  = "\(sign)\(Int(transaction.amount)) so'm"
        cell?.detailTextLabel?.font  = .systemFont(ofSize: 14, weight: .regular)
        cell?.detailTextLabel?.textColor = transaction.type == "Income" ? .systemGreen : .systemRed

        // Kategoriya icon (accessory)
        let categoryIcons: [String: String] = [
            "transport": "car.fill", "oziq-ovqat": "fork.knife",
            "kiyim-kechak": "tshirt.fill", "salomatlik": "heart.fill",
            "ijara": "house.fill", "o'yin-kulgi": "gamecontroller.fill"
        ]
        let cat = transaction.category?.lowercased() ?? ""
        if let iconName = categoryIcons.first(where: { cat.contains($0.key) })?.value {
            let iconConf = UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)
            let iconView = UIImageView(image: UIImage(systemName: iconName, withConfiguration: iconConf))
            iconView.tintColor = .tertiaryLabel
            iconView.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
            iconView.contentMode = .scaleAspectFit
            cell?.accessoryView = iconView
        } else {
            cell?.accessoryView = nil
            cell?.accessoryType = .none
        }

        return cell ?? UITableViewCell()
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        groupedTransactions[section].date
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.font      = .systemFont(ofSize: 13, weight: .bold)
            header.textLabel?.textColor = .secondaryLabel
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        54
    }

    // MARK: - Swipe Actions

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

        // O'chirish
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] _, _, done in
            guard let self else { done(false); return }
            self.viewModel.deleteTransaction(at: indexPath)
            done(true)
        }
        deleteAction.image           = UIImage(systemName: "trash.fill")
        deleteAction.backgroundColor = .systemRed

        // Tahrirlash
        let editAction = UIContextualAction(style: .normal, title: nil) { [weak self] _, _, done in
            self?.editTransaction(at: indexPath)
            done(true)
        }
        editAction.image           = UIImage(systemName: "pencil")
        editAction.backgroundColor = .systemOrange

        let config = UISwipeActionsConfiguration(actions: [deleteAction, editAction])
        config.performsFirstActionWithFullSwipe = false
        return config
    }

    // MARK: - Tahrirlash

    private func editTransaction(at indexPath: IndexPath) {
        let transaction = groupedTransactions[indexPath.section].transactions[indexPath.row]
        let alert = UIAlertController(title: "Tahrirlash", message: "Yangi ma'lumotlarni kiriting",
                                      preferredStyle: .alert)
        alert.addTextField { $0.text = transaction.title; $0.placeholder = "Nomi" }
        alert.addTextField { $0.text = "\(Int(transaction.amount))"; $0.placeholder = "Miqdori"; $0.keyboardType = .decimalPad }

        let save = UIAlertAction(title: "Saqlash", style: .default) { [weak self] _ in
            guard let self,
                  let titleText = alert.textFields?[0].text, !titleText.isEmpty,
                  let amountText = alert.textFields?[1].text,
                  let amount = Double(amountText) else { return }
            self.viewModel.updateTransaction(at: indexPath, title: titleText, amount: amount)
        }

        alert.addAction(save)
        alert.addAction(UIAlertAction(title: "Bekor qilish", style: .cancel))
        present(alert, animated: true)
    }
}
