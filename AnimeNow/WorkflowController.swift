//
//  WorkflowController.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/29/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import ANParseKit
import ANCommonKit

class WorkflowController {
    
    class func presentRootTabBar(animated animated: Bool) {
        
        let home = UIStoryboard(name: "Home", bundle: nil).instantiateInitialViewController() as! UINavigationController
        let library = UIStoryboard(name: "Library", bundle: nil).instantiateInitialViewController() as! UINavigationController
        let profile = UIStoryboard(name: "Profile", bundle: nil).instantiateInitialViewController() as! UINavigationController
        let notifications = UIStoryboard(name: "Profile", bundle: nil).instantiateViewControllerWithIdentifier("NotificationNav") as! UINavigationController
        let notificationVC = notifications.viewControllers.first as! NotificationsViewController
        
        
        let forum = UIStoryboard(name: "Forums", bundle: nil).instantiateInitialViewController() as! UINavigationController
        
        let tabBarController = RootTabBar()
        
        notificationVC.delegate = tabBarController
        
        tabBarController.viewControllers = [home, library, profile, notifications, forum]
        
        if animated {
            changeRootViewController(tabBarController, animationDuration: 0.5)
        } else {
            if let window = UIApplication.sharedApplication().delegate!.window {
                window?.rootViewController = tabBarController
                window?.makeKeyAndVisible()
            }
        }
        
    }
    
    class func presentOnboardingController(asRoot: Bool) {
            
        let onboarding = UIStoryboard(name: "Onboarding", bundle: nil).instantiateInitialViewController() as! OnboardingViewController
        
        if asRoot {
            onboarding.isInWindowRoot = true
            applicationWindow().rootViewController = onboarding
            applicationWindow().makeKeyAndVisible()
        } else {
            applicationWindow().rootViewController?.presentViewController(onboarding, animated: true, completion: nil)
        }

    }
    
    class func changeRootViewController(vc: UIViewController, animationDuration: NSTimeInterval = 0.5) {
        
        var window: UIWindow?
        
        let appDelegate = UIApplication.sharedApplication().delegate!
        
        if appDelegate.respondsToSelector(Selector("window")) {
            window = appDelegate.window!
        }
        
        if let window = window {
            if window.rootViewController == nil {
                window.rootViewController = vc
                return
            }
            
            let snapshot = window.snapshotViewAfterScreenUpdates(true)
            vc.view.addSubview(snapshot)
            window.rootViewController = vc
            window.makeKeyAndVisible()
            
            UIView.animateWithDuration(animationDuration, animations: { () -> Void in
                snapshot.alpha = 0.0
                }, completion: {(finished) in
                    snapshot.removeFromSuperview()
            })
        }
    }
    
    class func applicationWindow() -> UIWindow {
        return UIApplication.sharedApplication().delegate!.window!!
    }
    
    class func logoutUser() -> BFTask {
        // Remove cookies
        let storage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
        for cookie in storage.cookies! {
            storage.deleteCookie(cookie)
        }
        
        // Logout MAL
        User.logoutMyAnimeList()
        
        // Remove defaults
        NSUserDefaults.standardUserDefaults().removeObjectForKey(LibraryController.LastSyncDateDefaultsKey)
        NSUserDefaults.standardUserDefaults().removeObjectForKey(RootTabBar.ShowedMyAnimeListLoginDefault)
        NSUserDefaults.standardUserDefaults().synchronize()
        
        // Logout user
        return User.logOutInBackground()

    }
}