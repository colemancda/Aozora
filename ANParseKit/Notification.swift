//
//  TimelinePost.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 7/29/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import Parse

public class Notification: PFObject, PFSubclassing {
    override public class func initialize() {
        struct Static {
            static var onceToken : dispatch_once_t = 0;
        }
        dispatch_once(&Static.onceToken) {
            self.registerSubclass()
        }
    }
    
    public class func parseClassName() -> String {
        return "Notification"
    }
    
    @NSManaged public var triggeredBy: [User]
    @NSManaged public var targetID: String
    @NSManaged public var targetClass: String
    @NSManaged public var subscribers: [User]
    @NSManaged public var message: String
    @NSManaged public var messageOwner: String
    @NSManaged public var previousMessage: String?
    @NSManaged public var owner: User
    @NSManaged public var lastTriggeredBy: User
    @NSManaged public var readBy: [User]
    @NSManaged public var lastUpdatedAt: NSDate?
}