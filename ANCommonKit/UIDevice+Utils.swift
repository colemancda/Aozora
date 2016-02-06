//
//  UIDevice+Utils.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 12/12/15.
//  Copyright © 2015 AnyTap. All rights reserved.
//

import Foundation

extension UIDevice {
    public class func isPad() -> Bool {
        return UIDevice.currentDevice().userInterfaceIdiom == .Pad
    }
    
    public class func isLandscape() -> Bool {
        return UIDeviceOrientationIsLandscape(UIDevice.currentDevice().orientation)
    }
}
