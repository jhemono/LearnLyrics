//
//  Sync+CoreDataProperties.swift
//  LearnLyrics
//
//  Created by Julien Hémono on 02/07/15.
//  Copyright © 2015 Julien Hémono. All rights reserved.
//

import Foundation
import CoreData

extension Sync {
    @NSManaged var timestamp: NSNumber
    @NSManaged var song: Song
    @NSManaged var parts: Set<Part>
}