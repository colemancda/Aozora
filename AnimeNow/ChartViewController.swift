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

class ChartViewController: UIViewController {
    
    enum SelectedList: Int {
        case SeasonalChart = 0
        case AllSeasons
    }
    
    let SortTypeDefault = "Season.SortType"
    let LayoutTypeDefault = "Season.LayoutType"
    let FirstHeaderCellHeight: CGFloat = 88.0
    let HeaderCellHeight: CGFloat = 44.0
    
    var canFadeImages = true
    var showTableView = true
    
    var currentSeasonalChartName = SeasonalChartService.seasonalChartString(0).title
    
    var currentConfiguration: Configuration!
    
    var orders: [SortType] = []
    var viewTypes: [LayoutType] = []
    var selectedList: SelectedList = .SeasonalChart {
        didSet {
            filterBar.hidden = selectedList == .AllSeasons
        }
    }
    
    
    var timer: NSTimer!
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
    
    var currentSortType: SortType {
        get {
            guard let sortType = NSUserDefaults.standardUserDefaults().objectForKey(SortTypeDefault) as? String,
                let sortTypeEnum = SortType(rawValue: sortType) else {
                return SortType.Popularity
            }
            return sortTypeEnum
        }
        set ( value ) {
            NSUserDefaults.standardUserDefaults().setObject(value.rawValue, forKey: SortTypeDefault)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    var currentLayoutType: LayoutType {
        get {
            guard let layoutType = NSUserDefaults.standardUserDefaults().objectForKey(LayoutTypeDefault) as? String,
                let layoutTypeEnum = LayoutType(rawValue: layoutType) else {
                return LayoutType.Chart
            }
            return layoutTypeEnum
        }
        set ( value ) {
            NSUserDefaults.standardUserDefaults().setObject(value.rawValue, forKey: LayoutTypeDefault)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    var loadingView: LoaderView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var navigationBarTitle: UILabel!
    @IBOutlet weak var filterBar: UIView!
    @IBOutlet weak var navigationItemView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DialogController.sharedInstance.canShowFBAppInvite(self)
        
        AnimeCell.registerNibFor(collectionView: collectionView)
        
        // Layout and sort
        orders = [currentSortType, .None]
        viewTypes = [currentLayoutType, .SeasonalChart]
        
        // Update configuration
        currentConfiguration = [
            (FilterSection.View, currentLayoutType.rawValue, [LayoutType.Chart.rawValue]),
            (FilterSection.Sort, currentSortType.rawValue, [SortType.Rating.rawValue, SortType.Popularity.rawValue, SortType.Title.rawValue, SortType.NextAiringEpisode.rawValue])
        ]
        
        collectionView.alpha = 0.0
        
        timer = NSTimer.scheduledTimerWithTimeInterval(60.0, target: self, selector: "updateETACells", userInfo: nil, repeats: true)
        
        loadingView = LoaderView(parentView: view)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "changeSeasonalChart")
        navigationItemView.addGestureRecognizer(tapGestureRecognizer)
        
        prepareForList(selectedList)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateETACells", name: LibraryUpdatedNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
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
        
        if selectedList == .AllSeasons {
            updateLayoutType(.SeasonalChart, withSize: size)
        } else {
            updateLayoutType(currentLayoutType, withSize: size)
        }
    }
    
    // MARK: - UI Functions
    
    func updateETACells() {
        canFadeImages = false
        let indexPaths = collectionView.indexPathsForVisibleItems()
        collectionView.reloadItemsAtIndexPaths(indexPaths)
        canFadeImages = true
    }
    
    func prepareForList(selectedList: SelectedList) {
        
        self.selectedList = selectedList
        
        switch selectedList {
        case .SeasonalChart:
            collectionView.animateFadeOut()
            loadingView.startAnimating()
            navigationBarTitle.text = currentSeasonalChartName
            fetchSeasonalChart(currentSeasonalChartName)
        case .AllSeasons:
            navigationBarTitle.text = "All Seasons"
            collectionView.reloadData()
        }
        
        navigationBarTitle.text! += " " + FontAwesome.AngleDown.rawValue
        
        if selectedList == SelectedList.AllSeasons {
            updateLayoutType(.SeasonalChart, withSize: view.bounds.size)
        } else {
            updateLayoutType(currentLayoutType, withSize: view.bounds.size)
        }
    }
    
    func fetchAllSeasons() -> BFTask {
        return ChartController.fetchAllSeasons()
    }
    
    func fetchSeasonalChart(seasonalChart: String) {
        
        let startDate = NSDate()
        var seasonsTask: BFTask!
        
        if chartsDataSource.isEmpty {
            seasonsTask = fetchAllSeasons().continueWithSuccessBlock { (task: BFTask!) -> AnyObject! in
                
                let result = task.result as! [SeasonalChart]
                self.chartsDataSource = result
                let selectedSeasonalChart = result.filter({$0.title == seasonalChart})
                return BFTask(result: selectedSeasonalChart)
            }
        } else {
            let selectedSeasonalChart = chartsDataSource.filter({$0.title == seasonalChart})
            seasonsTask = BFTask(result: selectedSeasonalChart)
        }
        
        seasonsTask.continueWithSuccessBlock { (task: BFTask!) -> AnyObject! in
            
            guard let result = task.result as? [SeasonalChart], let selectedSeason = result.last else {
                return nil
            }
            return ChartController.fetchSeasonalChartAnime(selectedSeason)
        
        }.continueWithSuccessBlock { (task: BFTask!) -> AnyObject! in
            
            guard let result = task.result as? [Anime] else {
                return nil
            }
            LibrarySyncController.matchAnimeWithProgress(result)
            return BFTask(result: result)
            
        }.continueWithExecutor(BFExecutor.mainThreadExecutor(), withBlock: { (task: BFTask!) -> AnyObject! in
        
            print("Load seasons = \(NSDate().timeIntervalSinceDate(startDate))s")
            if let result = task.result as? [Anime] {
                let tvAnime = result.filter({$0.type == "TV"})
                let tv = tvAnime.filter({$0.duration == 0 || $0.duration > 15})
                let tvShort = tvAnime.filter({$0.duration > 0 && $0.duration <= 15})
                let movieAnime = result.filter({$0.type == "Movie"})
                let ovaAnime = result.filter({$0.type == "OVA"})
                let onaAnime = result.filter({$0.type == "ONA"})
                let specialAnime = result.filter({$0.type == "Special"})
                
                self.dataSource = [tv, tvShort, movieAnime, ovaAnime, onaAnime, specialAnime]
                self.updateSortType(self.currentSortType)
            }
            
            self.loadingView.stopAnimating()
            self.collectionView.animateFadeIn()
            return nil
        })
    }
    
    
    
    // MARK: - Utility Functions
    
    func updateSortType(sortType: SortType) {
        
        currentSortType = sortType
        
        dataSource = dataSource.map() { (var animeArray) -> [Anime] in
            switch self.currentSortType {
            case .Rating:
                animeArray.sortInPlace({ $0.rank < $1.rank && $0.rank != 0 })
            case .Popularity:
                animeArray.sortInPlace({ $0.popularityRank < $1.popularityRank})
            case .Title:
                animeArray.sortInPlace({ $0.title < $1.title})
            case .NextAiringEpisode:
                animeArray.sortInPlace({ (anime1: Anime, anime2: Anime) in
                    
                    let startDate1 = anime1.nextEpisodeDate ?? NSDate(timeIntervalSinceNow: 60*60*24*100)
                    let startDate2 = anime2.nextEpisodeDate ?? NSDate(timeIntervalSinceNow: 60*60*24*100)
                    return startDate1.compare(startDate2) == .OrderedAscending
                })
            default:
                break;
            }
            return animeArray
        }
        
        // Filter
        searchBar(searchBar, textDidChange: searchBar.text!)
    }
    
    func updateLayoutType(layoutType: LayoutType, withSize viewSize: CGSize) {
        
        if selectedList != SelectedList.AllSeasons {
            currentLayoutType = layoutType
        }
        
        guard let collectionView = collectionView,
            let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
                return
        }
        
        switch layoutType {
        case .Chart:
            AnimeCell.updateLayoutItemSizeWithLayout(layout, viewSize: viewSize)
        case .SeasonalChart:
            let lineSpacing: CGFloat = 1
            let columns: CGFloat = UIDevice.isLandscape() ? 3 : 2
            let cellHeight: CGFloat = 36
            var cellWidth: CGFloat = 0
            layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            layout.minimumLineSpacing = CGFloat(lineSpacing)
            
            if UIDevice.isPad() {
                cellWidth = viewSize.width / columns - columns * lineSpacing
            } else {
                cellWidth = viewSize.width
            }
            layout.itemSize = CGSize(width: cellWidth, height: cellHeight)
        }
        
        canFadeImages = false
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.reloadData()
        canFadeImages = true
    }
    
    // MARK: - IBActions
    
    @IBAction func showFilterPressed(sender: AnyObject) {
        
        if let tabBar = tabBarController {
            let controller = UIStoryboard(name: "Browse", bundle: nil).instantiateViewControllerWithIdentifier("Filter") as! FilterViewController
            
            controller.delegate = self
            controller.initWith(configuration: currentConfiguration)
            animator = tabBar.presentViewControllerModal(controller)
        }
        
    }
    
    func changeSeasonalChart() {
        if let sender = navigationController?.navigationBar,
        let viewController = tabBarController {
            
            var titlesDataSource: [String] = []
            var iconsDataSource: [String] = []
            
            for index in -1...2 {
                let (iconName, title) = SeasonalChartService.seasonalChartString(index)
                titlesDataSource.append(title)
                iconsDataSource.append(iconName)
            }
            
            let dataSource = [titlesDataSource,["All Seasons"]]
            let imageDataSource = [iconsDataSource,["icon-archived"]]
            
            DropDownListViewController.showDropDownListWith(sender: sender, viewController: viewController, delegate: self, dataSource: dataSource, imageDataSource: imageDataSource)
        }
    }
    
    @IBAction func showCalendarPressed(sender: AnyObject) {
        
        if let _ = InAppController.hasAnyPro() {
            
            let controller = UIStoryboard(name: "Season", bundle: nil).instantiateViewControllerWithIdentifier("Calendar") as! CalendarViewController
            presentViewController(controller, animated: true, completion: nil)
            
        } else {
            InAppPurchaseViewController.showInAppPurchaseWith(self)
        }
        
    }
}

extension ChartViewController: UICollectionViewDataSource {
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        if selectedList == SelectedList.AllSeasons {
            return 1
        } else {
            return filteredDataSource.count
        }
        
    }
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if selectedList == SelectedList.AllSeasons {
            return chartsDataSource.count
        } else {
            return filteredDataSource[section].count
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        guard selectedList != SelectedList.AllSeasons else {
            let reuseIdentifier = "SeasonCell";
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! BasicCollectionCell
            let seasonalChart = chartsDataSource[indexPath.row]
            cell.titleLabel.text = seasonalChart.title
            cell.layoutIfNeeded()
            return cell
        }
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(AnimeCell.id, forIndexPath: indexPath) as! AnimeCell
        let anime = filteredDataSource[indexPath.section][indexPath.row]
        cell.configureWithAnime(anime, canFadeImages: canFadeImages, showEtaAsAired: false)
        cell.layoutIfNeeded()
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        
        var reusableView: UICollectionReusableView!
        
        if kind == UICollectionElementKindSectionHeader {
            
            let headerView = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withReuseIdentifier: "HeaderView", forIndexPath: indexPath) as! BasicCollectionReusableView
    
                var title = ""
                switch indexPath.section {
                case 0: title = "TV"
                case 1: title = "TV Short"
                case 2: title = "Movie"
                case 3: title = "OVA"
                case 4: title = "ONA"
                case 5: title = "Special"
                default: break
                }
                
                headerView.titleLabel.text = title
            
            
            reusableView = headerView;
        }
        
