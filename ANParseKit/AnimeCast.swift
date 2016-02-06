//
//  AnimeCast.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/11/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import Parse

public class AnimeCast: PFObject, PFSubclassing {
    override public class func initialize() {
        struct Static {
            static var onceToken : dispatch_once_t = 0;
        }
        dispatch_once(&Static.onceToken) {
            self.registerSubclass()
        }
    }
    
    public class func parseClassName() -> String {
        return "AnimeCast"
    }
    
    @NSManaged public var cast: [[String:AnyObject]]
   
    public struct Cast {
        public var castID: Int = 0
        public var image: String = ""
        public var name: String = ""
        public var job: String = ""
    }
    
    public func castAtIndex(index: Int) -> Cast {
        let data = cast[index]
        
        return Cast(
            castID: (data["id"] as! Int),
            image: (data["image"] as! String),
            name: (data["name"] as! String),
            job: (data["rank"] as! String)
        )
    }
}
