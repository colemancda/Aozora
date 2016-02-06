//
//  LoadingTableCell.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/27/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit
import ANCommonKit

class LoadingTableCell: UITableViewCell {
    
    var loadingView: LoaderView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        loadingView = LoaderView(parentView: contentView)
        loadingView.startAnimating()
    }
}
