//
//  NowPlayingController.swift
//  LearnLyrics
//
//  Created by Julien Hémono on 15/06/15.
//  Copyright © 2015 Julien Hémono. All rights reserved.
//

import UIKit

class NowPlayingController: UIViewController, SafeSegue {
    
    var song: Song?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segueIdentifierForSegue(segue) {
        case .SelectLyrics:
            break
        case .EmbedLyrics:
            break
        }
    }
    
    enum SegueIdentifiers: String {
        case EmbedLyrics = "Embed Lyrics"
        case SelectLyrics = "Select Lyrics"
    }

}
