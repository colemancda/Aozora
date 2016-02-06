//
//  SearchViewController.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/25/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit
import ANParseKit
import ANCommonKit
import Bolts

enum SearchScope: Int {
    case AllAnime = 0
    case MyLibrary
    case Users
    case Forum
}

class SearchViewController: UIViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var loadingView: LoaderView!
    var animator: ZFModalTransitionAnimator!
    var dataSource: [PFObject] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    var emptyDataSource: [[AnyObject]] = [[],[],[],[]]

    var currentOperation = NSOperation()
    var initialSearchScope: SearchScope!
    
    func initWithSearchScope(searchScope: SearchScope) {
        initialSearchScope = searchScope
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AnimeCell.registerNibFor(collectionView: collectionView)
        
        guard let collectionView = collectionView,
            let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
                return
        }
        layout.itemSize = CGSize(width: view.bounds.size.width, height: 132)
        
        loadingView = LoaderView(parentView: view)
        
        searchBar.placeholder = "Enter your search"
        searchBar.becomeFirstResponder()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateETACells", name: LibraryUpdatedNotification, object: nil)
        
        var allBrowseTypes = BrowseType.allItems()
        allBrowseTypes.append(BrowseType.Filtering.rawValue)
        emptyDataSource[0] = allBrowseTypes
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    func updateETACells() {
        let indexPaths = collectionView.indexPathsForVisibleItems()
        collectionView.reloadItemsAtIndexPaths(indexPaths)
    }
    
    func fetchDataWithQuery(text: String, searchScope: SearchScope) {
        
        if searchScope == .MyLibrary {
            
            guard let library = LibraryController.sharedInstance.library else {
                return
            }
            self.dataSource = library.filter({ anime in
                
                if anime.progress == nil {
                    return false
                }
                if let title = anime.title where title.lowercaseString.rangeOfString(text.lowercaseString) != nil {
                    return true
                }
                if let titleEnglish = anime.titleEnglish where titleEnglish.lowercaseString.rangeOfString(text.lowercaseString) != nil {
                    return true
                }
                return false
            })            
            return
        }
        
        
        loadingView.startAnimating()
        collectionView.animateFadeOut()
        
        var query: PFQuery!
        
        switch searchScope {
        case .AllAnime:
            let query1 = Anime.query()!
            query1.whereKey("title", matchesRegex: text, modifiers: "i")
            
            let query2 = Anime.query()!
            query2.whereKey("titleEnglish", matchesRegex: text, modifiers: "i")
            
            let orQuery = PFQuery.orQueryWithSubqueries([query1, query2])
            orQuery.limit = 40
            orQuery.orderByAscending("popularityRank")
            
            query = orQuery
            
        case .Users:
            query = User.query()!
            query.limit = 40
            query.whereKey("aozoraUsername", matchesRegex: text, modifiers: "i")
            query.orderByAscending("aozoraUsername")
            
        case .Forum:
            query = Thread.query()!
            query.limit = 40
            query.whereKey("title", matchesRegex: text, modifiers: "i")
            query.includeKey("tags")
            query.includeKey("startedBy")
            query.includeKey("lastPostedBy")
            query.orderByAscending("updatedAt")
        default:
            break
        }
        
        currentOperation.cancel()
        let newOperation = NSOperation()
        
        dispatch_after_delay(0.6, queue: dispatch_get_main_queue()) { _ in
            
            if newOperation.cancelled == true {
                return
            }
            
            query.findObjectsInBackgroundWithBlock({ (result, error) -> Void in
                print("fetched! \(text)")
                if result != nil {
                    if let anime = result as? [Anime] {
                        LibrarySyncController.matchAnimeWithProgress(anime)
                        self.dataSource = anime
                    } else if let users = result as? [User] {
                        self.dataSource = users
                    } else if let threads = result as? [Thread] {
                        self.dataSource = threads
                    }
                }
                
                self.loadingView.stopAnimating()
                self.collectionView.animateFadeIn()
            })
        }
        
        currentOperation = newOperation
    }
    
    func dispatch_after_delay(delay: NSTimeInterval, queue: dispatch_queue_t, block: dispatch_block_t) {
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
        dispatch_after(time, queue, block)
    }
}

