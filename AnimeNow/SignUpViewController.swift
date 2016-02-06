//
//  SignViewController.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/29/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import ANCommonKit
import RSKImageCropper
import ANParseKit

protocol SignUpViewControllerDelegate: class {
    func signUpViewControllerCreatedAccount()
}

class SignUpViewController: UIViewController {
    
    @IBOutlet weak var usernameTextField: CustomTextField!
    @IBOutlet weak var emailTextField: CustomTextField!
    @IBOutlet weak var passwordTextField: CustomTextField!
    @IBOutlet weak var signButton: UIButton!
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var selectImageButton: UIButton!
    
    var loggedInWithFacebook = false
    var isInWindowRoot = true
    var userProfileManager = UserProfileManager()
    var user: User?
    weak var delegate: SignUpViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userProfileManager.initWith(self, delegate: self)
        
        if loggedInWithFacebook {
            passwordTextField.hidden = true
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
    }
    
    // MARK: - IBActions
    
    @IBAction func selectProfilePicturePressed(sender: AnyObject) {
        userProfileManager.selectAvatar()
    }
    
    @IBAction func dismissPressed(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func loginPressed(sender: AnyObject) {
        
        userProfileManager.createUser(self,
            username: usernameTextField.text ?? "",
            password: passwordTextField.text ?? "",
            email: emailTextField.text?.lowercaseString ?? "",
            avatar: profilePicture.image,
            user: user ?? User(),
            loginInWithFacebook: loggedInWithFacebook)
            .continueWithExecutor(BFExecutor.mainThreadExecutor(), withSuccessBlock: { (task: BFTask!) -> AnyObject! in
                
                self.view.endEditing(true)
                self.dismissViewControllerAnimated(true, completion: { () -> Void in
                    self.delegate?.signUpViewControllerCreatedAccount()
                })
                
            return nil
        })
    }
}

extension SignUpViewController: UINavigationBarDelegate {
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .TopAttached
    }
}

extension SignUpViewController: UITextFieldDelegate {

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        view.endEditing(true)
        if textField == passwordTextField {
            loginPressed(textField)
        }
        return true
    }
}

extension SignUpViewController: UserProfileManagerDelegate {
    
    func selectedAvatar(avatar: UIImage) {
        selectImageButton.setTitle("", forState: .Normal)
        profilePicture.image = avatar
    }
    
    func selectedBanner(banner: UIImage) {
        
    }

}

