//
//  NSDate+AniNow.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/11/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit

extension NSDate {

    var mediumFormatter: NSDateFormatter {
        struct Static {
            static let instance : NSDateFormatter = {
                let formatter = NSDateFormatter()
                formatter.dateStyle = NSDateFormatterStyle.MediumStyle
                return formatter
                }()
        }
        return Static.instance
    }
    
    var mediumDateTimeFormatter: NSDateFormatter {
        struct Static {
            static let instance : NSDateFormatter = {
                let formatter = NSDateFormatter()
                formatter.dateStyle = NSDateFormatterStyle.MediumStyle
                formatter.timeStyle = NSDateFormatterStyle.MediumStyle
                return formatter
            }()
        }
        return Static.instance
    }
    
    public func mediumDate() -> String {
        return mediumFormatter.stringFromDate(self)
    }
    
    public func mediumDateTime() -> String {
        return mediumDateTimeFormatter.stringFromDate(self)
    }
    
    public func timeAgo() -> String {
        
        let timeInterval = Int(-timeIntervalSinceDate(NSDate()))

        if let weeksAgo = timeInterval / (7*24*60*60) as Int? where weeksAgo > 0 {
            return "\(weeksAgo) " + (weeksAgo == 1 ? "week" : "weeks")
        } else if let daysAgo = timeInterval / (60*60*24) as Int? where daysAgo > 0 {
            return "\(daysAgo) " + (daysAgo == 1 ? "day" : "days")
        } else if let hoursAgo = timeInterval / (60*60) as Int? where hoursAgo > 0 {
            return "\(hoursAgo) " + (hoursAgo == 1 ? "hr" : "hrs")
        } else if let minutesAgo = timeInterval / 60 as Int? where minutesAgo > 0 {
            return "\(minutesAgo) " + (minutesAgo == 1 ? "min" : "mins")
        } else {
            return "Just now"
        }
    }

    public func etaForDate() -> (days: Int, hours: Int, minutes: Int) {
        let now = NSDate()
        let cal = NSCalendar.currentCalendar()
        let unit: NSCalendarUnit = [.Day, .Hour, .Minute]
        let components = cal.components(unit, fromDate: now, toDate: self, options: [])

        return (components.day,components.hour, components.minute)
    }

    public func etaStringForDate(short short: Bool = false) -> String {
        return etaForDateWithString(short: short).etaString
    }

    public func etaForDateWithString(short short: Bool = false) -> (days: Int, hours: Int, minutes: Int, etaString: String) {
        let (days, hours, minutes) = etaForDate()

        var etaTime = ""
        if days != 0 {
            etaTime = short ? "\(days)d \(hours)h" : "\(days)d \(hours)h \(minutes)m"
        } else if hours != 0 {
            etaTime = "\(hours)h \(minutes)m"
        } else {
            etaTime = "\(minutes)m"
        }

        return (days, hours, minutes, etaTime)
    }
}
