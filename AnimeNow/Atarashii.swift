//
//  AniListClient.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 4/29/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import Alamofire

public enum SyncState: Int {
    case InSync = 0
    case Created
    case Updated
    case Deleted
}

public enum MALList: String {
    case Planning = "plan to watch"
    case Watching = "watching"
    case Completed = "completed"
    case Dropped = "dropped"
    case OnHold = "on-hold"
}

public struct MALProgress: Hashable {
    public var myAnimeListID: Int
    public var status: String
    public var episodes: Int
    public var score: Int
    public var syncState: SyncState = .InSync
    
    public init(myAnimeListID: Int, status: MALList, episodes: Int, score: Int) {
        self.myAnimeListID = myAnimeListID
        self.status = status.rawValue
        self.episodes = episodes
        self.score = score
    }
    
    func toDictionary() -> [String: AnyObject] {
        return ["anime_id": myAnimeListID, "status": status, "episodes": episodes, "score": score]
    }
    
    public var hashValue: Int {
        get {
            return myAnimeListID
        }
    }
}

public func ==(lhs: MALProgress, rhs: MALProgress) -> Bool {
    return lhs.myAnimeListID == rhs.myAnimeListID
}

public struct Atarashii {
    
    public var accessToken: String
    
    public enum Router: URLRequestConvertible {
        static let BaseURLString = "https://api.atarashiiapp.com/2"
        
        case animeCast(id: Int)
        case verifyCredentials()
        case animeList(username: String)
        case profile(username: String)
        case friends(username: String)
        case history(username: String)
        case animeAdd(progress: MALProgress)
        case animeUpdate(progress: MALProgress)
        case animeDelete(id: Int)
        
        public var URLRequest: NSMutableURLRequest {
            let (method, path, parameters): (Alamofire.Method, String, [String: AnyObject]) = {
                switch self {
                case .animeCast(let id):
                    return (.GET,"anime/cast/\(id)",[:])
                case .verifyCredentials():
                    return (.GET,"account/verify_credentials",[:])
                case .animeList(let username):
                    return (.GET,"animelist/\(username)",[:])
                case .profile(let username):
                    return (.GET,"profile/\(username)",[:])
                case .friends(let username):
                    return (.GET,"friends/\(username)",[:])
                case .history(let username):
                    return (.GET,"history/\(username)",[:])
                case animeAdd(let progress):
                    return (.POST,"animelist/anime", progress.toDictionary())
                case animeUpdate(let progress):
                    return (.PUT,"animelist/anime/\(progress.myAnimeListID)", progress.toDictionary())
                case animeDelete(let id):
                    return (.DELETE,"animelist/anime/\(id)",[:])
                }
            }()
            
            let URL = NSURL(string: Router.BaseURLString)
            let URLRequest = NSMutableURLRequest(URL: URL!.URLByAppendingPathComponent(path))
            URLRequest.HTTPMethod = method.rawValue
            URLRequest.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
            let encoding = Alamofire.ParameterEncoding.URL
            
            return encoding.encode(URLRequest, parameters: parameters.count > 0 ? parameters : nil).0
        }
    }
    
}

