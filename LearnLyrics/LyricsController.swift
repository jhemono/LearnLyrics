//
//  LyricsController.swift
//  LearnLyrics
//
//  Created by Julien Hémono on 15/06/15.
//  Copyright © 2015 Julien Hémono. All rights reserved.
//

import UIKit

protocol LyricsControllerDelegate: class {
    func lyricsControllerDidBeginScrubbing(controller: LyricsController)
    func lyricsController(controller: LyricsController, didScrubToTime time: Double)
    func lyricsControllerDidEndScrubbing(controller: LyricsController)
}

class LyricsController: UITableViewController, UITextFieldDelegate {
    
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
    
    weak var delegate: LyricsControllerDelegate?
    
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
            } else {
               lyrics.first!.managedObjectContext!.saveIfHasChanges()
            }
            tableView.endUpdates()
        }
    }
    
    private var editingLanguageIndex: Int?
    
    @IBAction func longPress(sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .Began where editingRow != nil:
            editingRow = nil
        case .Began:
            fallthrough
        case .Changed, .Ended where editingRow != nil:
            let point = sender.locationInView(tableView)
            editingRow = tableView.indexPathForRowAtPoint(point)
        default:
            break
        }
    }
    
    private var firstReponderRow: NSIndexPath?
    
    func textFieldDidBeginEditing(textField: UITextField) {
        assert(firstReponderRow == nil)
        assert(editingRow != nil)
        firstReponderRow = editingRow
        editingLanguageIndex = textField.tag
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        let languageIndex = textField.tag
        let text = textField.text
        guard let syncIndex = firstReponderRow?.row else {
            print("should not read textfield when not editing")
            return
        }
        
        let languageParts = lyrics[languageIndex].parts
        let syncParts = syncArray[syncIndex].parts
        let part = languageParts.intersect(syncParts).first!
        part.text = text
        firstReponderRow = nil
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
            if let editingRowIndexPath = editingRow
                where tableView.indexPathsForVisibleRows!.contains(editingRowIndexPath) {
                    return
            }
            editingRow = middleRowIndexPath

        }
    }
    
    //MARK: UIScrollViewDelegate
    
    private var waitingForEndDecelerating = false
    
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        if !waitingForEndDecelerating {
            beginScrubbing()
        }
    }
    
    override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate && !waitingForEndDecelerating {
            endScrubbing()
        } else {
            waitingForEndDecelerating = true
        }
    }
    
    override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        waitingForEndDecelerating = false
        endScrubbing()
    }
    
    override func scrollViewShouldScrollToTop(scrollView: UIScrollView) -> Bool {
        return false
    }
    
    //MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if editingRow == nil {
            tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Middle, animated: true)
            delegate?.lyricsController(self, didScrubToTime: syncArray[indexPath.row].timestamp.doubleValue)
        } else {
            editingRow = indexPath
        }
    }
    
    //MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: UITableViewDataSource
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return syncArray.count
    }
    
    private func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        let syncParts = syncArray[indexPath.row].parts
        let lines = lyrics.map { $0.parts.intersect(syncParts).first?.text }
        
        if let editCell = cell as? SyncEditCell {
            editCell.lines = lines
            editCell.delegate = self
            if editingLanguageIndex == nil {
                editingLanguageIndex = 0
            }
            editingLanguageIndex = min(editingLanguageIndex!, editCell.stack.arrangedSubviews.count - 1)
            (editCell.stack.arrangedSubviews[editingLanguageIndex!] as! UITextField).becomeFirstResponder()
        } else if let displayCell = cell as? SyncDisplayCell {
            displayCell.lines = lines
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
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
    
    private struct Constants {
        static let LyricsPartCellReuseIdentifier = "LyricsPartCell"
        static let LyricsPartEditCellReuseIdentifier = "EditLyricsPartCell"
    }

}
