//
//  WormholeExtensions.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 1/31/16.
//  Copyright © 2016 AnyTap. All rights reserved.
//

import Foundation
import MMWormhole

extension MMWormhole {

    public enum Identifier: String {
        case WatchingList = "WatchingList"
    }

    public class func aozoraWormhole() -> MMWormhole {
        var groupIdentifier = ""
        if AppEnvironment.application() == .Aozora {
            groupIdentifier = "group.anytap.Aozora"
        } else {
            groupIdentifier = "group.EverFox.AnimeTrakr.TodayExtension"
        }

        return MMWormhole(applicationGroupIdentifier: groupIdentifier, optionalDirectory: "wormwhole")

    }
    
    public func messageWatchingList() -> [AnimeData]? {
        return messageWithIdentifier(Identifier.WatchingList.rawValue) as? [AnimeData]
    }

    public func passWatchingList(watchingList: [AnimeData]) {
        passMessageObject(watchingList, identifier: Identifier.WatchingList.rawValue)
    }

    public func listenForWatchingListUpdates(listener: (AnyObject? -> Void)) {
        listenForMessageWithIdentifier(Identifier.WatchingList.rawValue, listener: listener)
    }
}