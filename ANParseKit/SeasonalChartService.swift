//
//  SeasonalChartWorker.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 5/23/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import Parse
import Bolts

public enum SeasonalChartType: String {
    case Winter = "Winter"
    case Summer = "Summer"
    case Spring = "Spring"
    case Fall = "Fall"
}

public class SeasonalChartService {
    
    public class func findAllSeasonalCharts() -> BFTask {
        let query = PFQuery(className: ParseKit.SeasonalChart)
        return query.findAllObjectsInBackground()
    }
    
    public class func currentSeasonalChart() -> BFTask {
        let query = PFQuery(className: ParseKit.SeasonalChart)
        query.limit = 1
        query.orderByDescending("startDate")
        return query
            .findObjectsInBackground()
            .continueWithBlock { (task: BFTask!) -> BFTask! in
            return task
        }
    }
    
    // MARK: - Set anime to chart
    
    public class func fillAllSeasonalChart() {
        SeasonalChartService.findAllSeasonalCharts().continueWithBlock {
            (task: BFTask!) -> BFTask! in
            
            var sequence = BFTask(result: nil)
            
            if let charts = task.result as? [PFObject] {
                for chart in charts {
                    sequence = sequence.continueWithBlock {
                        (task: BFTask!) -> BFTask! in
                        
                        return SeasonalChartService.updateChartWithAnime(chart)
                    }
                }
            }
            
            return sequence
        }
    }
    
    public class func updateChartWithAnime(season: PFObject) -> BFTask {
    
        return AnimeService
            .findAnimeForSeasonalChart(season)
            .continueWithBlock {
                (task: BFTask!) -> BFTask! in
            
                if let result = task.result as? [PFObject] {
                    var tvAnime: [PFObject] = []
                    var movieAnime: [PFObject] = []
                    var specialAnime: [PFObject] = []
                    var ovaAnime: [PFObject] = []
                    var onaAnime: [PFObject] = []
                    
                    for anime in result {
                        let type = anime["type"] as! String
                        switch type {
                            case "TV": tvAnime.append(anime)
                            case "Movie": movieAnime.append(anime)
                            case "Special": specialAnime.append(anime)
                            case "OVA": ovaAnime.append(anime)
                            case "ONA": onaAnime.append(anime)
                            default: ()
                        }
                    }
                    season.setObject(tvAnime, forKey: "tvAnime")
                    season.setObject(movieAnime, forKey: "movieAnime")
                    season.setObject(ovaAnime, forKey: "ovaAnime")
                    season.setObject(onaAnime, forKey: "onaAnime")
                    season.setObject(specialAnime, forKey: "specialAnime")
                }
                
                return season.saveInBackground()
        }
    }
    
    // MARK: - Charts generation
    public class func seasonalChartString(seasonsAhead: Int) -> (iconName: String, title: String) {

        let calendar = NSCalendar.currentCalendar()
        
        let seasonDate = calendar.dateByAddingUnit(NSCalendarUnit.Month, value: seasonsAhead * 3, toDate: NSDate(), options: [])
        
        let components = calendar.components([NSCalendarUnit.Month, NSCalendarUnit.Year], fromDate: seasonDate!)
        var seasonString = ""
        
        var monthNumber = components.month + 1
        let yearNumber = components.year
        if monthNumber > 12 {
            monthNumber -= 12
        }
        
        switch monthNumber {
        case 2...4 : seasonString = "Winter"
        case 5...7 : seasonString = "Spring"
        case 8...10 : seasonString = "Summer"
        case 1 : fallthrough
        case 11...12 : seasonString = "Fall"
        default: break
        }
        
        var iconName = ""
        
        switch SeasonalChartType(rawValue: seasonString)! {
        case .Winter: iconName = "icon-winter"
        case .Spring: iconName = "icon-spring"
        case .Summer: iconName = "icon-summer"
        case .Fall: iconName = "icon-fall"
        }
        
        return (iconName , seasonString + " \(yearNumber)")
    }
    
    public class func generateAllSeasonalCharts() {
        let seasons: [SeasonalChartType] = [.Winter, .Summer, .Spring, .Fall]
        
        for var year = 1990; year < 2016; year++ {
            for seasonEnum in seasons {
                let season = PFObject(className: ParseKit.SeasonalChart)
                season["title"] = "\(seasonEnum.rawValue) \(year)"
                season["startDate"] = startDateForSeason(seasonEnum, year: year)
                season["endDate"] = endDateForSeason(seasonEnum, year: year)
                
                season.saveInBackground()
            }
        }
    }
    
    class func startDateForSeason(season: SeasonalChartType, year: Int) -> NSDate {
        let components = NSDateComponents()
        components.day = 1
        switch (season) {
        case .Winter: components.month = 1
        case .Spring: components.month = 4
        case .Summer: components.month = 7
        case .Fall: components.month = 10
        }
        components.year = year
        
        let calendar = NSCalendar.currentCalendar()
        calendar.timeZone = NSTimeZone(name: "UTC")!
        
        return calendar.dateFromComponents(components)!
    }
    
    class func endDateForSeason(season: SeasonalChartType, year: Int) -> NSDate {
        let components = NSDateComponents()
        
        switch (season) {
        case .Winter:
            components.month = 3
            components.day = 31
        case .Spring:
            components.month = 6
            components.day = 30
        case .Summer:
            components.month = 9
            components.day = 30
        case .Fall:
            components.month = 12
            components.day = 31
        }
        components.year = year
        
        let calendar = NSCalendar.currentCalendar()
        calendar.timeZone = NSTimeZone(name: "UTC")!
        
        return calendar.dateFromComponents(components)!
    }
    

}