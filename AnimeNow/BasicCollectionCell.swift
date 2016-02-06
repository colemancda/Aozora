//
//  BasicCollectionCell.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/8/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit
import FLAnimatedImage

public protocol BasicCollectionCellDelegate: class {
    func cellSelectedActionButton(cell: BasicCollectionCell)
}

public class BasicCollectionCell: UICollectionViewCell {
    
    public weak var delegate: BasicCollectionCellDelegate?
    
    @IBOutlet public weak var titleLabel: UILabel!
    @IBOutlet public weak var titleimageView: UIImageView!
    @IBOutlet public weak var actionButton: UIButton!
    @IBOutlet public weak var subtitleLabel: UILabel!
    
    @IBOutlet public weak var animatedImageView: FLAnimatedImageView!
    
    public var loadingURL: String?
    
    @IBAction public func actionButtonPressed(sender: AnyObject) {
        delegate?.cellSelectedActionButton(self)
    }
}