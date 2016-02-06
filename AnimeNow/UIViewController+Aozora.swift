//
//  UIViewController+Aozora.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 8/1/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation

extension UIViewController {
    public func addRefreshControl(refreshControl: UIRefreshControl, action: Selector, forTableView tableView: UITableView) {
        refreshControl.tintColor = UIColor.lightGrayColor()
        refreshControl.addTarget(self, action: action, forControlEvents: UIControlEvents.ValueChanged)
        tableView.insertSubview(refreshControl, atIndex: tableView.subviews.count - 1)
        tableView.alwaysBounceVertical = true
    }
    
    public func addRefreshControl(refreshControl: UIRefreshControl, action: Selector, forCollectionView collectionView: UICollectionView) {
        refreshControl.tintColor = UIColor.lightGrayColor()
        refreshControl.addTarget(self, action: action, forControlEvents: UIControlEvents.ValueChanged)
        collectionView.insertSubview(refreshControl, atIndex: collectionView.subviews.count - 1)
        collectionView.alwaysBounceVertical = true
    }
}