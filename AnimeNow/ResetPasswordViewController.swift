//
//  ResetPasswordViewController.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/29/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import ANCommonKit

class ResetPasswordViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: CustomTextField!
    
    @IBAction func resetPressed(sender: AnyObject) {
        
        emailTextField.trimSpaces()
        if emailTextField.validEmail() {
            PFUser.requestPasswordResetForEmailInBackground(emailTextField.text!.lowercaseString, block: { (success: Bool, error: NSError?) -> Void in
                if let error = error {
                    
                    let errorMessage = error.userInfo["error"] as! String
                    let alert = UIAlertController(title: "Hmm..", message: errorMessage, preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                    
                } else {
                    
                    let alert = UIAlertController(title: "Sent!", message: "Please check your email for instructions, domo", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                            self.dismissViewControllerAnimated(true, completion: nil)
                        }))
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            })
        } else {
            let alert = UIAlertController(title: "Woot", message: "Invalid email", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
    }
    @IBAction func dismissPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}

extension ResetPasswordViewController: UINavigationBarDelegate {
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .TopAttached
    }
}