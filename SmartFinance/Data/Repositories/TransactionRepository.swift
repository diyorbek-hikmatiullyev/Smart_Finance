//
//  TransactionRepository.swift
//  SmartFinance
//

import CoreData
import FirebaseFirestore

struct NewTransactionInput {
    let title: String
    let amount: Double
    let isIncome: Bool
    let category: String
    let userID: String
}

protocol TransactionRepositoryProtocol: AnyObject {
    func fetchTransactions(forUserID uid: String) throws -> [Transaction]
    func startRemoteSync(userID: String, onChange: @escaping () -> Void)
    func stopRemoteSync()
    func deleteLocalAndRemote(_ transaction: Transaction)
    func updateTitleAndAmount(documentID: String?, title: String, amount: Double, local: Transaction)
    func createTransaction(_ input: NewTransactionInput, completion: @escaping (Error?) -> Void)
    func deleteAllLocalTransactions(forUserID uid: String)
}

/// Tranzaksiyalar: Core Data (mahalliy) + Firestore (sinxron) — bitta joyda.
final class TransactionRepository: TransactionRepositoryProtocol {

    static let shared = TransactionRepository()

    private let coreData: CoreDataStack
    private let db: Firestore
    private var listener: ListenerRegistration?

    init(coreData: CoreDataStack = .shared, db: Firestore = .firestore()) {
        self.coreData = coreData
        self.db = db
    }

    func fetchTransactions(forUserID uid: String) throws -> [Transaction] {
        let req: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        req.predicate = NSPredicate(format: "userID == %@", uid)
        req.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return try coreData.context.fetch(req)
    }

    func startRemoteSync(userID: String, onChange: @escaping () -> Void) {
        listener?.remove()
        listener = db.collection("transactions")
            .whereField("userID", isEqualTo: userID)
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("❌ Listener: \(error.localizedDescription)")
                    return
                }
                self?.mergeRemoteDocumentsIfNeeded(snapshot: snapshot, userID: userID)
                DispatchQueue.main.async { onChange() }
            }
    }

    func stopRemoteSync() {
        listener?.remove()
        listener = nil
    }

    private func mergeRemoteDocumentsIfNeeded(snapshot: QuerySnapshot?, userID: String) {
        guard let docs = snapshot?.documents else { return }
        let ctx = coreData.context
        for doc in docs {
            let data = doc.data()
            let docID = doc.documentID
            let req: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            req.predicate = NSPredicate(format: "documentID == %@ AND userID == %@", docID, userID)
            if let existing = try? ctx.fetch(req), !existing.isEmpty { continue }

            let t = Transaction(context: ctx)
            t.documentID = docID
            t.userID = userID
            t.title = data["title"] as? String
            t.amount = data["amount"] as? Double ?? 0
            t.category = data["category"] as? String
            t.type = data["type"] as? String
            if let ts = data["date"] as? Timestamp {
                t.date = ts.dateValue()
            }
        }
        coreData.saveContext()
    }

    func deleteLocalAndRemote(_ transaction: Transaction) {
        if let docID = transaction.documentID {
            db.collection("transactions").document(docID).delete { err in
                if let err = err { print("❌ Firebase delete: \(err.localizedDescription)") }
            }
        }
        coreData.context.delete(transaction)
        coreData.saveContext()
    }

    func updateTitleAndAmount(documentID: String?, title: String, amount: Double, local: Transaction) {
        if let docID = documentID {
            db.collection("transactions").document(docID)
                .updateData(["title": title, "amount": amount]) { err in
                    if let err = err { print("❌ Firebase update: \(err.localizedDescription)") }
                }
        }
        local.title = title
        local.amount = amount
        coreData.saveContext()
    }

    func createTransaction(_ input: NewTransactionInput, completion: @escaping (Error?) -> Void) {
        let newDocRef = db.collection("transactions").document()
        let firebaseID = newDocRef.documentID
        let finalCategory = input.isIncome
            ? "Kirim"
            : ((input.category == "Boshqa...") ? input.title : input.category)

        let ctx = coreData.context
        let transaction = Transaction(context: ctx)
        transaction.documentID = firebaseID
        transaction.id = UUID()
        transaction.title = input.title
        transaction.amount = input.amount
        transaction.date = Date()
        transaction.type = input.isIncome ? "Income" : "Expense"
        transaction.category = finalCategory
        transaction.userID = input.userID

        coreData.saveContext()

        let transactionData: [String: Any] = [
            "userID": input.userID,
            "documentID": firebaseID,
            "id": transaction.id?.uuidString ?? UUID().uuidString,
            "title": input.title,
            "amount": input.amount,
            "category": finalCategory,
            "date": Timestamp(date: Date()),
            "type": input.isIncome ? "Income" : "Expense"
        ]

        newDocRef.setData(transactionData) { error in
            completion(error)
        }
    }

    func deleteAllLocalTransactions(forUserID uid: String) {
        let ctx = coreData.context
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        request.predicate = NSPredicate(format: "userID == %@", uid)
        guard let data = try? ctx.fetch(request) else { return }
        data.forEach { ctx.delete($0) }
        coreData.saveContext()
    }
}
