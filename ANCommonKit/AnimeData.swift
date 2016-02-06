//
//  AnimeData.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 1/31/16.
//  Copyright © 2016 AnyTap. All rights reserved.
//

import Foundation

public class AnimeData: NSObject, NSCoding {

    public var title = ""
    public var firstAired = NSDate()
    public var currentEpisode = 1
    public var episodes = 1
    public var status = AnimeStatus.NotYetAired

    public init(title: String, firstAired: NSDate, currentEpisode: Int, episodes: Int, status: AnimeStatus) {
        self.title = title
        self.firstAired = firstAired
        self.currentEpisode = currentEpisode
        self.episodes = episodes
        self.status = status
        super.init()
    }

    required public init?(coder aDecoder: NSCoder) {

        guard
            let title = aDecoder.decodeObjectForKey("title") as? String,
            let firstAired = aDecoder.decodeObjectForKey("firstAired") as? NSDate,
            let currentEpisode = aDecoder.decodeObjectForKey("currentEpisode") as? Int,
            let episodes = aDecoder.decodeObjectForKey("episodes") as? Int,
            let status = aDecoder.decodeObjectForKey("status") as? String
            else {
                super.init()
                return nil
        }

        self.title = title
        self.firstAired = firstAired
        self.currentEpisode = currentEpisode
        self.episodes = episodes
        self.status = AnimeStatus(rawValue: status) ?? .NotYetAired

        super.init()
    }

    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(title, forKey: "title")
        aCoder.encodeObject(firstAired, forKey: "firstAired")
        aCoder.encodeObject(currentEpisode, forKey: "currentEpisode")
        aCoder.encodeObject(episodes, forKey: "episodes")
        aCoder.encodeObject(status.rawValue, forKey: "status")
    }
}