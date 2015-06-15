//
//  Segue.swift
//  LearnLyrics
//
//  Created by Julien Hémono on 15/06/15.
//  Copyright © 2015 Julien Hémono. All rights reserved.
//

import UIKit

protocol SafeSegue {
    typealias SegueIdentifiers: RawRepresentable
}

extension SafeSegue where Self: UIViewController, SegueIdentifiers.RawValue == String {
    func performSegueWithIdentifier(identifier: SegueIdentifiers, sender: AnyObject?) {
        performSegueWithIdentifier(identifier.rawValue, sender: sender)
    }
    
    func segueIdentifierForSegue(segue: UIStoryboardSegue) -> SegueIdentifiers {
        guard let identifier = segue.identifier,
            let segueIdentifier = SegueIdentifiers(rawValue: identifier) else {
                fatalError("Nil or unrecognized segue identifer")
        }
        return segueIdentifier
    }
}