//
//  Episode.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/24/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import Parse

public class Episode: PFObject, PFSubclassing {
    
    override public class func initialize() {
        struct Static {
            static var onceToken : dispatch_once_t = 0;
        }
        dispatch_once(&Static.onceToken) {
            self.registerSubclass()
        }
    }
    
    public class func parseClassName() -> String {
        return "Episode"
    }
    
    @NSManaged public var anime: Anime
    @NSManaged public var traktID: Int
    @NSManaged public var tvdbID: Int
    @NSManaged public var tmdbID: Int
    @NSManaged public var number: Int
    @NSManaged public var title: String?
    @NSManaged public var overview: String?
    @NSManaged public var screenshot: String?
    @NSManaged public var traktNumber: Int
    @NSManaged public var traktSeason: Int
    @NSManaged public var firstAired: NSDate?
    
    public func imageURLString() -> String {
        return self.screenshot?.stringByReplacingOccurrencesOfString("original", withString: "thumb") ?? anime.fanart ?? anime.imageUrl ?? ""
    }
}
    