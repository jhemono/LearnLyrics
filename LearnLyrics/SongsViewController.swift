//
//  SongsViewController.swift
//  LearnLyrics
//
//  Created by Julien Hémono on 14/06/15.
//  Copyright © 2015 Julien Hémono. All rights reserved.
//

import UIKit
import CoreData
import MediaPlayer

class SongsViewController: UITableViewController, FetchedTableViewController, MPMediaPickerControllerDelegate {
    
    // MARK: - Fetched Results Controller
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        return (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    }()
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = NSEntityDescription.entityForName("Song", inManagedObjectContext: self.managedObjectContext)
        let artistDescriptor = NSSortDescriptor(key: "artist", ascending: true)
        let titleDescriptor = NSSortDescriptor(key: "title", ascending: true)
        fetchRequest.sortDescriptors = [artistDescriptor, titleDescriptor]
        
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "artist", cacheName: "Songs List")
        controller.delegate = self
        
        return controller
    }()
    
    // MARK: - Lifecycle
    
    private func handleError(error: NSError) {
        debugPrint("Unresolved error \(error), \(error.userInfo)")
        abort()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            // TODO: Handle error
            handleError(error)
        }

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    // MARK: - Table view data source
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        let song = fetchedResultsController.objectAtIndexPath(indexPath) as! Song
        
        cell.textLabel?.text = song.title
        cell.detailTextLabel?.text = song.artist
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.SongCellReuseIdentifier, forIndexPath: indexPath)

        configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            managedObjectContext.deleteObject(fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject)
            managedObjectContext.saveIfHasChanges()
        }
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "PlaySong" {
            let playVC = segue.destinationViewController.contentViewController as! NowPlayingController
            let cell = sender as! UITableViewCell
            if let indexPath = tableView.indexPathForCell(cell) {
                let song = fetchedResultsController.objectAtIndexPath(indexPath) as? Song
                playVC.song = song
            }
        }
    }
    
    // MARK: - Adding songs from media picker
    
    @IBAction func addSongFromLibrary(sender: UIBarButtonItem) {
        let picker = MPMediaPickerController(mediaTypes: MPMediaType.Music)
        picker.delegate = self
        picker.showsCloudItems = false
        presentViewController(picker, animated: true, completion: nil)
    }
    
    func mediaPicker(mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        dismissViewControllerAnimated(true, completion: nil)
        
        for item in mediaItemCollection.items {
            let _ = Song(context: managedObjectContext, mediaItem: item)
        }
        
        managedObjectContext.saveIfHasChanges()
    }
    
    func mediaPickerDidCancel(mediaPicker: MPMediaPickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    private struct Constants {
        static let SongCellReuseIdentifier = "Song Cell"
    }

}
