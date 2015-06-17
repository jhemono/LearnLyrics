//
//  SelectLyricsController.swift
//  LearnLyrics
//
//  Created by Julien Hémono on 15/06/15.
//  Copyright © 2015 Julien Hémono. All rights reserved.
//

import UIKit
import CoreData

class SelectLyricsController: UITableViewController {
    
    var lyricsSet: NSMutableSet? {
        didSet { updateLyricsArray() }
    }
    
    private struct LyricsWithLocalizedName {
        var lyrics: Lyrics
        var localizedName: String
    }
    
    // Sorted by their localized name
    private var lyricsArray: [LyricsWithLocalizedName]?
    
    private func updateLyricsArray() {
        var array = [LyricsWithLocalizedName]()
        let locale = NSLocale.currentLocale()
        for object in lyricsSet! {
            let lyrics = object as! Lyrics
            let localizedName = locale.displayNameForKey(NSLocaleLanguageCode, value: lyrics.language!)
            array.append(LyricsWithLocalizedName(lyrics: lyrics, localizedName: localizedName!))
        }
        array.sortInPlace { $0.localizedName <= $1.localizedName }
        lyricsArray = array
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.reloadData()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lyricsArray?.count ?? 0
    }

    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        guard let localizedName = lyricsArray?[indexPath.row].localizedName else { return }
        
        cell.textLabel?.text = localizedName
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)
        
        configureCell(cell, atIndexPath: indexPath)

        return cell
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {

            if let lyrics = lyricsArray?[indexPath.row].lyrics {
                lyrics.managedObjectContext?.deleteObject(lyrics)
                // Save Managed Object Context
                lyricsArray?.removeAtIndex(indexPath.row)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }
        } else if editingStyle == .Insert {
            
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
