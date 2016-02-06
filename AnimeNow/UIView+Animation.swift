//
//  UIView+Animation.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/15/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit

extension UIView {
    public func animateFadeIn() {
        alpha = 0.0
        transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.85, 0.85)
        
        UIView.animateWithDuration(0.8, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1.0, options:[UIViewAnimationOptions.AllowUserInteraction, UIViewAnimationOptions.CurveEaseOut], animations: { () -> Void in
            self.alpha = 1.0
            self.transform = CGAffineTransformIdentity
            }, completion: nil)
    }
    
    public func animateFadeOut() {
        
        UIView.animateWithDuration(0.25, animations: { () -> Void in
            self.alpha = 0.0
            self.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.85, 0.85)
            }, completion: nil)
    }

    public func animateBounce(growth: CGFloat = 2) {

        transform = CGAffineTransformIdentity
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.transform = CGAffineTransformScale(self.transform, growth, growth)
        }) { completion in
            UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 0.3, initialSpringVelocity: 0.4, options: [.CurveEaseIn, .AllowUserInteraction], animations: { () -> Void in
                self.transform = CGAffineTransformIdentity
            }, completion: nil)
        }
    }
}


