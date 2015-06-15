//
//  UIViewControllerExtensions.swift
//  LearnLyrics
//
//  Created by Julien Hémono on 15/06/15.
//  Copyright © 2015 Julien Hémono. All rights reserved.
//

import UIKit

extension UIViewController {
    var contentViewController: UIViewController {
        if let navigationVC = self as? UINavigationController,
           let content = navigationVC.topViewController?.contentViewController {
            return content
        } else {
            return self
        }
    }
}