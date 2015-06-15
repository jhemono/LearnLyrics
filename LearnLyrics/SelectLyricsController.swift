//
//  SelectLyricsController.swift
//  LearnLyrics
//
//  Created by Julien Hémono on 15/06/15.
//  Copyright © 2015 Julien Hémono. All rights reserved.
//

import Cocoa

class SelectLyricsController: UITableViewController {
    var lyrics: Set<Lyrics>? {
        didSet {
            lyricsArray = Array(lyrics ?? [])
        }
    }
    private var lyricsArray: [Lyrics]?
}
