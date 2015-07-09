//
//  Sync.swift
//  LearnLyrics
//
//  Created by Julien Hémono on 02/07/15.
//  Copyright © 2015 Julien Hémono. All rights reserved.
//

import Foundation
import CoreData

class Sync: NSManagedObject {
    
    convenience init(context: NSManagedObjectContext) {
        let entityDescription = NSEntityDescription.entityForName("Sync", inManagedObjectContext: context)
        self.init(entity: entityDescription!, insertIntoManagedObjectContext: context)
    }
    
}