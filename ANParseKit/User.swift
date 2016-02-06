//
//  TimelinePost.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 7/29/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import Parse

public class User: PFUser {
    
    override public class func initialize() {
        struct Static {
            static var onceToken : dispatch_once_t = 0;
        }
        dispatch_once(&Static.onceToken) {
            self.registerSubclass()
        }
    }
    
    @NSManaged public var avatarThumb: PFFile?
    @NSManaged public var banner: PFFile?
    @NSManaged public var badges: [String]
    @NSManaged public var unlockedContent: [String]
    @NSManaged public var joinDate: NSDate
    @NSManaged public var aozoraUsername: String
    @NSManaged public var myAnimeListUsername: String?
    @NSManaged public var anilistUsername: String
    @NSManaged public var details: UserDetails
    
    @NSManaged public var activeStart: NSDate
    @NSManaged public var activeEnd: NSDate
    @NSManaged public var active: Bool
    
    @NSManaged public var trialExpiration: NSDate?
    
    public var followingThisUser: Bool?
    
    static let MyAnimeListPasswordKey = "MyAnimeList.Password"
    
    public func following() -> PFRelation {
        return self.relationForKey("following")
    }

    public override class func currentUser() -> User? {
        return !currentUserIsGuest() ? PFUser.currentUser() as? User : nil
    }
    
    public class func currentUserLoggedIn() -> Bool {
        
        return PFUser.currentUser() != nil && !currentUserIsGuest()
    }
    
    public class func currentUserIsGuest() -> Bool {
        
        return PFAnonymousUtils.isLinkedWithUser(PFUser.currentUser())
    }
    
    public var myAnimeListPassword: String? {
        get {
        return NSUserDefaults.standardUserDefaults().objectForKey(User.MyAnimeListPasswordKey) as! String?
        }
        set(object) {
            NSUserDefaults.standardUserDefaults().setObject(object, forKey: User.MyAnimeListPasswordKey)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    public class func logoutMyAnimeList() {
        NSUserDefaults.standardUserDefaults().removeObjectForKey(User.MyAnimeListPasswordKey)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    public class func syncingWithMyAnimeList() -> Bool {
        guard let user = User.currentUser() else {
            return false
        }
        return user.myAnimeListPassword != nil
    }
    
    public func incrementPostCount(byAmount: Int) {
        details.incrementKey("posts", byAmount: byAmount)
        details.saveInBackground()
    }
    
    public func isAdmin() -> Bool {
        return badges.contains("Admin") || isTopAdmin()
    }
    
    public func isTopAdmin() -> Bool {
        return badges.contains("Top Admin")
    }
    
    // Don't ever name the function isCurrentUser it will conflict with Parse framework
    public func isTheCurrentUser() -> Bool {
        guard let id1 = self.objectId, let currentUser = User.currentUser(), let id2 = currentUser.objectId else {
            return false
        }
        return id1 == id2
    }
    
    // Trial
    public func hasTrial() -> Bool {
        return trialExpiration?.compare(NSDate()) == .OrderedDescending
    }
    
    public func followUser(user: User, follow: Bool) {
        
        var incrementer = 0
        if follow {
            let followingRelation = following()
            followingRelation.addObject(user)
            incrementer = 1
            PFCloud.callFunctionInBackground("sendFollowingPushNotificationV2", withParameters: ["toUser":user.objectId!])
        } else {
            let followingRelation = following()
            followingRelation.removeObject(user)
            incrementer = -1
        }
        
        user.followingThisUser = follow
        user.details.incrementKey("followersCount", byAmount: incrementer)
        user.saveInBackground()
        
        details.incrementKey("followingCount", byAmount: incrementer)
        saveInBackground()
    }
    
    // Muting
    public class func muted(viewController: UIViewController) -> Bool {
        
        
        guard let currentUser = User.currentUser() else {
            return false
        }
        
        var mutedUntil: NSDate?
        
        do {
            let details = try currentUser.details.fetchIfNeeded()
            mutedUntil = details.mutedUntil
            
        } catch _ { }
        
        guard let muteDate = mutedUntil else {
            return false
        }
        
        if muteDate.compare(NSDate()) == NSComparisonResult.OrderedAscending  {
            currentUser.details.mutedUntil = nil
            currentUser.saveInBackground()
            return false
        }
        
        viewController.presentBasicAlertWithTitle("Account muted", message: "Until \(muteDate.mediumDateTime()).\nContact admins for more information.")
        return true
    }
}