//
//  LyricsController.swift
//  LearnLyrics
//
//  Created by Julien Hémono on 15/06/15.
//  Copyright © 2015 Julien Hémono. All rights reserved.
//

import UIKit

protocol LyricsControllerDelegate {
    func lyricsControllerDidBeginScrubbing(controller: LyricsController)
    func lyricsController(controller: LyricsController, didScrubToTime time: Double)
    func lyricsControllerDidEndScrubbing(controller: LyricsController)
}

class LyricsController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var lyrics: Lyrics? {
        didSet {
            let timestampOrder = NSSortDescriptor(key: "timestamp", ascending: true)
            parts = lyrics?.parts?.sortedArrayUsingDescriptors([timestampOrder]) as? [LyricsPart] ?? []
            tableView?.reloadData()
        }
    }
    
    private var parts = [LyricsPart]()
    
    var delegate: LyricsControllerDelegate?
    
    var currentTime: Double = 0 {
        didSet {
            for index in parts.indices {
                if index.successor() == parts.endIndex || parts[index.successor()].timestamp?.doubleValue > currentTime {
                    tableView?.selectRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0), animated: true, scrollPosition: .Middle)
                    return
                }
            }
        }
    }
    
    //MARK: Scrubbing
    
    private func beginScrubbing() {
        delegate?.lyricsControllerDidBeginScrubbing(self)
    }
    
    private func endScrubbing() {
        let pointOnMiddle = CGPoint(x: 10, y: tableView.bounds.midY)
        guard let indexPath = tableView.indexPathForRowAtPoint(pointOnMiddle) else { return }
        let time = parts[indexPath.row].timestamp!.doubleValue
        delegate?.lyricsController(self, didScrubToTime: time)
        delegate?.lyricsControllerDidEndScrubbing(self)
    }
    
    //MARK: UIScrollViewDelegate
    
    private var waitingForEndDecelerating = false
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        if !waitingForEndDecelerating {
            beginScrubbing()
        }
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate && !waitingForEndDecelerating {
            endScrubbing()
        } else {
            waitingForEndDecelerating = true
        }
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        waitingForEndDecelerating = false
        endScrubbing()
    }
    
    //MARK: - UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Middle, animated: true)
        delegate?.lyricsController(self, didScrubToTime: parts[indexPath.row].timestamp!.doubleValue)
    }
    
    //MARK: - Lifecycle

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
    
    @IBOutlet weak var tableView: UITableView!
    
    private struct Constants {
        static let LyricsPartCellReuseIdentifier = "LyricsPartCell"
    }

}
