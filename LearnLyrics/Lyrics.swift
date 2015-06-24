//
//  Lyrics.swift
//  LearnLyrics
//
//  Created by Julien Hémono on 14/06/15.
//  Copyright © 2015 Julien Hémono. All rights reserved.
//

import Foundation
import CoreData

class Lyrics: NSManagedObject {
    
    convenience init(context: NSManagedObjectContext) {
        let entityDescription = NSEntityDescription.entityForName("Lyrics", inManagedObjectContext: context)
        self.init(entity: entityDescription!, insertIntoManagedObjectContext: context)
    }
    
    var mutableParts: NSMutableOrderedSet {
        return mutableOrderedSetValueForKey("parts")
    }
    
}
