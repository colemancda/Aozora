//
//  InAppController.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 7/10/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation

public let ProInAppPurchase = "com.anytap.Aozora.Pro"
public let ProPlusInAppPurchase = "com.anytap.Aozora.ProPlus"

public class InAppController {

    public class func canDisplayAds() -> Bool {
        return hasAnyPro() == nil
    }

    public class func hasAnyPro() -> Int? {
        guard let user = User.currentUser() else {
            return nil
        }
        return (purchasedPro() != nil ||
                purchasedProPlus() != nil || user.hasTrial()) ? 1 : nil
    }
    
    public class func purchasedPro() -> Int? {
        guard let user = User.currentUser() else {
            return nil
        }
        let identifier = ProInAppPurchase
        let pro = NSUserDefaults.standardUserDefaults().boolForKey(identifier) ||
            user.unlockedContent.indexOf(identifier) != nil
        return pro ? 1 : nil
    }
    
    public class func purchasedProPlus() -> Int? {
        guard let user = User.currentUser() else {
            return nil
        }
        let identifier = ProPlusInAppPurchase
        let proPlus = NSUserDefaults.standardUserDefaults().boolForKey(identifier) ||
        user.unlockedContent.indexOf(identifier) != nil
        return proPlus ? 1 : nil
    }
}
