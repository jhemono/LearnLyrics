//
//  SyncDisplayCell.swift
//  LearnLyrics
//
//  Created by Julien Hémono on 15/07/15.
//  Copyright © 2015 Julien Hémono. All rights reserved.
//

import UIKit

class SyncDisplayCell: UITableViewCell {
    
    var lines = [String?]() {
        didSet {
            while stack.arrangedSubviews.count > lines.count {
                let lineLabel = stack.arrangedSubviews.last!
                stack.removeArrangedSubview(lineLabel)
                lineLabel.removeFromSuperview()
            }
            
            while lines.count > stack.arrangedSubviews.count {
                let lineLabel = UILabel()
                stack.addArrangedSubview(lineLabel)
            }
            
            for i in lines.indices {
                (stack.arrangedSubviews[i] as! UILabel).text = lines[i]
            }
        }
    }
    
    @IBOutlet weak var stack: UIStackView!

}
