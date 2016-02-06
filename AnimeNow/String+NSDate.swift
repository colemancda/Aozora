//
//  String+NSDate.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/22/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit

extension String {
    
    // Does not include seconds
    public func dateWithISO8601() -> NSDate? {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mmZZZZZ"
        return dateFormatter.dateFromString(self)
    }
    public func dateWithISO8601NoMinutes() -> NSDate? {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HHZZZZZ"
        return dateFormatter.dateFromString(self)
    }
}
