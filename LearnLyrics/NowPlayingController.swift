//
//  NowPlayingController.swift
//  LearnLyrics
//
//  Created by Julien Hémono on 15/06/15.
//  Copyright © 2015 Julien Hémono. All rights reserved.
//

import UIKit
import MediaPlayer
import AVFoundation

private var nowPlayingControllerKVOContext = 0

class NowPlayingController: UIViewController, SafeSegue, SelectLyricsControllerDelegate, LyricsControllerDelegate {
    
    var song: Song? {
        didSet {
            selectedLyrics = song?.lyrics?.allObjects.first as? Lyrics
            getAsset()
        }
    }
    
    //MARK: - Player
    
    private func getAsset() {
        guard let persistentId = song?.persistentIDMP else {
            handleErrorWithMessage("This song has no persistent ID")
            return
        }
        let predicate = MPMediaPropertyPredicate(value: persistentId, forProperty: MPMediaItemPropertyPersistentID)
        let query = MPMediaQuery(filterPredicates: [predicate])
        guard let mediaItem = query.items?.first else {
            handleErrorWithMessage("Could no get a media item")
            return
        }
        guard let assetURL = mediaItem.valueForProperty(MPMediaItemPropertyAssetURL) as? NSURL else {
            handleErrorWithMessage("Cound no get url for media Item")
            return
        }
        asset = AVURLAsset(URL: assetURL)
    }
    
    private var asset: AVURLAsset? {
        didSet {
            guard let newAsset = asset else { return }
            
            asynchronouslyLoadURLAsset(newAsset)
        }
    }
    
    static let assetKeysRequiredToPlay = [
        "playable",
        "hasProtectedContent"
    ]
    
    private func asynchronouslyLoadURLAsset(newAsset: AVURLAsset) {
        /*
        Using AVAsset now runs the risk of blocking the current thread (the
        main UI thread) whilst I/O happens to populate the properties. It's
        prudent to defer our work until the properties we need have been loaded.
        */
        newAsset.loadValuesAsynchronouslyForKeys(NowPlayingController.assetKeysRequiredToPlay) {
            /*
            The asset invokes its completion handler on an arbitrary queue.
            To avoid multiple threads using our internal state at the same time
            we'll elect to use the main thread at all times, let's dispatch
            our handler to the main queue.
            */
            dispatch_async(dispatch_get_main_queue()) {
                /*
                `self.asset` has already changed! No point continuing because
                another `newAsset` will come along in a moment.
                */
                guard newAsset == self.asset else { return }
                
                /*
                Test whether the values of each of the keys we need have been
                successfully loaded.
                */
                for key in NowPlayingController.assetKeysRequiredToPlay {
                    var error: NSError?
                    
                    if newAsset.statusOfValueForKey(key, error: &error) == .Failed {
                        let stringFormat = NSLocalizedString("error.asset_key_%@_failed.description", comment: "Can't use this AVAsset because one of it's keys failed to load")
                        
                        let message = String.localizedStringWithFormat(stringFormat, key)
                        
                        self.handleErrorWithMessage(message, error: error)
                        
                        return
                    }
                }
                
                // We can't play this asset.
                if !newAsset.playable || newAsset.hasProtectedContent {
                    let message = NSLocalizedString("error.asset_not_playable.description", comment: "Can't use this AVAsset because it isn't playable or has protected content")
                    
                    self.handleErrorWithMessage(message)
                    
                    return
                }
                
                /*
                We can play this asset. Create a new `AVPlayerItem` and make
                it our player's current item.
                */
                self.playerItem = AVPlayerItem(asset: newAsset)
            }
        }
    }
    
    private var playerItem: AVPlayerItem? = nil {
        didSet {
            /*
            If needed, configure player item here before associating it with a player.
            (example: adding outputs, setting text style rules, selecting media options)
            */
            player.replaceCurrentItemWithPlayerItem(self.playerItem)
        }
    }
    
    let player = AVPlayer()
    
