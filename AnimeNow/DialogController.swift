//
//  DialogController.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 7/10/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import iRate
import FBSDKShareKit

class DialogController: NSObject {
    
    static let sharedInstance = DialogController()
    
    let DefaultFacebookAppInvitePromped = "Default.FacebookAppInvite.Promped"
    let DefaultFacebookAppInviteEventCount = "Default.FacebookAppInvite.EventCount"
    
    func canShowFBAppInvite(viewController: UIViewController) {
        
        let promped = NSUserDefaults.standardUserDefaults().boolForKey(DefaultFacebookAppInvitePromped)
        if promped {
            return
        }
        
        let eventCount = NSUserDefaults.standardUserDefaults().integerForKey(DefaultFacebookAppInviteEventCount)
        if eventCount > 8 {
            let alert = UIAlertController(title: "Help this app get Discovered", message: "If you like this app, please recommend it to your friends (private recommendation)", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Sure", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                self.showFBAppInvite(viewController)
            }))
            alert.addAction(UIAlertAction(title: "No, thanks", style: UIAlertActionStyle.Default, handler: nil))
            viewController.presentViewController(alert, animated: true, completion: nil)
            
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: DefaultFacebookAppInvitePromped)
            NSUserDefaults.standardUserDefaults().synchronize()

        } else {
            // Increment event count
            NSUserDefaults.standardUserDefaults().setInteger(eventCount + 1, forKey: DefaultFacebookAppInviteEventCount)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        
    }
    
    func showFBAppInvite(viewController: UIViewController) {
        let content = FBSDKAppInviteContent()
        content.appLinkURL = NSURL(string: "https://fb.me/1471151336531847")
        content.appInvitePreviewImageURL = NSURL(string: "https://files.parsetfss.com/496f5287-6440-4a0e-a747-4633b4710808/tfss-2143b956-6840-4e86-a0f1-f706c03f61f8-facebook-app-invite")
        FBSDKAppInviteDialog.showFromViewController(viewController, withContent: content, delegate: nil)
    }
}

//extension DialogController: FBSDKAppInviteDialogDelegate {
//    func appInviteDialog(appInviteDialog: FBSDKAppInviteDialog!, didCompleteWithResults results: [NSObject : AnyObject]) {
//        print(results)
//    }
//    
//    func appInviteDialog(appInviteDialog: FBSDKAppInviteDialog!, didFailWithError error: NSError) {
//        print(error)
//    }
//}