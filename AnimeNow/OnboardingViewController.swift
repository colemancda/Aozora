//
//  OnboardingViewController.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/29/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import FBSDKCoreKit
import FBSDKLoginKit
import ANParseKit
import ParseFacebookUtilsV4

class OnboardingViewController: UIViewController {

    @IBOutlet weak var facebookLoginButton: UIButton!
    
    var isInWindowRoot = true
    var loggedInWithFacebook = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showSignIn" {
            let sign = segue.destinationViewController as! SignInViewController
            sign.delegate = self
            sign.isInWindowRoot = isInWindowRoot
        } else if segue.identifier == "showSignUp" {
            let sign = segue.destinationViewController as! SignUpViewController
            sign.delegate = self
            sign.user = sender as? User
            sign.isInWindowRoot = isInWindowRoot
            sign.loggedInWithFacebook = loggedInWithFacebook
        }
    }
    
    func presentRootTabBar() {
        
        fillInitialUserDataIfNeeded()
        
        if isInWindowRoot {
            WorkflowController.presentRootTabBar(animated: true)
        } else {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func fillInitialUserDataIfNeeded() {
        if let currentUser = User.currentUser() where currentUser["joinDate"] == nil {
            
            let params = ["user": currentUser.objectId!]
            PFCloud.callFunctionInBackground("fillInitialUserData", withParameters: params, block: { (result, error) -> Void in
                currentUser.fetchInBackground()
            })
        }
        
        // Link instalation with user
        let installation = PFInstallation.currentInstallation()
        
        if let user = User.currentUser() {
            installation.setObject(user, forKey: "user")
            installation.saveInBackground()
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func signUpWithFacebookPressed(sender: AnyObject) {
        let permissions = ["public_profile", "email", "user_friends"]
        PFFacebookUtils.facebookLoginManager().logOut()
        PFFacebookUtils.logInInBackgroundWithReadPermissions(permissions) {
            (user: PFUser?, error: NSError?) -> Void in
            if let user = user {
                self.loggedInWithFacebook = true
                if user.isNew || user["aozoraUsername"] == nil {
                    print("User signed up and logged in through Facebook!")
                    self.performSegueWithIdentifier("showSignUp", sender: user)
                } else {
                    print("User logged in through Facebook!")
                    self.presentRootTabBar()
                }
                
            } else if let error = error {
                print("\(error)")
            }
        }
    }
    
    @IBAction func signUpWithEmailPressed(sender: AnyObject) {

        performSegueWithIdentifier("showSignUp", sender: nil)
    }
    
    @IBAction func skipSignUpPressed(sender: AnyObject) {
        
        if User.currentUserIsGuest() {
            presentRootTabBar()
        } else {
            PFUser.logOut()
            PFAnonymousUtils.logInWithBlock {
                (user: PFUser?, error: NSError?) -> Void in
                if error != nil || user == nil {
                    print("Anonymous login failed.")
                    let alert = UIAlertController(title: "Woot", message: "Anonymous login failed", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                } else {
                    print("Anonymous user logged in.")
                    self.presentRootTabBar()
                }
            }
        }
        
    }
    
    @IBAction func signInPressed(sender: AnyObject) {
        
        performSegueWithIdentifier("showSignIn", sender: nil)
    }
}

extension OnboardingViewController: SignInViewControllerDelegate {
    func signInViewControllerLoggedIn() {
        presentRootTabBar()
    }
}

extension OnboardingViewController: SignUpViewControllerDelegate {
    func signUpViewControllerCreatedAccount() {
        presentRootTabBar()
    }
}