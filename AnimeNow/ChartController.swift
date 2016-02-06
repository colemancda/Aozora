//
//  ChartController.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 7/12/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import ANParseKit

class ChartController {
    
    class func fetchSeasonalChartAnime(seasonalChart: SeasonalChart) -> BFTask {
        
        let query = Anime.query()!
        query.whereKey("startDate", greaterThanOrEqualTo: seasonalChart.startDate)
        query.whereKey("startDate", lessThanOrEqualTo: seasonalChart.endDate)
        return query.findAllObjectsInBackground()
    }
    
    class func fetchAllSeasons() -> BFTask {
        
        let query = SeasonalChart.query()!
        query.orderByDescending("startDate")
        return query.findAllObjectsInBackground()
    }
}