    var currentTime: Double {
        get {
            return CMTimeGetSeconds(player.currentTime())
        }
        set {
            let newTime = CMTimeMakeWithSeconds(newValue, 1)
            player.seekToTime(newTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
        }
    }
    
    var duration: Double {
        guard let currentItem = player.currentItem else { return 0.0 }
        
        return CMTimeGetSeconds(currentItem.duration)
    }
    
    //MARK: - Interface Builder
    
    @IBOutlet weak var playButton: UIButton!
    
    @IBAction func playPause(sender: UIButton) {
        if player.rate != 1.0 {
            if currentTime == duration {
                currentTime = 0.0
            }
            player.play()
        } else {
            player.pause()
        }
    }
    
    //MARK: - Lyrics
    
    var selectedLyrics: Lyrics? {
        didSet {
            lyricsVC?.lyrics = selectedLyrics
        }
    }
    
    var lyricsVC: LyricsController? {
        didSet {
            lyricsVC?.lyrics = selectedLyrics
        }
    }
    
    //MARK: - Lyfecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        //syncPlayerUI()
        
        addObserver(self, forKeyPath: "player.currentItem.duration", options: [.New, .Initial], context: &nowPlayingControllerKVOContext)
        addObserver(self, forKeyPath: "player.rate", options: [.New, .Initial], context: &nowPlayingControllerKVOContext)
        addObserver(self, forKeyPath: "player.currentItem.status", options: [.New, .Initial], context: &nowPlayingControllerKVOContext)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        player.pause()
        
        removeObserver(self, forKeyPath: "player.currentItem.duration", context: &nowPlayingControllerKVOContext)
        removeObserver(self, forKeyPath: "player.rate", context: &nowPlayingControllerKVOContext)
        removeObserver(self, forKeyPath: "player.currentItem.status", context: &nowPlayingControllerKVOContext)
        
        removeBoundaryObserver()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Scrolling to lyrics part
    
    var timeObserverToken: AnyObject? = nil
    
    func removeBoundaryObserver() {
        if let token = timeObserverToken {
            player.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }
    
    func updateBoundaries() {
        removeBoundaryObserver()
        
        guard let times = selectedLyrics?.parts?.array.map({ (object: AnyObject) -> NSValue in
            let part = object as! LyricsPart
            let time = CMTimeMakeWithSeconds((part.timestamp?.doubleValue)!, 1)
            let value = NSValue(CMTime: time)
            return value
        }) else { return }
        
        let queue = dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0)
        timeObserverToken = player.addBoundaryTimeObserverForTimes(times, queue: queue) {
            dispatch_async(dispatch_get_main_queue()) {
                lyricsVC?.currentTime = currentTime
            }
        }
    }
    
    //MARK: - Scrubbing
    
    var playerRateBeforeScrubbing: Float?
    
    func lyricsControllerDidBeginScrubbing(controller: LyricsController) {
        playerRateBeforeScrubbing = player.rate
        player.pause()
    }
    
    func lyricsController(controller: LyricsController, didEndScrubbingToTime time: Double) {
        currentTime = time
        if playerRateBeforeScrubbing != nil {
            player.rate = playerRateBeforeScrubbing!
            playerRateBeforeScrubbing = nil
        }
    }
    
    //MARK: - Key-Value Observing
    
    // Update our UI when player or `player.currentItem` changes.
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [NSObject : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        // Make sure the this KVO callback was intended for this view controller.
        guard context == &nowPlayingControllerKVOContext else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
            return
        }
        
        if keyPath == "player.currentItem.duration" {
            // enable/disable controls when duration > 0.0
            
            /*
            Handle `NSNull` value for `NSKeyValueChangeNewKey`, i.e. when
            `player.currentItem` is nil.
            */
            let newDuration: CMTime
            if let newDurationAsValue = change?[NSKeyValueChangeNewKey] as? NSValue {
                newDuration = newDurationAsValue.CMTimeValue
            }
            else {
                newDuration = kCMTimeZero
            }
            
            let hasValidDuration = newDuration.isNumeric && newDuration.value != 0
            
            playButton.enabled = hasValidDuration
            
            if hasValidDuration {
                updateBoundaries()
            }
        }
        else if keyPath == "player.rate" {
            // Update `playButton` title.
            
            let newRate = (change?[NSKeyValueChangeNewKey] as! NSNumber).doubleValue
            
            let playButtonTitle = newRate == 1.0 ? "Pause" : "Play"
            
            playButton.setTitle(playButtonTitle, forState: .Normal)
        }
        else if keyPath == "player.currentItem.status" {
            // Display an error if status becomes `.Failed`.
            
            /*
            Handle `NSNull` value for `NSKeyValueChangeNewKey`, i.e. when
            `player.currentItem` is nil.
            */
            let newStatus: AVPlayerItemStatus
            
            if let newStatusAsNumber = change?[NSKeyValueChangeNewKey] as? NSNumber {
                newStatus = AVPlayerItemStatus(rawValue: newStatusAsNumber.integerValue)!
            }
            else {
                newStatus = .Unknown
            }
            
            if newStatus == .Failed {
                handleErrorWithMessage(player.currentItem?.error?.localizedDescription, error:player.currentItem?.error)
            }
        }
    }
    
    // Trigger KVO for anyone observing our properties affected by player and player.currentItem
    override class func keyPathsForValuesAffectingValueForKey(key: String) -> Set<String> {
        let affectedKeyPathsMappingByKey: [String: Set<String>] = [
            "duration":     ["player.currentItem.duration"],
            "currentTime":  ["player.currentItem.currentTime"],
            "rate":         ["player.rate"]
        ]
        
        return affectedKeyPathsMappingByKey[key] ?? super.keyPathsForValuesAffectingValueForKey(key)
    }
    
    // MARK: - Select Lyrics Controller Delegate
    
    func selectLyricsControllerIsDone(controller: SelectLyricsController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func selectLyricsController(controller: SelectLyricsController, didSelectLyrics lyrics: Lyrics) {
        selectedLyrics = lyrics
        dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segueIdentifierForSegue(segue) {
        case .SelectLyrics:
            let selectLyricsVC = segue.destinationViewController.contentViewController as! SelectLyricsController
            selectLyricsVC.delegate = self
            selectLyricsVC.lyricsSet = song?.mutableLyrics
        case .EmbedLyrics:
            lyricsVC = segue.destinationViewController as? LyricsController
            lyricsVC?.delegate = self
        }
    }
    
    enum SegueIdentifiers: String {
        case EmbedLyrics = "Embed Lyrics"
        case SelectLyrics = "Select Lyrics"
    }
    
    // MARK: - Error Handling
    
    func handleErrorWithMessage(message: String?, error: NSError? = nil) {
        NSLog("Error occured with message: \(message), error: \(error).")
        
        let alertTitle = NSLocalizedString("alert.error.title", comment: "Alert title for errors")
        let defaultAlertMessage = NSLocalizedString("error.default.description", comment: "Default error message when no NSError provided")
        
        let alert = UIAlertController(title: alertTitle, message: message == nil ? defaultAlertMessage : message, preferredStyle: UIAlertControllerStyle.Alert)
        
        let alertActionTitle = NSLocalizedString("alert.error.actions.OK", comment: "OK on error alert")
        
        let alertAction = UIAlertAction(title: alertActionTitle, style: .Default, handler: nil)
        
        alert.addAction(alertAction)
        
        presentViewController(alert, animated: true, completion: nil)
    }

}
