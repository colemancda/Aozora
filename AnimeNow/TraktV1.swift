//
//  AniListClient.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 4/29/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import Alamofire
import Keys

public struct TraktV1 {
    
    public enum Router: URLRequestConvertible {
        static let TraktAPIKey = AozoraKeys().trakrV1ApiKey()
        static let BaseURLString = "https://api.trakt.tv"
        
        case showSummaryForID(tvdbID: Int)
        
        public var URLRequest: NSMutableURLRequest {
            let (method, path, parameters): (Alamofire.Method, String, [String: AnyObject]) = {
                switch self {
                case .showSummaryForID(let tvdbID):
                    return (.GET, "show/summary.json/\(Router.TraktAPIKey)/\(tvdbID)", [:])
                }
            }()
            
            let URL = NSURL(string: Router.BaseURLString)
            let URLRequest = NSMutableURLRequest(URL: URL!.URLByAppendingPathComponent(path))
            URLRequest.HTTPMethod = method.rawValue
            let encoding = Alamofire.ParameterEncoding.URL
            
            return encoding.encode(URLRequest, parameters: parameters).0
        }
    }

}