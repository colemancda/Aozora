//
//  Anime.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/6/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import Parse

public class SeasonalChart: PFObject, PFSubclassing {
    override public class func initialize() {
        struct Static {
            static var onceToken : dispatch_once_t = 0;
        }
        dispatch_once(&Static.onceToken) {
            self.registerSubclass()
        }
    }
    
    public class func parseClassName() -> String {
        return "SeasonalChart"
    }
    
    @NSManaged public var title: String
    @NSManaged public var startDate: NSDate
    @NSManaged public var endDate: NSDate
    @NSManaged public var tvAnime: [Anime]
    @NSManaged public var leftOvers: [Anime]
    @NSManaged public var movieAnime: [Anime]
    @NSManaged public var ovaAnime: [Anime]
    @NSManaged public var specialAnime: [Anime]
    @NSManaged public var onaAnime: [Anime]
    @NSManaged public var fanarts: [String]
}