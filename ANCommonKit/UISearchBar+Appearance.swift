//
//  UISearchBar+Appearance.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 8/6/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation

extension UISearchBar {
    public func enableCancelButton() {
        for view1 in subviews {
            for view2 in view1.subviews where view2.isKindOfClass(UIButton) {
                let button = view2 as! UIButton
                button.enabled = true
                button.userInteractionEnabled = true
            }
        }
    }
}