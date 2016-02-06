//
//  CustomTextField.swift
//  Seedonk
//
//  Created by Paul Chavarria Podoliako on 2/20/15.
//  Copyright (c) 2015 Seedonk. All rights reserved.
//

import UIKit

public class CustomTextField: UITextField {

    @IBOutlet var nextField : UITextField?

    override public func awakeFromNib() {
        super.awakeFromNib()

        let paddingView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 10.0, height: bounds.size.height))
        leftView = paddingView
        leftViewMode = .Always
    }

}

public extension CustomTextField {
    
    func isEmpty() -> Bool {
        return text!.characters.count == 0
    }
    
    func validEmail() -> Bool {
        let emailRegex = "[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?"
        let regularExpression = try? NSRegularExpression(pattern: emailRegex, options: NSRegularExpressionOptions.CaseInsensitive)
        let matches = regularExpression?.numberOfMatchesInString(text!, options: [], range: NSMakeRange(0, (text! as NSString).length))
        return (matches == 1)
    }
    
    func hasEqualTextAs(otherTextField:UITextField) -> Bool {
        return (text == otherTextField.text)
    }
    
    func validPassword() -> Bool {
        return text!.characters.count >= 6
    }
    
    func trimSpaces() {
        text = text!.stringByReplacingOccurrencesOfString(" ", withString: "")
    }
    
}
