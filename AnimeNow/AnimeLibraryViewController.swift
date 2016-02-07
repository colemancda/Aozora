//
//  AnimeLibraryViewController.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/21/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit
import ANCommonKit
import ANParseKit
import XLPagerTabStrip

enum AnimeList: String {
    case Planning = "Planning"
    case Watching = "Watching"
    case Completed = "Completed"
    case OnHold = "On-Hold"
    case Dropped = "Dropped"
}

enum LibraryLayout: String {
    case CheckIn = "Check-In"
    case Compact = "Compact"
    
    static func allRawValues() -> [String] {
        return [
            LibraryLayout.CheckIn.rawValue,
            LibraryLayout.Compact.rawValue
        ]
    }
}

class AnimeLibraryViewController: XLButtonBarPagerTabStripViewController {
    
    let SortTypeDefault = "Library.SortType."
    let LayoutTypeDefault = "Library.LayoutType."
    
    var allAnimeLists: [AnimeList] = [.Watching, .Planning, .OnHold, .Completed, .Dropped]
    var listControllers: [AnimeListViewController] = []
    
    var loadingView: LoaderView!
    var libraryController = LibraryController.sharedInstance
    var animator: ZFModalTransitionAnimator!
    
    var currentConfiguration: Configuration {
        get {
            return configurations[Int(currentIndex)]
        }
        
        set (value) {
            configurations[Int(currentIndex)] = value
        }
    }
    var configurations: [Configuration] = []
    
    func sortTypeForList(list: AnimeList) -> SortType {
        let key = SortTypeDefault+list.rawValue
        if let sortType = NSUserDefaults.standardUserDefaults().objectForKey(key) as? String, let sortTypeEnum = SortType(rawValue: sortType) {
            return sortTypeEnum
        } else {
            return SortType.Title
        }
    }
    
