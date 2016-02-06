//
//  BasicCollectionReusableView.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/6/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit

public protocol BasicCollectionReusableViewDelegate: class {
    func headerSelectedActionButton(cell: BasicCollectionReusableView)
    func headerSelectedActionButton2(cell: BasicCollectionReusableView)
}

public class BasicCollectionReusableView: UICollectionReusableView {

    public weak var delegate: BasicCollectionReusableViewDelegate?
    public var section: Int?
    
    @IBOutlet public weak var titleLabel: UILabel!
    @IBOutlet public weak var subtitleLabel: UILabel!
    @IBOutlet public weak var titleImageView: UIImageView!
    @IBOutlet public weak var actionButton: UIButton!
    
    @IBAction public func actionButtonPressed(sender: AnyObject) {
        delegate?.headerSelectedActionButton(self)
    }
    
    @IBAction func actionButton2Pressed(sender: AnyObject) {
        delegate?.headerSelectedActionButton2(self)
    }
}
