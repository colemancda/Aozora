//
//  DayViewController.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 7/4/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit
import ANParseKit
import SDWebImage
import Alamofire
import ANCommonKit
import XLPagerTabStrip

class DayViewController: UIViewController {
    
    var animator: ZFModalTransitionAnimator!
    var dayString: String = ""
    var dataSource: [Anime] = []
    var section: Int = 0
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    func initWithTitle(title: String, section: Int) {
        dayString = title
        self.section = section
    }

    func updateDataSource(dataSource: [Anime]) {
        
        self.dataSource = dataSource
        self.sort()
        if self.isViewLoaded() {
            self.collectionView.reloadData()
            self.collectionView.animateFadeIn()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AnimeCell.registerNibFor(collectionView: collectionView)
        
        updateLayout(withSize: view.bounds.size)
    }
    
    
    
    // MARK: - Utility Functions
    
    func sort() {
    
        dataSource.sortInPlace({ (anime1: Anime, anime2: Anime) in
            
            let startDate1 = anime1.nextEpisodeDate ?? NSDate(timeIntervalSinceNow: 60*60*24*100)
            let startDate2 = anime2.nextEpisodeDate ?? NSDate(timeIntervalSinceNow: 60*60*24*100)
            return startDate1.compare(startDate2) == .OrderedAscending
        })
    }
    
    func updateLayout(withSize viewSize: CGSize) {
        
        guard let collectionView = collectionView,
            let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }
        
        AnimeCell.updateLayoutItemSizeWithLayout(layout, viewSize: viewSize)
    }
    
}


extension DayViewController: UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(AnimeCell.id, forIndexPath: indexPath) as! AnimeCell
        
        let anime = dataSource[indexPath.row]

        let nextDate = anime.nextEpisodeDate ?? NSDate(timeIntervalSinceNow: 60*60*24*100)
        let showEtaAsAired = nextDate.timeIntervalSinceNow > 60*60*24 && section == 0
        
        cell.configureWithAnime(anime, canFadeImages: true, showEtaAsAired: showEtaAsAired)
        cell.layoutIfNeeded()
        return cell
    }
    

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.bounds.size.width, height: 0.0)
    }
    
}

extension DayViewController: UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let anime = dataSource[indexPath.row]
        animator = presentAnimeModal(anime)
    }
}

extension DayViewController: LibraryAnimeCellDelegate {
    func cellPressedWatched(cell: LibraryAnimeCell, anime: Anime) {
        if let _ = anime.progress,
            let indexPath = collectionView.indexPathForCell(cell) {
            
            collectionView.reloadItemsAtIndexPaths([indexPath])
        }
    }
    
    func cellPressedEpisodeThread(cell: LibraryAnimeCell, anime: Anime, episode: Episode) {
        let threadController = ANAnimeKit.customThreadViewController()
        threadController.initWithEpisode(episode, anime: anime)
        
        if InAppController.hasAnyPro() == nil {
            threadController.interstitialPresentationPolicy = .Automatic
        }
        
        navigationController?.pushViewController(threadController, animated: true)
    }
}

extension DayViewController: XLPagerTabStripChildItem {
    func titleForPagerTabStripViewController(pagerTabStripViewController: XLPagerTabStripViewController!) -> String! {
        return dayString
    }
    
    func colorForPagerTabStripViewController(pagerTabStripViewController: XLPagerTabStripViewController!) -> UIColor! {
        return UIColor.whiteColor()
    }
}