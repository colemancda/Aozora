//
//  AppEnvironment.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 2/6/16.
//  Copyright © 2016 AnyTap. All rights reserved.
//

import Foundation

public class AppEnvironment {
    public enum Application: String {
        case Aozora = "Aozora"
        case AnimeTrakr = "AnimeTrakr"
    }

    public class func application() -> Application {
        if let appName = NSBundle.mainBundle().objectForInfoDictionaryKey("APP_NAME") as? String {
            return Application(rawValue: appName) ?? .Aozora
        }
        return .Aozora
    }
}