//
//  TopicCell.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/16/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit
import TTTAttributedLabel

public class TopicCell: UITableViewCell {
    @IBOutlet public weak var title: UILabel!
    @IBOutlet public weak var information: UILabel!
    @IBOutlet public weak var typeLabel: UILabel!
    @IBOutlet public weak var tagsLabel: TTTAttributedLabel!
}