extension SearchViewController: UICollectionViewDataSource {
    
    func objectAtIndex(indexPath: NSIndexPath) -> AnyObject {
        return dataSource.count > 0 ? dataSource[indexPath.row] : emptyDataSource[searchBar.selectedScopeButtonIndex][indexPath.row]
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count > 0 ? dataSource.count : emptyDataSource[searchBar.selectedScopeButtonIndex].count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let object = objectAtIndex(indexPath)
        
        if let anime = object as? Anime {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(AnimeCell.id, forIndexPath: indexPath) as! AnimeCell
            cell.configureWithAnime(anime)
            return cell
            
        } else if let profile = object as? User {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("UserCell", forIndexPath: indexPath) as! BasicCollectionCell
            if let avatarFile = profile.avatarThumb {
                cell.titleimageView.setImageWithPFFile(avatarFile)
            }
            cell.titleLabel.text = profile.aozoraUsername
            cell.layoutIfNeeded()
            return cell
            
        } else if let thread = object as? Thread {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ThreadCell", forIndexPath: indexPath) as! BasicCollectionCell
            cell.titleLabel.text = thread.title
            cell.layoutIfNeeded()
            return cell
        } else if let string = object as? String {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ThreadCell", forIndexPath: indexPath) as! BasicCollectionCell
            cell.titleLabel.text = string
            cell.layoutIfNeeded()
            return cell
        }
        
        return UICollectionViewCell()
    }
}

extension SearchViewController: UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let object = objectAtIndex(indexPath)
        
        if let anime = object as? Anime {
            self.animator = presentAnimeModal(anime)
        } else if let user = object as? User {
            let profileController = ANAnimeKit.profileViewController()
            profileController.initWithUser(user)
            navigationController?.pushViewController(profileController, animated: true)
        } else if let thread = object as? Thread {
            let threadController = ANAnimeKit.customThreadViewController()
            
            if let episode = thread.episode, let anime = thread.anime {
                threadController.initWithEpisode(episode, anime: anime)
            } else {
                threadController.initWithThread(thread)
            }
            
            if InAppController.hasAnyPro() == nil {
                threadController.interstitialPresentationPolicy = .Automatic
            }
            navigationController?.pushViewController(threadController, animated: true)
        } else if let string = object as? String {
            guard let browse = UIStoryboard(name: "Browse", bundle: nil).instantiateViewControllerWithIdentifier("Browse") as? BrowseViewController,
                let browseType = BrowseType(rawValue: string) else {
                return
            }
            browse.currentBrowseType = browseType
            navigationController?.pushViewController(browse, animated: true)
        }
    }
}

extension SearchViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let object = objectAtIndex(indexPath)
        
        if let _ = object as? Anime {
            return CGSize(width: view.bounds.size.width, height: 132)
        } else if let _ = object as? User {
            return CGSize(width: view.bounds.size.width, height: 44)
        } else if let _ = object as? Thread {
            return CGSize(width: view.bounds.size.width, height: 44)
        } else if let _ = object as? String {
            return CGSize(width: view.bounds.size.width, height: 44)
        }
        
        return CGSizeZero
    }
}

extension SearchViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        startNewFetch()
        view.endEditing(true)
        searchBar.enableCancelButton()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        startNewFetch()
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func searchBar(searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        startNewFetch()
        collectionView.reloadData()
    }
    
    func startNewFetch() {
        
        guard let query = searchBar.text,
            let searchScope = SearchScope(rawValue: searchBar.selectedScopeButtonIndex) where query.characters.count > 0 else {
            return
        }
        
        fetchDataWithQuery(query, searchScope: searchScope)
    }
}

extension SearchViewController: UINavigationBarDelegate {
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.TopAttached
    }
}

extension SearchViewController: ModalTransitionScrollable {
    var transitionScrollView: UIScrollView? {
        return collectionView
    }
}