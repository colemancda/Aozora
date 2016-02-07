//
//  InAppController.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 7/10/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import ANCommonKit

// Aozora
public let ProInAppPurchase = "com.anytap.Aozora.Pro"
public let ProPlusInAppPurchase = "com.anytap.Aozora.ProPlus"

// AnimeTrakr
public let ATPurchaseIDAnimeTrakrPRO = "com.EverFox.AnimeTrakr.AnimeTrakr" // PRO+
public let ATPurchaseIDCheckIn = "com.EverFox.AnimeTrakr.CheckIn" // PRO
// AnimeTrakr Deprecated
public let ATPurchaseIDAllFeatures = "com.EverFox.AnimeTrakr.AllFeatures" // PRO+
public let ATPurchaseIDEpisodeFeed = "com.EverFox.AnimeTrakr.EpisodeFeed" // PRO
public let ATPurchaseIDNoAds = "com.EverFox.AnimeTrakr.NoAds" // PRO
public let ATPurchaseIDSync = "com.EverFox.AnimeTrakr.Sync" // PRO

public class InAppController {

    public static var ProIdentifier: String {
        return AppEnvironment.application() == .Aozora ? ProInAppPurchase : ATPurchaseIDCheckIn
    }

    public static var ProPlusIdentifier: String {
        return AppEnvironment.application() == .Aozora ? ProPlusInAppPurchase : ATPurchaseIDAnimeTrakrPRO
    }

    public class func canDisplayAds() -> Bool {
        return !hasAnyPro()
    }

    public class func hasAnyPro() -> Bool {
        guard let user = User.currentUser() else {
            return false
        }
        return purchasedPro() || purchasedProPlus() || user.hasTrial()
    }
    
    public class func purchasedPro() -> Bool {
        guard let user = User.currentUser() else {
            return false
        }
        let userDefaults = NSUserDefaults.standardUserDefaults()

        let pro = userDefaults.boolForKey(InAppController.ProIdentifier) ||
            user.unlockedContent.indexOf(InAppController.ProIdentifier) != nil ||
            userDefaults.boolForKey(ATPurchaseIDEpisodeFeed) ||
            userDefaults.boolForKey(ATPurchaseIDNoAds) ||
            userDefaults.boolForKey(ATPurchaseIDSync)

        return pro
    }
    
    public class func purchasedProPlus() -> Bool {
        guard let user = User.currentUser() else {
            return false
        }
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let proPlus = userDefaults.boolForKey(InAppController.ProPlusIdentifier) ||
            user.unlockedContent.indexOf(InAppController.ProPlusIdentifier) != nil ||
            userDefaults.boolForKey(ATPurchaseIDAllFeatures)
        return proPlus
    }
}
