//
//  Anime.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/11/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import Bolts
import Parse
import ANCommonKit

public class Anime: PFObject, PFSubclassing {
    
    override public class func initialize() {
        struct Static {
            static var onceToken : dispatch_once_t = 0;
        }
        dispatch_once(&Static.onceToken) {
            self.registerSubclass()
        }
    }
    
    public class func parseClassName() -> String {
        return "Anime"
    }
    
    @NSManaged public var rank: Int
    @NSManaged public var myAnimeListID: Int
    @NSManaged public var anilistID: Int
    @NSManaged public var tvdbID: Int
    @NSManaged public var traktID: Int
    @NSManaged public var traktSlug: String
    @NSManaged public var title: String?
    @NSManaged public var titleEnglish: String?
    @NSManaged public var type: String
    @NSManaged public var episodes: Int
    
    @NSManaged public var startDate: NSDate?
    @NSManaged public var endDate: NSDate?
    @NSManaged public var genres: [String]
    @NSManaged public var imageUrl: String
    @NSManaged public var producers: [String]
    @NSManaged public var status: String
    
    @NSManaged public var details: AnimeDetail
    @NSManaged public var relations: AnimeRelation
    @NSManaged public var cast: AnimeCast
    @NSManaged public var characters: AnimeCharacter
    
    @NSManaged public var favoritedCount: Int
    @NSManaged public var membersCount: Int
    @NSManaged public var membersScore: Double
    @NSManaged public var popularityRank: Int
    @NSManaged public var year: Int
    @NSManaged public var fanart: String?
    @NSManaged public var hummingBirdID: Int
    @NSManaged public var hummingBirdSlug: String
    
    @NSManaged public var duration: Int
    @NSManaged public var externalLinks: [AnyObject]
    @NSManaged public var source: String?
    @NSManaged public var startDateTime: NSDate?
    @NSManaged public var studio: [NSDictionary]
    
    public var progress: AnimeProgress?
    public var publicProgress: AnimeProgress?
    
    public func fanartThumbURLString() -> String {
        if let fanartUrl = fanart where fanartUrl.characters.count != 0 {
            return fanartUrl.stringByReplacingOccurrencesOfString("/original/", withString: "/thumb/")
        } else {
            return fanartURLString()
        }
    }
    
    public func fanartURLString() -> String {
        if let fanartUrl = fanart where fanartUrl.characters.count != 0 {
            return fanartUrl
        } else {
            return imageUrl.stringByReplacingOccurrencesOfString(".jpg", withString: "l.jpg")
        }
    }
    
    public func informationString() -> String {
        let episodes = (self.episodes != 0) ? self.episodes.description : "?"
        let duration = (self.duration != 0) ? self.duration.description : "?"
        let year = (self.year != 0) ? self.year.description : "?"
        return "\(type) · \(ANParseKit.shortClassification(details.classification)) · \(episodes) eps · \(duration) min · \(year)"
    }
    
    // Episodes
    var cachedEpisodeList: [Episode] = []
    
    public func episodeList() -> BFTask {
    
        if cachedEpisodeList.count != 0 || (episodes == 0 && traktID == 0) {
            return BFTask(result: cachedEpisodeList)
        }
        
        return fetchEpisodes(myAnimeListID).continueWithSuccessBlock { (task: BFTask!) -> AnyObject! in
            
            guard let episodes = task.result as? [Episode] else {
                return nil
            }

            self.cachedEpisodeList = episodes
            return nil
            
        }.continueWithSuccessBlock { (task: BFTask!) -> AnyObject! in
            
            if let result = task.result as? [Episode] where result.count > 0 {
                print("Found \(result.count) eps from network")
                self.cachedEpisodeList += result
            }
        
            return BFTask(result: self.cachedEpisodeList)
        }

    }
    
    func fetchEpisodes(myAnimeListID: Int) -> BFTask {
        let episodesQuery = Episode.query()!
        episodesQuery.orderByAscending("number")
        episodesQuery.whereKey("anime", equalTo: self)
        return episodesQuery.findAllObjectsInBackground()
    }
    
    // ETA
    
    public var nextEpisode: Int? {
        get {
            return hasNextEpisodeInformation() ? nextEpisodeInternal : nil
        }
    }
    
    public var nextEpisodeDate: NSDate? {
        get {
            return hasNextEpisodeInformation() ? nextEpisodeDateInternal : nil
        }
    }
    
    var nextEpisodeInternal: Int = 0
    var nextEpisodeDateInternal: NSDate = NSDate()
    
    func hasNextEpisodeInformation() -> Bool {
        if let startDate = startDateTime where AnimeStatus(rawValue: status) != .FinishedAiring {
            if nextEpisodeInternal == 0 {
                let (nextAiringDate, nextAiringEpisode) = AiringController.nextEpisodeToAirForStartDate(startDate)
                nextEpisodeInternal = nextAiringEpisode
                nextEpisodeDateInternal = nextAiringDate    
            }
            return true
        } else {
            return false
        }
    }
    
    // External Links
    
    public enum ExternalLink: String {
        case Crunchyroll = "Crunchyroll"
        case OfficialSite = "Official Site"
        case Daisuki = "Daisuki"
        case Funimation = "Funimation"
        case MyAnimeList = "MyAnimeList"
        case Hummingbird = "Hummingbird"
        case Anilist = "Anilist"
        case Other = "Other"
    }
    
    public struct Link {
        public var site: ExternalLink
        public var url: String
    }
    
    public func linkAtIndex(index: Int) -> Link {
        
        let linkData: AnyObject = externalLinks[index]
        let externalLink = ExternalLink(rawValue: linkData["site"] as! String) ?? .Other

        return Link(site: externalLink, url: (linkData["url"] as! String))
    }
    
    // Fetching
    
    public class func queryWith(objectID objectID: String) -> PFQuery {
        
        let query = Anime.query()!
        query.limit = 1
        query.whereKey("objectId", equalTo: objectID)
        return query
    }
    
    public class func queryWith(malID malID: Int) -> PFQuery {
        
        let query = Anime.query()!
        query.limit = 1
        query.whereKey("myAnimeListID", equalTo: malID)
        return query
    }
    

}
