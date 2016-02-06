//
//  AnimeService.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 5/23/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import ANCommonKit
import Parse
import Bolts


public class AnimeService {

    public class func findAllAnime() -> BFTask {
        
        let query = PFQuery(className: ParseKit.Anime)
        query.limit = 1000
        query.skip = 0
        
        return findAllObjectsWith(query: query)
    }
    
    public class func findAllObjectsWith(query query: PFQuery, skip: Int? = 0) -> BFTask {
        query.limit = 1000
        query.skip = skip!
        
        return query
            .findObjectsInBackground()
            .continueWithBlock { (task: BFTask!) -> BFTask! in
            
            let result = task.result as! [PFObject]
                
                if result.count == query.limit {
                    return self.findAllObjectsWith(query: query, skip:query.skip + query.limit)
                        .continueWithBlock({ (previousTask: BFTask!) -> AnyObject! in
                        let previousResults = previousTask.result as! [PFObject]
                        return BFTask(result: previousResults+result)
                    })
                } else {
                    return task
                }
        }
    }
    
    public class func findAnimeForSeasonalChart(season: PFObject) -> BFTask {
        if let startDate = season["startDate"] as? NSDate,
        let endDate = season["endDate"] as? NSDate {
            
            let query = PFQuery(className: ParseKit.Anime)
            query.whereKey("startDate", greaterThanOrEqualTo: startDate)
            query.whereKey("startDate", lessThanOrEqualTo: endDate)
            
            let query2 = PFQuery(className: ParseKit.Anime)
            query2.whereKey("type", notEqualTo: "TV")
            query2.whereKey("endDate", greaterThanOrEqualTo: startDate)
            query2.whereKey("endDate", lessThanOrEqualTo: endDate)
            
            return PFQuery
                .orQueryWithSubqueries([query,query2])
                .findObjectsInBackground()
        }
        return BFTask(result: [])
    }
    
    public class func findAnime(sort: AnimeSort? = .AZ, years: [Int]? = [], genres: [AnimeGenre]? = [], types: [AnimeType]? = [], classification: [AnimeClassification]? = [], status: [AnimeStatus]? = [] , includeClasses: [String]? = [] , limit: Int? = 1000) -> BFTask {
        let query = PFQuery(className: ParseKit.Anime)
        
        query.limit = limit!
        
        switch sort! {
            case .AZ: query.orderByAscending("title")
            case .Popular: query.orderByDescending("popularityRank")
            case .Rating: query.orderByDescending("rank")
        }
        
        if let years = years where years.count != 0 {
            
            var includeYears: [Int] = []
            for year in years {
                includeYears.append(year)
            }
            query.whereKey("year", containedIn: includeYears)
        }
        
        if let genres = genres where genres.count != AnimeGenre.count() && genres.count != 0 {
            var includeGenres: [String] = []
            for genre in genres {
                includeGenres.append(genre.rawValue)
            }
            query.whereKey("genres", containsAllObjectsInArray: includeGenres)
        }
        
        
        if let types = types where types.count != AnimeType.count() && types.count != 0  {
            var includeTypes: [String] = []
            for type in types {
                includeTypes.append(type.rawValue)
            }
            query.whereKey("type", containedIn: includeTypes)
        }
        
        if let classification = classification where classification.count != AnimeClassification.count() && classification.count != 0  {
            var includeClassifications: [String] = []
            for aClassification in classification {
                includeClassifications.append(aClassification.rawValue)
            }
            let innerQuery = PFQuery(className: ParseKit.AnimeDetail)
            innerQuery.whereKey("classification", containedIn: includeClassifications)
            query.whereKey("details", matchesQuery: innerQuery)
        }
        
        if let status = status where status.count != AnimeStatus.count() && status.count != 0  {
            var includeStatus: [String] = []
            for aStatus in status {
                includeStatus.append(aStatus.rawValue)
            }
            query.whereKey("status", containedIn: includeStatus)
        }
        
        return query.findObjectsInBackground()
        
    }
    
}