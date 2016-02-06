//
//  ChartViewController.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/4/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit
import ANParseKit
import SDWebImage
import Alamofire
import ANCommonKit

class PublicListViewController: UIViewController {
    
    let FirstHeaderCellHeight: CGFloat = 108.0
    let HeaderCellHeight: CGFloat = 64.0
    
    var canFadeImages = true
    var showTableView = true

    var animator: ZFModalTransitionAnimator!
    
    var dataSource: [[Anime]] = [] {
        didSet {
            filteredDataSource = dataSource
        }
    }
    
    var filteredDataSource: [[Anime]] = [] {
        didSet {
            canFadeImages = false
            self.collectionView.reloadData()
            canFadeImages = true
        }
    }
    
    var chartsDataSource: [SeasonalChart] = [] {
        didSet {
            self.collectionView.reloadData()
        }
    }
    
    var loadingView: LoaderView!
    var userProfile: User!
    var sectionSubtitles: [String] = ["","","","","",""]
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var navigationBarTitle: UILabel!
    @IBOutlet weak var filterBar: UIView!
    
    func initWithUser(user: User) {
        userProfile = user
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AnimeCell.registerNibFor(collectionView: collectionView)
        
        collectionView.alpha = 0.0
        
        loadingView = LoaderView(parentView: view)
        
        title = "\(userProfile.aozoraUsername) Library"
        
        fetchUserLibrary()
        updateLayout(withSize: view.bounds.size)
    }
    
    deinit {
        for typeList in dataSource {
            for anime in typeList {
                anime.publicProgress = nil
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if loadingView.animating == false {
            loadingView.stopAnimating()
            collectionView.animateFadeIn()
        }
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        updateLayout(withSize: size)
        
    }
    
    func fetchUserLibrary() {
        
        let query = AnimeProgress.query()!
        query.includeKey("anime")
        query.whereKey("user", equalTo: userProfile)
        query.findAllObjectsInBackground()
            .continueWithExecutor(BFExecutor.mainThreadExecutor(), withBlock: { (task: BFTask!) -> AnyObject! in
        
            if var result = task.result as? [AnimeProgress] {

                result.sortInPlace({ (progress1: AnimeProgress, progress2: AnimeProgress) -> Bool in
                    if progress1.anime.type == progress2.anime.type {
                        return progress1.anime.title! < progress2.anime.title
                    } else {
                        return progress1.anime.type > progress2.anime.type
                    }
                })
                
                func assignPublicProgressAndReturnAnime(animeProgress: AnimeProgress) -> Anime {
                    let anime = animeProgress.anime
                    anime.publicProgress = animeProgress
                    return anime
                }
                
                let watching = result.filter({$0.list == "Watching"}).map(assignPublicProgressAndReturnAnime)
                let planning = result.filter({$0.list == "Planning"}).map(assignPublicProgressAndReturnAnime)
                let onHold = result.filter({$0.list == "On-Hold"}).map(assignPublicProgressAndReturnAnime)
                let completed = result.filter({$0.list == "Completed"}).map(assignPublicProgressAndReturnAnime)
                let dropped = result.filter({$0.list == "Dropped"}).map(assignPublicProgressAndReturnAnime)
                
                self.dataSource = [[],watching, planning, onHold, completed, dropped]
                
                var tvTotalCount = 0
                var moviesTotalCount = 0
                var restTotalCount = 0
                // Set stats
                for var i = 1 ; i < self.dataSource.count ; i++ {
                    let animeList = self.dataSource[i]
                    var tvCount = 0
                    var moviesCount = 0
                    var restCount = 0
                    for anime in animeList {
                        switch anime.type {
                        case "TV":
                            tvCount += 1
                        case "Movie":
                            moviesCount += 1
                        default:
                            restCount += 1
                        }
                    }
                    tvTotalCount += tvCount
                    moviesTotalCount += moviesCount
                    restTotalCount += restCount
                    self.sectionSubtitles[i] = "\(tvCount) TV · \(moviesCount) Movie · \(restCount) OVA/ONA/Specials"
                }
                self.sectionSubtitles[0] = "\(tvTotalCount) TV · \(moviesTotalCount) Movie · \(restTotalCount) OVA/ONA/Specials"
            }
            
            self.loadingView.stopAnimating()
            self.collectionView.animateFadeIn()
            return nil
        })
    }
    
    // MARK: - Utility Functions
    func updateLayout(withSize viewSize: CGSize) {
        
        guard let collectionView = collectionView,
            let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
                return
        }
        
        AnimeCell.updateLayoutItemSizeWithLayout(layout, viewSize: viewSize)
        
        canFadeImages = false
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.reloadData()
        canFadeImages = true
    }
    
    @IBAction func dismissViewControllerPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}

extension PublicListViewController: UICollectionViewDataSource {
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {

        return filteredDataSource.count
    }
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        return filteredDataSource[section].count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(AnimeCell.id, forIndexPath: indexPath) as! AnimeCell
        let anime = filteredDataSource[indexPath.section][indexPath.row]
        cell.configureWithAnime(anime, canFadeImages: canFadeImages, showEtaAsAired: false, publicAnime: true)
        cell.layoutIfNeeded()
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        
        var reusableView: UICollectionReusableView!
        
        if kind == UICollectionElementKindSectionHeader {
            
            let headerView = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withReuseIdentifier: "HeaderView", forIndexPath: indexPath) as! BasicCollectionReusableView
    
                var title = ""
                switch indexPath.section {
                case 0: title = "All Lists"
                case 1: title = "Watching"
                case 2: title = "Planning"
                case 3: title = "On-Hold"
                case 4: title = "Completed"
                case 5: title = "Dropped"
                default: break
                }
                
                headerView.titleLabel.text = title
                headerView.subtitleLabel.text = sectionSubtitles[indexPath.section]
            
            
            reusableView = headerView;
        }
        
        return reusableView
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        let height = (section == 0) ? FirstHeaderCellHeight : HeaderCellHeight
        return CGSize(width: view.bounds.size.width, height: height)
    }
    
}

extension PublicListViewController: UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        view.endEditing(true)
        
        let anime = filteredDataSource[indexPath.section][indexPath.row]
        animator = presentAnimeModal(anime)
    }
}


extension PublicListViewController: UISearchBarDelegate {
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        
        if searchBar.text == "" {
            filteredDataSource = dataSource
            return
        }
        
        filteredDataSource = dataSource.map { (var animeTypeArray) -> [Anime] in
            func filterText(anime: Anime) -> Bool {
                return (anime.title!.rangeOfString(searchBar.text!) != nil) ||
                    (anime.genres.joinWithSeparator(" ").rangeOfString(searchBar.text!) != nil)
                
            }
            return animeTypeArray.filter(filterText)
        }
        
    }
}

extension PublicListViewController: ModalTransitionScrollable {
    var transitionScrollView: UIScrollView? {
        return collectionView
    }
}