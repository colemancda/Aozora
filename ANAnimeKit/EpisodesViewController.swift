//
//  EpisodeViewController.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/24/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit
import ANCommonKit
import ANParseKit
import Bolts

extension EpisodesViewController: StatusBarVisibilityProtocol {
    func shouldHideStatusBar() -> Bool {
        return false
    }
    func updateCanHideStatusBar(canHide: Bool) {
    }
}

class EpisodesViewController: AnimeBaseViewController {
    
    var canFadeImages = true
    var laidOutSubviews = false
    var dataSource: [Episode] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    
    var loadingView: LoaderView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadingView = LoaderView(parentView: view)
        
        fetchEpisodes()
        
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        updateLayoutWithSize(size)
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !laidOutSubviews {
            laidOutSubviews = true
            updateLayoutWithSize(view.bounds.size)
        }
        
    }
    
    func updateLayoutWithSize(viewSize: CGSize) {
        
        let height: CGFloat = 195
        
        guard let collectionView = collectionView,
            let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
                return
        }
        
        var size: CGSize?
        var inset: CGFloat = 0
        var lineSpacing: CGFloat = 0
        
        if UIDevice.isPad() {
            inset = 4
            lineSpacing = 4
            let columns: CGFloat = UIDevice.isLandscape() ? 3 : 2
            let totalWidth: CGFloat = viewSize.width - (inset * (columns + 1))
            size = CGSize(width: totalWidth / columns, height: height)
        } else {
            inset = 10
            lineSpacing = 10
            size = CGSize(width: viewSize.width - inset * 2, height: height)
        }
        layout.sectionInset = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        layout.minimumLineSpacing = lineSpacing
        layout.minimumInteritemSpacing = lineSpacing
        
        layout.itemSize = size!
        layout.invalidateLayout()
    }
    
    func fetchEpisodes() {
        
        loadingView.startAnimating()

        anime.episodeList().continueWithExecutor(BFExecutor.mainThreadExecutor(), withSuccessBlock: { (task: BFTask!) -> AnyObject! in
        
            self.dataSource = task.result as! [Episode]
            self.collectionView.animateFadeIn()
            self.loadingView.stopAnimating()

            return nil
        })
    }
    
    // MARK: - IBActions
    
    @IBAction func goToPressed(sender: UIBarButtonItem) {
        
        let dataSource = [["First Episode", "Next Episode", "Last Episode"]]
        
        DropDownListViewController.showDropDownListWith(sender: navigationController!.navigationBar, viewController: self, delegate: self, dataSource: dataSource)
        
    }
}


extension EpisodesViewController: UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("EpisodeCell", forIndexPath: indexPath) as! EpisodeCell
        
        let episode = dataSource[indexPath.row]

        cell.delegate = self

        var watchStatus: EpisodeCell.WatchStatus = .Disabled

        if let progress = anime.progress {
            if progress.watchedEpisodes < indexPath.row + 1 {
                watchStatus = .NotWatched
            } else {
                watchStatus = .Watched
            }
        }

        cell.configureCellWithEpisode(episode, watchStatus: watchStatus)

        return cell
    }

}

extension EpisodesViewController: UICollectionViewDelegate {
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let episode = dataSource[indexPath.row]
        let threadController = ANAnimeKit.customThreadViewController()
        threadController.initWithEpisode(episode, anime: anime)
        if InAppController.hasAnyPro() == nil {
            threadController.interstitialPresentationPolicy = .Automatic
        }
        
        if let tabBar = tabBarController as? CustomTabBarController {
            tabBar.disableDragDismiss()
        }
        
        navigationController?.pushViewController(threadController, animated: true)
    }
}

extension EpisodesViewController: EpisodeCellDelegate {
    func episodeCellWatchedPressed(cell: EpisodeCell) {
        if let indexPath = collectionView.indexPathForCell(cell),
        let progress = anime.progress {
            
            let nextEpisode = indexPath.row + 1
            if progress.watchedEpisodes == nextEpisode {
                progress.watchedEpisodes = nextEpisode - 1
            } else {
                progress.watchedEpisodes = nextEpisode
            }
            
            progress.updatedEpisodes(anime.episodes)
            
            if progress.myAnimeListList() == .Completed {
                RateViewController.showRateDialogWith(self.tabBarController!, title: "You've finished\n\(anime.title!)!\ngive it a rating", initialRating: Float(progress.score)/2.0, anime: anime, delegate: self)
            }
            
            progress.saveInBackground()
            LibrarySyncController.updateAnime(progress)
            
            NSNotificationCenter.defaultCenter().postNotificationName(LibraryUpdatedNotification, object: nil)
            
            canFadeImages = false
            let indexPaths = collectionView.indexPathsForVisibleItems()
            collectionView.reloadItemsAtIndexPaths(indexPaths)
            canFadeImages = true
        }
        
    }
    func episodeCellMorePressed(cell: EpisodeCell) {
        let indexPath = collectionView.indexPathForCell(cell)!
        let episode = dataSource[indexPath.row]
        var textToShare = ""
            
        if anime.episodes == indexPath.row + 1 {
            textToShare = "Finished watching \(anime.title!) via #AozoraApp"
        } else {
            textToShare = "Just watched \(anime.title!) ep \(episode.number) via #AozoraApp"
        }
        
        var objectsToShare: [AnyObject] = [textToShare]
        if let image = cell.screenshotImageView.image {
            objectsToShare.append( image )
        }
        
        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        activityVC.excludedActivityTypes = [UIActivityTypeAssignToContact, UIActivityTypeCopyToPasteboard, UIActivityTypeAddToReadingList,UIActivityTypePrint];
        self.presentViewController(activityVC, animated: true, completion: nil)
    
    }
}

extension EpisodesViewController: DropDownListDelegate {
    func selectedAction(trigger: UIView, action: String, indexPath: NSIndexPath) {
        if dataSource.isEmpty {
            return
        }
        
        switch indexPath.row {
        case 0:
            // Go to top
            self.collectionView.scrollToItemAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: UICollectionViewScrollPosition.Top, animated: true)
        case 1:
            // Go to next episode
            if let nextEpisode = anime.nextEpisode where nextEpisode > 0 {
                self.collectionView.scrollToItemAtIndexPath(NSIndexPath(forRow: nextEpisode - 1, inSection: 0), atScrollPosition: UICollectionViewScrollPosition.CenteredVertically, animated: true)
            }
        case 2:
            // Go to bottom
            self.collectionView.scrollToItemAtIndexPath(NSIndexPath(forRow: dataSource.count - 1, inSection: 0), atScrollPosition: UICollectionViewScrollPosition.Bottom, animated: true)
        default:
            break
        }
    }
    
    func dropDownDidDismissed(selectedAction: Bool) {
        
    }
}

extension EpisodesViewController: RateViewControllerProtocol {
    func rateControllerDidFinishedWith(anime anime: Anime, rating: Float) {
        RateViewController.updateAnime(anime, withRating: rating*2.0)
    }
}