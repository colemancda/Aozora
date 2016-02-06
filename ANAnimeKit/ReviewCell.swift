//
//  ReviewCell.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/9/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit

class ReviewCell: UITableViewCell {
    
    @IBOutlet weak var reviewerLabel: UILabel!
    @IBOutlet weak var reviewerAvatar: UIImageView!
    @IBOutlet weak var reviewerOverallScoreLabel: UILabel!
    @IBOutlet weak var reviewerReviewLabel: UILabel!
    @IBOutlet weak var reviewStatisticsLabel: UILabel!
    
    @IBOutlet weak var reviewHeightConstraint: NSLayoutConstraint!
}
