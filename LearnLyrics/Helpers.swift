//
//  Helpers.swift
//  LearnLyrics
//
//  Created by Julien Hémono on 18/07/15.
//  Copyright © 2015 Julien Hémono. All rights reserved.
//

import CoreData

extension NSManagedObjectContext {
    func saveIfHasChanges() {
        if hasChanges {
            do {
                try save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
}
