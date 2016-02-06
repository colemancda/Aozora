//
//  AnimeBaseViewController.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/12/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit
import ANParseKit

extension AnimeBaseViewController: RequiresAnimeProtocol {
    func initWithAnime(anime: Anime) {
        self.anime = anime
    }
}

extension AnimeBaseViewController: CustomAnimatorProtocol {
    func scrollView() -> UIScrollView {
        return tableView != nil ? tableView : collectionView
    }
}

public class AnimeBaseViewController: UIViewController {
    var anime: Anime!
    
    @IBOutlet public weak var tableView: UITableView!
    @IBOutlet public weak var collectionView: UICollectionView!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if let _ = tabBarController as? CustomTabBarController {
            
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Stop, target: self, action: "dismissViewControllerPressed")
            
            navigationController?.navigationBar.tintColor = UIColor.peterRiver()
            navigationController?.navigationBar.barTintColor = UIColor.whiteColor()
            navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.blackColor()]
        }
    }
    
    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let tabBar = tabBarController as? CustomTabBarController {
            tabBar.setCurrentViewController(self)
        }
    }
    
    func dismissViewControllerPressed() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}