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

class SongsViewController: UITableViewController, NSFetchedResultsControllerDelegate, MPMediaPickerControllerDelegate {
    
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
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: NSManagedObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
        case .Update:
            configureCell(tableView.cellForRowAtIndexPath(indexPath!)!, atIndexPath: indexPath!)
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Automatic)
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: UITableViewRowAnimation.Automatic)
        case .Delete:
            tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: UITableViewRowAnimation.Automatic)
        default:
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }
    
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
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
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return fetchedResultsController.sections?[section].name
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            managedObjectContext.deleteObject(fetchedResultsController.objectAtIndexPath(indexPath))
            do {
                try managedObjectContext.save()
            } catch let error as NSError {
                handleError(error)
            }
        }
    }

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    
    // MARK: - Adding songs from media picker
    
    @IBAction func addSongFromLibrary(sender: UIBarButtonItem) {
        let picker = MPMediaPickerController(mediaTypes: MPMediaType.Music)
        picker.delegate = self
        presentViewController(picker, animated: true, completion: nil)
    }
    
    func mediaPicker(mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        dismissViewControllerAnimated(true, completion: nil)
        
        let entity = NSEntityDescription.entityForName(Constants.SongEntity, inManagedObjectContext: managedObjectContext)
        
        for item in mediaItemCollection.items {
            let song = Song(entity: entity!, insertIntoManagedObjectContext: managedObjectContext)
            song.artist = item.valueForKey(MPMediaItemPropertyArtist) as? String
            song.title = item.valueForKey(MPMediaItemPropertyTitle) as? String
            song.persistentIDMP = Int64((item.valueForKey(MPMediaItemPropertyPersistentID) as? UInt64) ?? 0)
        }
        
        do {
            try managedObjectContext.save()
        } catch let error as NSError {
            handleError(error)
        }
    }
    
    func mediaPickerDidCancel(mediaPicker: MPMediaPickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    private struct Constants {
        static let SongCellReuseIdentifier = "Song Cell"
        static let SongEntity = "Song"
    }

}
