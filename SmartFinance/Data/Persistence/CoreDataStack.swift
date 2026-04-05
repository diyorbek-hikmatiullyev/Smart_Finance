//
//  CoreDataStack.swift
//  SmartFinance
//

import CoreData

final class CoreDataStack {
    static let shared = CoreDataStack()
    private init() {}

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "SmartFinance")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data yuklanishida xatolik: \(error)")
            }
        }
        return container
    }()

    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Saqlashda xatolik: \(error)")
            }
        }
    }
}
