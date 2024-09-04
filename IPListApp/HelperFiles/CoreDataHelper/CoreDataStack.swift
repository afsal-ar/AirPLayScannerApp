//
//  CoreDataStack.swift
//  IPListApp
//
//  Created by Afsal  on 27/08/24.
//

import Foundation
import CoreData

class CoreDataStack {
    
    static let shared = CoreDataStack()
     
    lazy var persistentContainer : NSPersistentContainer = {
        let container = NSPersistentContainer(name: "AirplayDevice")
        container.loadPersistentStores(completionHandler: {
            (storedescription,error) in
            if let error = error as NSError? {
                fatalError("Error occurred \(error) with info \(error.userInfo)")
            }
        })
        return container
    }()
    var context : NSManagedObjectContext {
        return persistentContainer.viewContext
    }
}
