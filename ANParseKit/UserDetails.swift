//
//  Anime.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/6/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import Parse

public class UserDetails: PFObject, PFSubclassing {
    override public class func initialize() {
        struct Static {
            static var onceToken : dispatch_once_t = 0;
        }
        dispatch_once(&Static.onceToken) {
            self.registerSubclass()
        }
    }
    
    public class func parseClassName() -> String {
        return "UserDetails"
    }
    
    @NSManaged public var about: String
    @NSManaged public var gender: String
    @NSManaged public var planningAnimeCount: Int
    @NSManaged public var watchingAnimeCount: Int
    @NSManaged public var completedAnimeCount: Int
    @NSManaged public var droppedAnimeCount: Int
    @NSManaged public var onHoldAnimeCount: Int
    @NSManaged public var joinDate: NSDate
    @NSManaged public var posts: Int
    @NSManaged public var watchedTime: Double
    @NSManaged public var avatarRegular: PFFile?
    @NSManaged public var banner: PFFile?
    @NSManaged public var mutedUntil: NSDate?
    
    @NSManaged public var followingCount: Int
    @NSManaged public var followersCount: Int
}