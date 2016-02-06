//
//  TimelinePost.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 7/29/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import Parse

public class ThreadTag: PFObject, PFSubclassing {
    override public class func initialize() {
        struct Static {
            static var onceToken : dispatch_once_t = 0;
        }
        dispatch_once(&Static.onceToken) {
            self.registerSubclass()
        }
    }
    
    public class func parseClassName() -> String {
        return "ThreadTag"
    }
    
    @NSManaged public var name: String
    @NSManaged public var detail: String?
    @NSManaged public var order: Int
    @NSManaged public var privateTag: Bool

    @NSManaged public var visible: Bool
    
}