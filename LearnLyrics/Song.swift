//
//  Song.swift
//  LearnLyrics
//
//  Created by Julien Hémono on 14/06/15.
//  Copyright © 2015 Julien Hémono. All rights reserved.
//

import Foundation
import CoreData
import MediaPlayer

class Song: NSManagedObject {
    
    convenience init(context: NSManagedObjectContext) {
        let entityDescription = NSEntityDescription.entityForName("Song", inManagedObjectContext: context)
        self.init(entity: entityDescription!, insertIntoManagedObjectContext: context)
    }
    
    convenience init(context: NSManagedObjectContext, mediaItem item: MPMediaItem) {
        self.init(context: context)
        self.artist = item.valueForKey(MPMediaItemPropertyArtist) as? String
        self.title = item.valueForKey(MPMediaItemPropertyTitle) as? String
        self.persistentIDMP = item.valueForKey(MPMediaItemPropertyPersistentID) as? NSNumber
        
        // Placeholder lyrics
        let duration = (item.valueForKey(MPMediaItemPropertyPlaybackDuration) as? Double) ?? 0
        
        let syncs = 0.stride(through: duration, by: 1).map { (d) -> Sync in
            let sync = Sync(context: context)
            sync.timestamp = NSNumber(double: d)
            sync.song = self
            return sync
        }
        
        for code in ["fr", "en", "nl", "de"] {
            let formatter = NSNumberFormatter()
            formatter.locale = NSLocale(localeIdentifier: code)
            formatter.numberStyle = .SpellOutStyle
            
            let lyrics = Lyrics(context: context)
            lyrics.language = code
            lyrics.song = self
            for sync in syncs {
                let part = Part(context: context)
                part.text = formatter.stringFromNumber(sync.timestamp)
                part.lyrics = lyrics
                part.sync = sync
            }
        }
        
        self.displayed = NSOrderedSet(object: self.lyrics.first!)
    }
    
    var mutableLyrics: NSMutableSet {
        return mutableSetValueForKey("lyrics")
    }
    
    var mutableDisplayed: NSMutableOrderedSet {
        return mutableOrderedSetValueForKey("displayed")
    }
    
}
