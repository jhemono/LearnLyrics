//
//  SelectLyricsController.swift
//  LearnLyrics
//
//  Created by Julien Hémono on 15/06/15.
//  Copyright © 2015 Julien Hémono. All rights reserved.
//

import UIKit
import CoreData

protocol SelectLyricsControllerDelegate {
    func selectLyricsControllerIsDone(controller: SelectLyricsController)
}

class SelectLyricsController: UITableViewController {
    
    var delegate: SelectLyricsControllerDelegate?
    
    var song: Song! {
        didSet {
            displayed = song.mutableDisplayed
            updateLyricsArray()
        }
    }
    
    private var order = LanguageOrder.sharedOrder()
    
    private var displayed: NSMutableOrderedSet!
    
    // Sorted by persisted order
    private var lyricsArray: [Lyrics]!
    
    private let locale = NSLocale.currentLocale()
    
    private func updateLyricsArray() {
        lyricsArray = order.orderLyrics(song.lyrics.subtract(displayed.set as! Set<Lyrics>))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.reloadData()
        tableView.setEditing(true, animated: false)
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "On Display" : "Other Languages"
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return displayed.count
        } else {
            return lyricsArray.count
        }
    }

    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        let lyric: Lyrics
        if indexPath.displayed {
            lyric = displayed.objectAtIndex(indexPath.row) as! Lyrics
        } else {
            lyric = lyricsArray[indexPath.row]
        }
        let localizedName = locale.displayNameForKey(NSLocaleLanguageCode, value: lyric.language)
        
        cell.textLabel?.text = localizedName ?? lyric.language
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Language Cell", forIndexPath: indexPath)
        
        configureCell(cell, atIndexPath: indexPath)

        return cell
    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        return indexPath.displayed ? nil : indexPath
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let indexPathBottomDisplayed = NSIndexPath(forRow: displayed.count, inSection: 0)
        self.tableView(tableView, moveRowAtIndexPath: indexPath, toIndexPath: indexPathBottomDisplayed)
        tableView.moveRowAtIndexPath(indexPath, toIndexPath: indexPathBottomDisplayed)
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.None
    }
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        
        guard sourceIndexPath != destinationIndexPath else { return }
        
        if sourceIndexPath.displayed && destinationIndexPath.displayed {
            displayed.moveObjectsAtIndexes(NSIndexSet(index: sourceIndexPath.row), toIndex: destinationIndexPath.row)
            return
        }
        
        let lyric: Lyrics
        if sourceIndexPath.displayed {
            lyric = displayed.objectAtIndex(sourceIndexPath.row) as! Lyrics
            displayed.removeObjectAtIndex(sourceIndexPath.row)
        } else {
            lyric = lyricsArray.removeAtIndex(sourceIndexPath.row)
        }
        
        if destinationIndexPath.displayed {
            displayed.insertObject(lyric, atIndex: destinationIndexPath.row)
        } else {
            lyricsArray.insert(lyric, atIndex: destinationIndexPath.row)
        }
        
        if !sourceIndexPath.displayed && destinationIndexPath.displayed {
            order.raiseLanguage(lyric)
        }
    }

    @IBAction func hitDone(sender: UIBarButtonItem) {
        delegate?.selectLyricsControllerIsDone(self)
    }
    
    //MARK: -Lifecyle
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        do {
            try song.managedObjectContext?.save()
        } catch {
            print("Error saving seledted languages")
            abort()
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

private extension NSIndexPath {
    var displayed: Bool {
        return section == 0
    }
}
