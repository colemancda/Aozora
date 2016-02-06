//
//  ANParseKit.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 5/23/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation

public struct ParseKit {
    public static let Anime = "Anime"
    public static let AnimeDetail = "AnimeDetail"
    public static let AnimeCast = "AnimeCast"
    public static let AnimeCharacters = "AnimeCharacters"
    public static let AnimeForum = "AnimeForum"
    public static let AnimeRelations = "AnimeRelations"
    public static let AnimeReview = "AnimeReview"
    public static let SeasonalChart = "SeasonalChart"
}

public class ANParseKit {
    
    public class func bundle() -> NSBundle {
        return NSBundle(forClass: self)
    }
    
    public class func commentStoryboard() -> UIStoryboard {
        return UIStoryboard(name: "Comment", bundle: bundle())
    }
    
    public class func newPostViewController() -> NewPostViewController {
        let controller = ANParseKit.commentStoryboard().instantiateViewControllerWithIdentifier("NewPost") as! NewPostViewController
        return controller
    }
    
    public class func newThreadViewController() -> NewThreadViewController {
        let controller = ANParseKit.commentStoryboard().instantiateViewControllerWithIdentifier("NewThread") as! NewThreadViewController
        return controller
    }
    
    public class func loginViewController() -> LoginViewController {
        let storyboard = UIStoryboard(name: "Login", bundle: ANParseKit.bundle())
        let loginController = storyboard.instantiateInitialViewController() as! LoginViewController
        return loginController
    }

    public class func webViewController() -> (UINavigationController,InAppBrowserViewController) {
        let controller = UIStoryboard(name: "InAppBrowser", bundle: NSBundle(forClass: self)).instantiateInitialViewController() as! UINavigationController
        return (controller,controller.viewControllers.last! as! InAppBrowserViewController)
    }
    
    public class func shortClassification(classification: String) -> String {
        
        switch classification {
        case "None":
            return "?"
        case "G - All Ages":
            return "G"
        case "PG-13 - Teens 13 or older":
            return "PG-13"
        case "R - 17+ (violence & profanity)":
            return "R17+"
        case "Rx - Hentai":
            return "Rx"
        default:
            return "?"
        }
        
    }
}