    func setSortTypeForList(sort:SortType, list: AnimeList) {
        let key = SortTypeDefault+list.rawValue
        NSUserDefaults.standardUserDefaults().setObject(sort.rawValue, forKey: key)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func layoutTypeForList(list: AnimeList) -> LibraryLayout {
        let key = LayoutTypeDefault+list.rawValue
        if let layoutType = NSUserDefaults.standardUserDefaults().objectForKey(key) as? String, let layoutTypeEnum = LibraryLayout(rawValue: layoutType) {
            return layoutTypeEnum
        } else {
            return LibraryLayout.CheckIn
        }

    }
    
    func setLayoutTypeForList(layout:LibraryLayout, list: AnimeList) {
        let key = LayoutTypeDefault+list.rawValue
        NSUserDefaults.standardUserDefaults().setObject(layout.rawValue, forKey: key)
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()

        canDisplayBannerAds = InAppController.canDisplayAds()

        self.isProgressiveIndicator = true
        self.buttonBarView.selectedBar.backgroundColor = UIColor.watching()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateLibrary", name: LibraryUpdatedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "controllerRequestRefresh", name: LibraryCreatedNotification, object: nil)
     
        loadingView = LoaderView(parentView: view)
        
        libraryController.delegate = self
        loadingView.startAnimating()
        if let library = libraryController.library {
            updateListViewControllers(library)
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func updateLibrary() {
        fetchAnimeList(false)
    }
    
    func fetchAnimeList(isRefreshing: Bool) -> BFTask {
        
        if libraryController.currentlySyncing {
            return BFTask(result: nil)
        }
        
        if !isRefreshing {
            loadingView.startAnimating()
        }
        
        return libraryController.fetchAnimeList(isRefreshing).continueWithExecutor(BFExecutor.mainThreadExecutor(), withBlock: { (task: BFTask!) -> AnyObject? in
            
            if let library = task.result as? [Anime] {
                self.updateListViewControllers(library)
            }
            
            return nil
        })
    }
    
    func updateListViewControllers(animeList: [Anime]) {
        
        var lists: [[Anime]] = [[],[],[],[],[]]
        
        for anime in animeList {
            if let progress = anime.progress {
                switch progress.myAnimeListList() {
                case .Watching:
                    lists[0].append(anime)
                case .Planning:
                    lists[1].append(anime)
                case .OnHold:
                    lists[2].append(anime)
                case .Completed:
                    lists[3].append(anime)
                case .Dropped:
                    lists[4].append(anime)
                }
            }
        }
        
        for index in 0...4 {
            let aList = lists[index]
            if aList.count > 0 {
                let controller = self.listControllers[index]
                controller.animeList = aList
                controller.updateSortType(controller.currentSortType)
            }
        }
        
        loadingView.stopAnimating()
    }
    
    
    
    // MARK: - XLPagerTabStripViewControllerDataSource
    
    override func childViewControllersForPagerTabStripViewController(pagerTabStripViewController: XLPagerTabStripViewController!) -> [AnyObject]! {
        
        // Initialize configurations
        for list in allAnimeLists {
            configurations.append(
                [
                    (FilterSection.View, layoutTypeForList(list).rawValue, LibraryLayout.allRawValues()),
                    (FilterSection.Sort, sortTypeForList(list).rawValue, [SortType.Title.rawValue, SortType.NextEpisodeToWatch.rawValue, SortType.NextAiringEpisode.rawValue, SortType.MyRating.rawValue, SortType.Rating.rawValue, SortType.Popularity.rawValue, SortType.Newest.rawValue, SortType.Oldest.rawValue]),
                ]
            )
        }
        
        // Initialize controllers
        let storyboard = UIStoryboard(name: "Library", bundle: nil)
        
        var lists: [AnimeListViewController] = []
        
        for index in 0...4 {
            if let controller = storyboard.instantiateViewControllerWithIdentifier("AnimeList") as? AnimeListViewController {
                let animeList = allAnimeLists[index]
                
                controller.initWithList(animeList, configuration: configurations[index])
                controller.delegate = self
                
                lists.append(controller)
            }
        }
        
        listControllers = lists
        
        return lists
    }
    
    // MARK: - XLPagerTabStripViewControllerDelegate
    
    override func pagerTabStripViewController(pagerTabStripViewController: XLPagerTabStripViewController!, updateIndicatorFromIndex fromIndex: Int, toIndex: Int, withProgressPercentage progressPercentage: CGFloat) {
        super.pagerTabStripViewController(pagerTabStripViewController, updateIndicatorFromIndex: fromIndex, toIndex: toIndex, withProgressPercentage: progressPercentage)
        
        if progressPercentage > 0.5 {
            self.buttonBarView.selectedBar.backgroundColor = colorForIndex(toIndex)
        } else {
            self.buttonBarView.selectedBar.backgroundColor = colorForIndex(fromIndex)
        }
    }
    
    func colorForIndex(index: Int) -> UIColor {
        var color: UIColor?
        switch index {
        case 0:
            color = UIColor.watching()
        case 1:
            color = UIColor.planning()
        case 2:
            color = UIColor.onHold()
        case 3:
            color = UIColor.completed()
        case 4:
            color = UIColor.dropped()
        default: break
        }
        return color ?? UIColor.completed()
    }
    
    // MARK: - IBActions
    
    @IBAction func presentSearchPressed(sender: AnyObject) {
        
        if let tabBar = tabBarController {
            tabBar.presentSearchViewController(.MyLibrary)
        }
    }
    
    @IBAction func showFilterPressed(sender: AnyObject) {
        
        if let tabBar = tabBarController,
            let controller = UIStoryboard(name: "Browse", bundle: nil).instantiateViewControllerWithIdentifier("Filter") as? FilterViewController {
            
            controller.delegate = self
            controller.initWith(configuration: currentConfiguration)
            animator = tabBar.presentViewControllerModal(controller)
        }
    }
}


extension AnimeLibraryViewController: FilterViewControllerDelegate {
    func finishedWith(configuration configuration: Configuration, selectedGenres: [String]) {

        let currentListIndex = Int(currentIndex)
        currentConfiguration = configuration
        listControllers[currentListIndex].currentConfiguration = currentConfiguration
        
        if let value = currentConfiguration[0].value,
            let layoutType = LibraryLayout(rawValue: value) {
                setLayoutTypeForList(layoutType, list: allAnimeLists[currentListIndex])
        }
        
        if let value = currentConfiguration[1].value,
            let sortType = SortType(rawValue: value) {
                setSortTypeForList(sortType, list: allAnimeLists[currentListIndex])
        }
        
    }
}

extension AnimeLibraryViewController: AnimeListControllerDelegate {
    func controllerRequestRefresh() -> BFTask {
        return fetchAnimeList(true)
    }
}

extension AnimeLibraryViewController: LibraryControllerDelegate {
    func libraryControllerFinishedFetchingLibrary(library: [Anime]) {
        updateListViewControllers(library)
    }
}