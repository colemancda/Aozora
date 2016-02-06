//
//  SettingsViewController.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/28/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit
import iRate
import ANParseKit
import ANCommonKit
import FBSDKShareKit

let DefaultLoadingScreen = "Defaults.InitialLoadingScreen";

class SettingsViewController: UITableViewController {
    
    let FacebookPageDeepLink = "fb://profile/713541968752502";
    let FacebookPageURL = "https://www.facebook.com/AozoraApp";
    let TwitterPageDeepLink = "twitter://user?id=3366576341";
    let TwitterPageURL = "https://www.twitter.com/AozoraApp";
    
    @IBOutlet weak var loginLabel: UILabel!
    @IBOutlet weak var linkWithMyAnimeListLabel: UILabel!
    @IBOutlet weak var facebookLikeButton: FBSDKLikeButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        facebookLikeButton.objectID = "https://www.facebook.com/AozoraApp"
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updateLoginButton()
    }
    
    func updateLoginButton() {
        if User.currentUserLoggedIn() {
            // Logged In both
            loginLabel.text = "Logout Aozora"
        } else if User.currentUserIsGuest() {
            // User is guest
            loginLabel.text = "Login Aozora"
        }
        
        if User.syncingWithMyAnimeList() {
            linkWithMyAnimeListLabel.text = "Unlink MyAnimeList"
        } else {
            linkWithMyAnimeListLabel.text = "Sync with MyAnimeList"
        }

    }
    
    // MARK: - IBActions
    
    @IBAction func dismissPressed(sender: AnyObject) {
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - TableView functions
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        guard let cell = tableView.cellForRowAtIndexPath(indexPath) else {
            return
        }
        
        switch (indexPath.section, indexPath.row) {
        case (0,0):
            // Login / Logout
            if User.currentUserLoggedIn() {
                // Logged In both, logout
                let alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
                alert.popoverPresentationController?.sourceView = cell.superview
                alert.popoverPresentationController?.sourceRect = cell.frame
                
                alert.addAction(UIAlertAction(title: "Logout Aozora", style: UIAlertActionStyle.Destructive, handler: { (action) -> Void in
                    
                    WorkflowController.logoutUser().continueWithExecutor( BFExecutor.mainThreadExecutor(), withSuccessBlock: { (task: BFTask!) -> AnyObject! in
                        
                        if let error = task.error {
                            print("failed loggin out: \(error)")
                        } else {
                            print("logout succeeded")
                        }
                        WorkflowController.presentOnboardingController(true)
                        return nil
                    })
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
                }))
                
                self.presentViewController(alert, animated: true, completion: nil)
                
            } else if User.currentUserIsGuest() {
                // User is guest, login
                WorkflowController.presentOnboardingController(true)
            }
        case (0,1):
            // Sync with MyAnimeList
            if User.syncingWithMyAnimeList() {
                let alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
                alert.popoverPresentationController?.sourceView = cell.superview
                alert.popoverPresentationController?.sourceRect = cell.frame
                
                alert.addAction(UIAlertAction(title: "Stop syncing with MyAnimeList", style: UIAlertActionStyle.Destructive, handler: { (action) -> Void in
                    
                    User.logoutMyAnimeList()
                    self.updateLoginButton()
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
                }))
                
                self.presentViewController(alert, animated: true, completion: nil)
            } else {
                
                let loginController = ANParseKit.loginViewController()
                presentViewController(loginController, animated: true, completion: nil)
                
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: RootTabBar.ShowedMyAnimeListLoginDefault)
                NSUserDefaults.standardUserDefaults().synchronize()
            }
            
        case (0,2):
            // Select initial tab
            let alert = UIAlertController(title: "Select Initial Tab", message: "This tab will load when application starts", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Season", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                NSUserDefaults.standardUserDefaults().setValue("Season", forKey: DefaultLoadingScreen)
                NSUserDefaults.standardUserDefaults().synchronize()
            }))
            alert.addAction(UIAlertAction(title: "Library", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                NSUserDefaults.standardUserDefaults().setValue("Library", forKey: DefaultLoadingScreen)
                NSUserDefaults.standardUserDefaults().synchronize()
            }))
            alert.addAction(UIAlertAction(title: "Profile", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                NSUserDefaults.standardUserDefaults().setValue("Profile", forKey: DefaultLoadingScreen)
                NSUserDefaults.standardUserDefaults().synchronize()
            }))
            alert.addAction(UIAlertAction(title: "Forum", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                NSUserDefaults.standardUserDefaults().setValue("Forum", forKey: DefaultLoadingScreen)
                NSUserDefaults.standardUserDefaults().synchronize()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
            }))
            
            self.presentViewController(alert, animated: true, completion: nil)
            
        case (1,0):
            // Unlock features
            let controller = UIStoryboard(name: "InApp", bundle: nil).instantiateViewControllerWithIdentifier("InApp") as! InAppPurchaseViewController
            navigationController?.pushViewController(controller, animated: true)
        case (1,1):
            // Restore purchases
            InAppTransactionController.restorePurchases().continueWithBlock({ (task: BFTask!) -> AnyObject! in
                
                if let _ = task.result {
                    let alert = UIAlertController(title: "Restored!", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                    
                    self.presentViewController(alert, animated: true, completion: nil)
                }
                
                return nil
            })
        case (2,0):
            // Rate app
            iRate.sharedInstance().openRatingsPageInAppStore()
        case (2,1):
            // Recommend to friends
            DialogController.sharedInstance.showFBAppInvite(self)
        case (3,0):
            // Open Facebook
            var url: NSURL?
            if let twitterScheme = NSURL(string: "fb://requests") where UIApplication.sharedApplication().canOpenURL(twitterScheme) {
                url = NSURL(string: FacebookPageDeepLink)
            } else {
                url = NSURL(string: FacebookPageURL)
            }
            UIApplication.sharedApplication().openURL(url!)
        case (3,1):
            // Open Twitter
            var url: NSURL?
            if let twitterScheme = NSURL(string: "twitter://") where UIApplication.sharedApplication().canOpenURL(twitterScheme) {
                url = NSURL(string: TwitterPageDeepLink)
            } else {
                url = NSURL(string: TwitterPageURL)
            }
            UIApplication.sharedApplication().openURL(url!)
        default:
            break
        }
        
        
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        
        switch section {
        case 0:
            return nil
        case 1:
            var message = ""
            if let user = User.currentUser() where
                    user.hasTrial() &&
                    InAppController.purchasedPro() == nil &&
                    InAppController.purchasedProPlus() == nil {
                message = "** You're on a 15 day PRO trial **\n"
            }
            message += "Going PRO unlocks all features and help us keep improving the app"
            return message
        case 2:
            return "If you're looking for support drop us a message on Facebook or Twitter"
        case 3:
            let version = NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"] as! String
            let build = NSBundle.mainBundle().infoDictionary!["CFBundleVersion"] as! String
            return "Created by Anime fans for Anime fans, enjoy!\nAozora \(version) (\(build))"
        default:
            return nil
        }
    }
}

extension SettingsViewController: ModalTransitionScrollable {
    var transitionScrollView: UIScrollView? {
        return tableView
    }
}