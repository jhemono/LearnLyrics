//
//  LyricsPart+CoreDataProperties.swift
//  LearnLyrics
//
//  Created by Julien Hémono on 14/06/15.
//  Copyright © 2015 Julien Hémono. All rights reserved.
//
//  Delete this file and regenerate it using "Create NSManagedObject Subclass…"
//  to keep your implementation up to date with your model.
//

import Foundation
import CoreData

extension LyricsPart {

    @NSManaged var text: String?
    @NSManaged var timestamp: NSNumber?
    @NSManaged var ofLyrics: Lyrics?

}
