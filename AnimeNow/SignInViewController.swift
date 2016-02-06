//
//  SignInViewController.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 7/27/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

//
//  SignViewController.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/29/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import ANCommonKit
import ANParseKit

protocol SignInViewControllerDelegate: class {
    func signInViewControllerLoggedIn()
}

class SignInViewController: UIViewController {
    
    @IBOutlet weak var usernameTextField: CustomTextField!
    @IBOutlet weak var passwordTextField: CustomTextField!
    @IBOutlet weak var signButton: UIButton!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    @IBOutlet weak var navigationBar: UINavigationBar!
    
    var isInWindowRoot = true
    weak var delegate: SignInViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - IBActions
    
    @IBAction func dismissPressed(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func signInPressed(sender: AnyObject) {
        
        usernameTextField.trimSpaces()
        
        guard let username = usernameTextField.text, password = passwordTextField.text else {
            presentBasicAlertWithTitle("Username or password field is empty")
            return
        }
        
        User.logInWithUsernameInBackground(username.lowercaseString, password:password) {
            (user: PFUser?, error: NSError?) -> Void in
            if let _ = error {
                // The login failed. Check error to see why.
                self.loginWithUsername(username, password: password)
            } else {
                self.view.endEditing(true)
                self.dismissViewControllerAnimated(true, completion: { () -> Void in
                    self.delegate?.signInViewControllerLoggedIn()
                })
            }
        }
    }
    
    func loginWithUsername(username: String, password: String) {
        User.logInWithUsernameInBackground(usernameTextField.text!, password:passwordTextField.text!) {
            (user: PFUser?, error: NSError?) -> Void in
            
            if let error = error {
                let errorMessage = error.userInfo["error"] as! String
                let alert = UIAlertController(title: "Hmm", message: errorMessage+". If you signed in with Facebook, login in with Facebook is required.", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                
                
                self.presentViewController(alert, animated: true, completion: nil)
            } else {
                self.view.endEditing(true)
                self.dismissViewControllerAnimated(true, completion: { () -> Void in
                    self.delegate?.signInViewControllerLoggedIn()
                })
            }
        }
    }
    
}

extension SignInViewController: UINavigationBarDelegate {
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .TopAttached
    }
}

extension SignInViewController: UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        view.endEditing(true)
        if textField == passwordTextField {
            signInPressed(textField)
        }
        return true
    }
}
