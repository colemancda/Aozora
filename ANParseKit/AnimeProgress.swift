//
//  Anime.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/6/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import Parse
import ANCommonKit

public enum AozoraList: String {
    case Planning = "Planning"
    case Watching = "Watching"
    case Completed = "Completed"
    case Dropped = "Dropped"
    case OnHold = "On-Hold"
}

public class AnimeProgress: PFObject, PFSubclassing {
    override public class func initialize() {
        struct Static {
            static var onceToken : dispatch_once_t = 0;
        }
        dispatch_once(&Static.onceToken) {
            self.registerSubclass()
        }
    }
    
    public class func parseClassName() -> String {
        return "AnimeProgress"
    }
    
    @NSManaged public var anime: Anime
    @NSManaged public var user: User
    @NSManaged public var startDate: NSDate
    @NSManaged public var endDate: NSDate
    @NSManaged public var isRewatching: Bool
    @NSManaged public var rewatchCount: Int
    @NSManaged public var score: Int
    @NSManaged public var tags: [String]
    @NSManaged public var collectedEpisodes: Int
    @NSManaged public var watchedEpisodes: Int
    @NSManaged public var list: String
    
    // Used to cache the ID to sync with MyAnimeList faster
    var myAnimeListID: Int = 0
    
    public func myAnimeListList() -> MALList {
        switch list {
        case "Planning": return .Planning
        case "Watching": return .Watching
        case "Completed": return .Completed
        case "Dropped": return .Dropped
        case "On-Hold": return .OnHold
        default: return .Planning
        }
    }
    
    public func updateList(malList: MALList) {
        switch malList {
        case .Planning:
            list = AozoraList.Planning.rawValue
        case .Watching:
            list = AozoraList.Watching.rawValue
        case .Completed:
            if anime.episodes != 0 {
                watchedEpisodes = anime.episodes
            }
            endDate = NSDate()
            list = AozoraList.Completed.rawValue
        case .Dropped:
            list = AozoraList.Dropped.rawValue
        case .OnHold:
            list = AozoraList.OnHold.rawValue
        }
    }
    
    public func updatedEpisodes(animeEpisodes: Int) {
        if myAnimeListList() == .Planning {
            list = AozoraList.Watching.rawValue
        }
        
        if myAnimeListList() != .Completed && (animeEpisodes == watchedEpisodes && animeEpisodes != 0) {
            list = AozoraList.Completed.rawValue
        }
        
        if myAnimeListList() == .Completed && (animeEpisodes != watchedEpisodes && animeEpisodes != 0) {
            list = AozoraList.Watching.rawValue
        }
    }
    
    // Next episode to Watch
    
    public var nextEpisodeToWatch: Int? {
        get {
            return hasNextEpisodeToWatchInformation() ? nextEpisodeToWatchInternal : nil
        }
    }
    
    public var nextEpisodeToWatchDate: NSDate? {
        get {
            return hasNextEpisodeToWatchInformation() ? nextEpisodeToWatchDateInternal : nil
        }
    }
    
    var nextEpisodeToWatchInternal: Int = 0
    var nextEpisodeToWatchDateInternal: NSDate = NSDate()
    
    func hasNextEpisodeToWatchInformation() -> Bool {
        if let startDate = anime.startDate where myAnimeListList() != .Completed {
            if nextEpisodeToWatchInternal == 0 {
                let (nextAiringDate, nextAiringEpisode) = nextEpisodeToWatchForStartDate(startDate)
                nextEpisodeToWatchInternal = nextAiringEpisode
                nextEpisodeToWatchDateInternal = nextAiringDate
            }
            return true
        } else {
            return false
        }
    }
    
    func nextEpisodeToWatchForStartDate(startDate: NSDate) -> (nextDate: NSDate, nextEpisode: Int) {
        
        let now = NSDate()
        
        if startDate.compare(now) == NSComparisonResult.OrderedDescending || watchedEpisodes == 0 {
            return (startDate, 1)
        }
        
        let cal = NSCalendar.currentCalendar()
        let unit: NSCalendarUnit = .WeekOfYear
        let components = cal.components(unit, fromDate: startDate)
        components.weekOfYear = watchedEpisodes
        
        let nextEpisodeDate: NSDate = cal.dateByAddingComponents(components, toDate: startDate, options: [])!
        return (nextEpisodeDate, components.weekOfYear + 1)
    }
}