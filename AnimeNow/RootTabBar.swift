//
//  CustomTabBar.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/9/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit
import ANParseKit
import ANCommonKit

public class RootTabBar: UITabBarController {
    public static let ShowedMyAnimeListLoginDefault = "Defaults.ShowedMyAnimeListLogin"
    
    var selectedDefaultTabOnce = false
    var chechedForNotificationsOnce = false
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        // Load library
        LibraryController.sharedInstance.fetchAnimeList(false)
        delegate = self
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if !selectedDefaultTabOnce {
            selectedDefaultTabOnce = true
            if let value = NSUserDefaults.standardUserDefaults().valueForKey(DefaultLoadingScreen) as? String {
                switch value {
                case "Season":
                    break
                case "Library":
                    selectedIndex = 1
                case "Profile":
                    selectedIndex = 2
                case "Forum":
                    selectedIndex = 4
                default:
                    break
                }
            }
        }
    }
    
    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if !chechedForNotificationsOnce {
            chechedForNotificationsOnce = true
            checkIfThereAreNotifications()
        }
    }
    
    func newNotifications(count: Int) {
        var result: String? = nil
        if count > 0 {
            result = "\(count)"
        }
        
        tabBar.items?[3].badgeValue = result
    }
    
    func checkIfThereAreNotifications() {
        if let navController = viewControllers![3] as? UINavigationController,
            let notificationVC = navController.viewControllers.first as? NotificationsViewController {
            notificationVC.fetchNotifications()
        }
    }
}

// MARK: - NotificationsViewControllerDelegate
extension RootTabBar: NotificationsViewControllerDelegate {
    func notificationsViewControllerHasUnreadNotifications(count: Int) {
        newNotifications(count)
    }
    func notificationsViewControllerClearedAllNotifications() {
        newNotifications(0)
    }
}

extension RootTabBar: UITabBarControllerDelegate {
    public func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        
        
        if let navController = viewController as? UINavigationController {
            
            let profileController = navController.viewControllers.first as? ProfileViewController
            let libraryController = navController.viewControllers.first as? AnimeLibraryViewController
            
            if profileController == nil && libraryController == nil {
                return true
            }
            
            if User.currentUserIsGuest() {
                let onboarding = UIStoryboard(name: "Onboarding", bundle: nil).instantiateInitialViewController() as! OnboardingViewController
                onboarding.isInWindowRoot = false
                presentViewController(onboarding, animated: true, completion: nil)
                return false
            }
            
            if let _ = libraryController where !NSUserDefaults.standardUserDefaults().boolForKey(RootTabBar.ShowedMyAnimeListLoginDefault) {
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: RootTabBar.ShowedMyAnimeListLoginDefault)
                NSUserDefaults.standardUserDefaults().synchronize()
                
                let loginController = ANParseKit.loginViewController()
                loginController.delegate = self
                presentViewController(loginController, animated: true, completion: nil)
                return false
                
            }
        }
        
        return true
    }
}

extension RootTabBar: LoginViewControllerDelegate {
    public func loginViewControllerPressedDoesntHaveAnAccount() {
        selectedIndex = 1
    }
}