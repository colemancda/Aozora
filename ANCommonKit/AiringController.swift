//
//  AiringController.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 1/31/16.
//  Copyright © 2016 AnyTap. All rights reserved.
//

import Foundation

public class AiringController {

    public typealias AiringStatusType = (string: String, status: AiringStatus)

    public enum AiringStatus {
        case Behind
        case Future
    }

    public class func airingStatusForFirstAired(firstAired: NSDate, currentEpisode: Int, totalEpisodes: Int, airingStatus: AnimeStatus) -> AiringStatusType {

        // TODO: Clean this mess
        let nextEpisodeToWatchDate = firstAired.dateByAddingWeeks(currentEpisode)
        let (nextAirEpisodeDate, _) = AiringController.nextEpisodeToAirForStartDate(firstAired)

        if airingStatus != AnimeStatus.FinishedAiring && nextEpisodeToWatchDate.compare(NSDate()) == .OrderedDescending {
            // Future episode
            print("Future Episode")

            let etaString = nextAirEpisodeDate.etaStringForDate(short: true)
            return (etaString, .Future)
        } else {

            print("Past Episode")
            var episodesBehind = 0
            var newDate = nextEpisodeToWatchDate

            var lastAiredEpisode: NSDate

            if airingStatus == AnimeStatus.FinishedAiring {
                lastAiredEpisode = firstAired.dateByAddingWeeks(totalEpisodes - 1)
            } else {
                lastAiredEpisode = nextAirEpisodeDate
            }

            while newDate.compare(lastAiredEpisode) == .OrderedAscending {
                episodesBehind += 1
                newDate = nextEpisodeToWatchDate.dateByAddingWeeks(episodesBehind)
            }

            return ("\(episodesBehind + 1) behind", .Behind)
        }
    }

    public class func nextEpisodeToAirForStartDate(startDate: NSDate) -> (nextDate: NSDate, nextEpisode: Int) {

        let now = NSDate()

        if startDate.compare(now) == NSComparisonResult.OrderedDescending {
            return (startDate, 1)
        }

        let cal = NSCalendar.currentCalendar()
        let unit: NSCalendarUnit = .WeekOfYear
        let components = cal.components(unit, fromDate: startDate, toDate: now, options: [])
        components.weekOfYear = components.weekOfYear+1

        let nextEpisodeDate: NSDate = cal.dateByAddingComponents(components, toDate: startDate, options: [])!
        return (nextEpisodeDate, components.weekOfYear+1)
    }
}

extension NSDate {
    func dateByAddingWeeks(weeks: Int) -> NSDate {
        return dateByAddingTimeInterval(Double(weeks * 7 * 24 * 60 * 60))
    }
}