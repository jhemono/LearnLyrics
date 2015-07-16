//
//  SyncEditCell.swift
//  LearnLyrics
//
//  Created by Julien Hémono on 15/07/15.
//  Copyright © 2015 Julien Hémono. All rights reserved.
//

import UIKit

class SyncEditCell: UITableViewCell {
    
    var lines = [String?]() {
        didSet {
            while stack.arrangedSubviews.count > lines.count {
                let lineLabel = stack.arrangedSubviews.last!
                stack.removeArrangedSubview(lineLabel)
                lineLabel.removeFromSuperview()
            }
            
            while lines.count > stack.arrangedSubviews.count {
                let lineLabel = UITextField()
                lineLabel.delegate = delegate
                lineLabel.tag = stack.arrangedSubviews.count
                stack.addArrangedSubview(lineLabel)
            }
            
            for i in lines.indices {
                (stack.arrangedSubviews[i] as! UITextField).text = lines[i]
            }
        }
    }
    
    weak var delegate: UITextFieldDelegate? {
        didSet {
            for field in stack.arrangedSubviews as! [UITextField] {
                field.delegate = delegate
            }
        }
    }
    
    @IBOutlet weak var stack: UIStackView!

}