        return reusableView
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        if filteredDataSource[section].count == 0
            || selectedList == SelectedList.AllSeasons {
                return CGSizeZero
        } else {
            let height = (section == 0) ? FirstHeaderCellHeight : HeaderCellHeight
            return CGSize(width: view.bounds.size.width, height: height)
        }
    }
    
}

extension ChartViewController: UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        view.endEditing(true)
        
        if selectedList != SelectedList.AllSeasons {
            let anime = filteredDataSource[indexPath.section][indexPath.row]
            animator = presentAnimeModal(anime)
        }
        
        if selectedList == SelectedList.AllSeasons {
            let seasonalChart = chartsDataSource[indexPath.row]
            currentSeasonalChartName = seasonalChart.title
            prepareForList(.SeasonalChart)
        }
    }
}



extension ChartViewController: DropDownListDelegate {
    func selectedAction(trigger: UIView, action: String, indexPath: NSIndexPath) {
        if trigger.isEqual(navigationController?.navigationBar) {
            switch (indexPath.row, indexPath.section) {
            case (_, 0):
                currentSeasonalChartName = action
                prepareForList(.SeasonalChart)
            case (0,1):
                prepareForList(.AllSeasons)
            default: break
            }
            
        }
    }
}

extension ChartViewController: UISearchBarDelegate {
    
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

extension ChartViewController: FilterViewControllerDelegate {
    func finishedWith(configuration configuration: Configuration, selectedGenres: [String]) {
        
        currentConfiguration = configuration
        
        for (filterSection, value, _) in configuration {
            if let value = value {
                switch filterSection {
                case .Sort:
                    updateSortType(SortType(rawValue: value)!)
                case .View:
                    updateLayoutType(LayoutType(rawValue: value)!, withSize: view.bounds.size)
                default: break
                }
            }
        }
    
    }
    
}