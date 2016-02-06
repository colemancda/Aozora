//
//  TimelinePost.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 7/29/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import Parse

public class TimelinePost: PFObject, PFSubclassing, TimelinePostable {
    override public class func initialize() {
        struct Static {
            static var onceToken : dispatch_once_t = 0;
        }
        dispatch_once(&Static.onceToken) {
            self.registerSubclass()
        }
    }
    
    public class func parseClassName() -> String {
        return "TimelinePost"
    }
    
    // Postable
    
    public var replies: [PFObject] = []
    public var isSpoilerHidden = true
    public var showAllReplies = false
    
    public var imagesDataInternal: [ImageData]?
    public var linkDataInternal: LinkData?
}