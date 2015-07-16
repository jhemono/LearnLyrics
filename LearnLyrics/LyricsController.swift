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
    
    private var middleRowIndexPath: NSIndexPath? {
        let pointOnMiddle = CGPoint(x: 10, y: tableView.bounds.midY)
        return tableView?.indexPathForRowAtPoint(pointOnMiddle)
    }
    
    var currentTime: Double {
        get {
            guard let indexPath = middleRowIndexPath else { return 0 }
            return syncArray[indexPath.row].timestamp.doubleValue
        }
        set {
            for index in syncArray.indices {
                if index.successor() == syncArray.endIndex || syncArray[index.successor()].timestamp.doubleValue > newValue {
                    tableView?.selectRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0), animated: true, scrollPosition: .Middle)
                    return
                }
            }
        }
    }
    
    //MARK: Lyric Editing
    
    private var editingRow: NSIndexPath? {
        didSet {
            guard editingRow != oldValue else { return }
            tableView.beginUpdates()
            if let oldRow = oldValue {
                tableView.reloadRowsAtIndexPaths([oldRow], withRowAnimation: UITableViewRowAnimation.Right)
            }
            if let newRow = editingRow {
                tableView.reloadRowsAtIndexPaths([newRow], withRowAnimation: UITableViewRowAnimation.Left)
                tableView.selectRowAtIndexPath(newRow, animated: true, scrollPosition: .Middle)
            }
            tableView.endUpdates()
        }
    }
    
    @IBAction func longPress(sender: UILongPressGestureRecognizer) {
        guard sender.state == .Began else { return }
        
        if editingRow != nil {
            editingRow = nil
        } else {
            let point = sender.locationInView(tableView)
            editingRow = tableView.indexPathForRowAtPoint(point)
        }
    }
    //MARK: Scrubbing
    
    private func beginScrubbing() {
        if editingRow == nil {
            delegate?.lyricsControllerDidBeginScrubbing(self)
        }
    }
    
    private func endScrubbing() {
        if editingRow == nil {
            delegate?.lyricsController(self, didScrubToTime: currentTime)
            delegate?.lyricsControllerDidEndScrubbing(self)
        } else {
            editingRow = middleRowIndexPath
        }
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
        
        (cell as? SyncDisplayCell)?.lines = lines
        (cell as? SyncEditCell)?.lines = lines
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let identifier: String
        if indexPath == editingRow {
            identifier = Constants.LyricsPartEditCellReuseIdentifier
        } else {
            identifier = Constants.LyricsPartCellReuseIdentifier
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath)
        
        configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    private struct Constants {
        static let LyricsPartCellReuseIdentifier = "LyricsPartCell"
        static let LyricsPartEditCellReuseIdentifier = "EditLyricsPartCell"
    }

}
