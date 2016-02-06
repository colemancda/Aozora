//
//  CustomTextField.swift
//  Seedonk
//
//  Created by Paul Chavarria Podoliako on 2/20/15.
//  Copyright (c) 2015 Seedonk. All rights reserved.
//

import UIKit

public class CustomLabel: UILabel {
    
    public override func drawTextInRect(rect: CGRect) {
        let insets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        super.drawTextInRect(UIEdgeInsetsInsetRect(rect, insets))
    }

}
