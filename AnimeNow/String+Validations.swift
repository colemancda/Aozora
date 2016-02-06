//
//  String+Validations.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 8/7/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import Parse
import Bolts
import ANCommonKit

extension String {
    public func validEmail(viewController: UIViewController) -> Bool {
        let emailRegex = "[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?"
        let regularExpression = try? NSRegularExpression(pattern: emailRegex, options: NSRegularExpressionOptions.CaseInsensitive)
        let matches = regularExpression?.numberOfMatchesInString(self, options: [], range: NSMakeRange(0, self.characters.count))
        
        let validEmail = (matches == 1)
        if !validEmail {
            viewController.presentBasicAlertWithTitle("Invalid email")
        }
        return validEmail
    }
    
    public func validPassword(viewController: UIViewController) -> Bool {
        
        let validPassword = self.characters.count >= 6
        if !validPassword {
            viewController.presentBasicAlertWithTitle("Invalid password", message: "Length should be at least 6 characters")
        }
        return validPassword
    }
    
    public func validUsername(viewController: UIViewController) -> Bool {
        
        switch self {
        case _ where self.characters.count < 3:
            viewController.presentBasicAlertWithTitle("Invalid username", message: "Make it 3 characters or longer")
            return false
        case _ where self.rangeOfString(" ") != nil:
            viewController.presentBasicAlertWithTitle("Invalid username", message: "It can't have spaces")
            return false
        default:
            return true
        }
    }
    
    public func usernameIsUnique() -> BFTask {
        let query = User.query()!
        query.limit = 1
        query.whereKey("aozoraUsername", matchesRegex: self, modifiers: "i")
        return query.findObjectsInBackground()
    }
}