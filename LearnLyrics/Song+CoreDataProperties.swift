//
//  Song+CoreDataProperties.swift
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

extension Song {

    @NSManaged var artist: String?
    @NSManaged var title: String?
    @NSManaged var url: NSURL?
    @NSManaged var lyrics: Set<Lyrics>?

}
