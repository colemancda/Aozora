//
//  AnimePosterCell.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 1/30/16.
//  Copyright © 2016 AnyTap. All rights reserved.
//

import Foundation

class AnimePosterCell: UICollectionViewCell {

    static let id = "AnimePosterCell"
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!

    class func registerNibFor(collectionView collectionView: UICollectionView) {
        let chartNib = UINib(nibName: AnimePosterCell.id, bundle: nil)
        collectionView.registerNib(chartNib, forCellWithReuseIdentifier: AnimePosterCell.id)
    }
}