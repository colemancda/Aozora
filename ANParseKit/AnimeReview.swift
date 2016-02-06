//
//  AnimeReview.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/11/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import Parse

public class AnimeReview: PFObject, PFSubclassing {
    override public class func initialize() {
        struct Static {
            static var onceToken : dispatch_once_t = 0;
        }
        dispatch_once(&Static.onceToken) {
            self.registerSubclass()
        }
    }
    
    public class func parseClassName() -> String {
        return "AnimeReview"
    }
    
    @NSManaged public var reviews: [AnyObject]
    
    public struct Review {
        public var avatarUrl: String
        public var date: String
        public var episodes: Int
        public var helpful: Int
        public var helpfulTotal: Int
        public var rating: Int
        public var review: String
        public var username: String
        public var watchedEpisodes: Int
        
        public func helpfulString() -> String {
            let percentageString = String(format: "%.0f%%",Double(self.helpful)*100.0 / Double(self.helpfulTotal))
            return "\(percentageString) of \(self.helpfulTotal) people found this review helpful"
        }
    }
    
    public func reviewFor(index index: Int) -> Review {
        
        let data: AnyObject = reviews[index]

        return Review(
            avatarUrl: (data["avatar_url"] as! String),
            date: (data["date"] as! String),
            episodes: (data["episodes"] as! Int),
            helpful: (data["helpful"] as! Int),
            helpfulTotal: (data["helpful_total"] as! Int),
            rating: (data["rating"] as! Int),
            review: (data["review"] as! String),
            username: (data["username"] as! String),
            watchedEpisodes: (data["watched_episodes"] as! Int)
        )
    }
}
