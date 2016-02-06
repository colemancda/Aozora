//
//  EditProfileViewController.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 8/7/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import Bolts
import ANParseKit

protocol EditProfileViewControllerProtocol: class {
    func editProfileViewControllerDidEditedUser(user: User)
}

public class EditProfileViewController: UIViewController {
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var bannerImageView: UIImageView!
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var aboutTextView: UITextView!
    
    @IBOutlet weak var saveBBI: UIBarButtonItem!
    
    @IBOutlet weak var formWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollViewBottomSpaceConstraint: NSLayoutConstraint!
    
    weak var delegate: EditProfileViewControllerProtocol?
    var user = User.currentUser()!
    var userProfileManager = UserProfileManager()
    var updatedAvatar = false
    var updatedBanner = false
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        emailTextField.textColor = UIColor.blackColor()
        
        userProfileManager.initWith(self, delegate: self)
        
        if let avatarFile = user.avatarThumb {
            avatarImageView.setImageWithPFFile(avatarFile, animated: true)
        }
        
        if let bannerFile = user.banner {
            bannerImageView.setImageWithPFFile(bannerFile, animated: true)
        }
        
        emailTextField.text = user.email
        user.details.fetchIfNeededInBackgroundWithBlock({ (details, error) -> Void  in
            if let details = details as? UserDetails {
                self.formWidthConstraint.constant = self.view.bounds.size.width
                
                self.aboutTextView.text = details.about
                self.view.layoutIfNeeded()
            }
        })
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - NSNotificationCenter
    
    func keyboardWillShow(notification: NSNotification) {
        let userInfo = notification.userInfo! as NSDictionary
        
        let endFrameValue = userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue
        let keyboardEndFrame = view.convertRect(endFrameValue.CGRectValue(), fromView: nil)
        
        updateInputForHeight(keyboardEndFrame.size.height)
    }
    
    func keyboardWillHide(notification: NSNotification) {
        updateInputForHeight(0)
    }
    
    // MARK: - Functions
    
    func updateInputForHeight(height: CGFloat) {
        
        scrollViewBottomSpaceConstraint.constant = height
        
        view.setNeedsUpdateConstraints()
        
        UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseOut, animations: {
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    // MARK: - IBAction
    
    @IBAction func changeAvatar(sender: AnyObject) {
        userProfileManager.selectAvatar()
    }
    
    @IBAction func changeBanner(sender: AnyObject) {
        userProfileManager.selectBanner()
    }
    
    @IBAction func dismissController(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func saveUser(sender: AnyObject) {
        saveBBI.enabled = false
        userProfileManager.updateUser(
            self,
            user: user,
            email: emailTextField.text,
            avatar: updatedAvatar ? avatarImageView.image : nil,
            banner: updatedBanner ? bannerImageView.image : nil,
            about: aboutTextView.text).continueWithSuccessBlock { (task: BFTask!) -> AnyObject! in
                self.delegate?.editProfileViewControllerDidEditedUser(self.user)
                self.dismissViewControllerAnimated(true, completion: nil)
                return nil
            }.continueWithBlock { (task: BFTask!) -> AnyObject! in
                self.saveBBI.enabled = true
                return nil
        }
    }
}

extension EditProfileViewController: UINavigationBarDelegate {
    public func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.TopAttached
    }
}

extension EditProfileViewController: UserProfileManagerDelegate {
    public func selectedAvatar(avatar: UIImage) {
        updatedAvatar = true
        avatarImageView.image = avatar
    }
    
    public func selectedBanner(banner: UIImage) {
        updatedBanner = true
        bannerImageView.image = banner
    }
}

extension EditProfileViewController: UITextViewDelegate {
    public func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        view.layoutIfNeeded()
        return true
    }
}