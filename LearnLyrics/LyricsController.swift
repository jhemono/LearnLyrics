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
    
    var lyrics: [Lyrics] = [] {
        didSet {
            tableView?.reloadData()
        }
    }
    
    var syncs: Set<Sync> = [] {
        didSet {
            syncArray = syncs.sort({ (lhs, rhs) in
                return lhs.timestamp.doubleValue < rhs.timestamp.doubleValue
            })
            tableView?.reloadData()
        }
    }
    
    private var syncArray = [Sync]()
    
    var delegate: LyricsControllerDelegate?
    
    var currentTime: Double {
        get {
            let pointOnMiddle = CGPoint(x: 10, y: tableView.bounds.midY)
            guard let indexPath = tableView?.indexPathForRowAtPoint(pointOnMiddle) else { return 0 }
            let time = syncArray[indexPath.row].timestamp.doubleValue
            return time
        }
        set {
            let index = syncArray.indexOf { $0.timestamp.doubleValue <= newValue } ?? syncArray.startIndex
            tableView?.selectRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0), animated: true, scrollPosition: .Middle)
        }
    }
    
    //MARK: Scrubbing
    
    private func beginScrubbing() {
        delegate?.lyricsControllerDidBeginScrubbing(self)
    }
    
    private func endScrubbing() {
        delegate?.lyricsController(self, didScrubToTime: currentTime)
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
    
    func scrollViewShouldScrollToTop(scrollView: UIScrollView) -> Bool {
        return false
    }
    
    //MARK: - UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Middle, animated: true)
        delegate?.lyricsController(self, didScrubToTime: syncArray[indexPath.row].timestamp.doubleValue)
    }
    
    //MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return syncArray.count
    }
    
    private func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        let syncParts = syncArray[indexPath.row].parts
        let lines = lyrics.map { $0.parts.intersect(syncParts).first?.text }
        
        (cell as! SyncDisplayCell).lines = lines
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
