//
//  CoreDataStack.swift
//  SmartFinance
//
//  Created by Diyorbek Xikmatullayev on 22/03/26.
//

import CoreData
import UIKit

class CoreDataStack {
    static let shared = CoreDataStack()
    private init() {}

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "SmartFinance") // .xcdatamodeld faylingiz nomi
        container.loadPersistentStores { (_, error) in
            if let error = error {
                fatalError("Core Data yuklanishida xatolik: \(error)")
            }
        }
        return container
    }()

    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
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
