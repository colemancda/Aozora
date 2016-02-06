//
//  TimelinePost.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 7/29/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import Parse

public class Thread: PFObject, PFSubclassing, Postable {
    override public class func initialize() {
        struct Static {
            static var onceToken : dispatch_once_t = 0;
        }
        dispatch_once(&Static.onceToken) {
            self.registerSubclass()
        }
    }
    
    public class func parseClassName() -> String {
        return "Thread"
    }
    
    
    @NSManaged public var title: String
    @NSManaged public var anime: Anime?
    @NSManaged public var episode: Episode?
    @NSManaged public var startedBy: User?
    
    @NSManaged public var pinType: String?
    @NSManaged public var locked: Bool
    @NSManaged public var tags: [PFObject]
    @NSManaged public var subscribers: [User]
    @NSManaged public var lastPostedBy: User?
    
    public var imagesDataInternal: [ImageData]?
    public var linkDataInternal: LinkData?
    
    public var isForumGame: Bool {
        get {
            let forumGameId = "M4rpxLDwai"
            for tag in self.tags {
                if let tag = tag as? ThreadTag where tag.objectId! == forumGameId {
                    return true
                }
            }
            return false
        }
    }
}