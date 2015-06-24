//
//  LyricsController.swift
//  LearnLyrics
//
//  Created by Julien Hémono on 15/06/15.
//  Copyright © 2015 Julien Hémono. All rights reserved.
//

import UIKit

protocol LyricsControllerDelegate {
    
}

class LyricsController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    var lyrics: Lyrics? {
        didSet {
            let timestampOrder = NSSortDescriptor(key: "timestamp", ascending: true)
            parts = lyrics?.parts?.sortedArrayUsingDescriptors([timestampOrder]) as? [LyricsPart] ?? []
            tableView?.reloadData()
        }
    }
    
    var parts = [LyricsPart]()
    
    var currentTime: Double = 0 {
        didSet {
            for index in parts.indices {
                if index.successor() == parts.endIndex || parts[index.successor()].timestamp?.doubleValue > currentTime {
                    tableView?.scrollToRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0), atScrollPosition: .Middle, animated: true)
                    return
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes

        // Do any additional setup after loading the view.
    }
    
    // MARK: UITableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return parts.count
    }
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        let part = parts[indexPath.row]
        
        cell.textLabel?.text = part.text
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.LyricsPartCellReuseIdentifier, forIndexPath: indexPath)
        
        configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    private struct Constants {
        static let LyricsPartCellReuseIdentifier = "LyricsPartCell"
    }

}
