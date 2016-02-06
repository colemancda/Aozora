//
//  LoaderView.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/6/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit

public class LoaderView: UIView {

    let rectShape = CAShapeLayer()
    let diameter = 20
    
    var parentView: UIView!
    public var animating: Bool = false
    
    convenience public init(parentView: UIView) {
        self.init(frame: CGRectZero)
        self.parentView = parentView
        configure()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func configure() {
        backgroundColor = UIColor.clearColor()
        
        rectShape.bounds = CGRect(x: 0, y: 0, width: diameter, height: diameter)
        rectShape.position = CGPoint(x: CGFloat(diameter/2), y: CGFloat(diameter/2))
        rectShape.cornerRadius = bounds.width / 2
        rectShape.path = UIBezierPath(ovalInRect: rectShape.bounds).CGPath
        rectShape.fillColor = UIColor.belizeHole().CGColor
        
        translatesAutoresizingMaskIntoConstraints = false
        
        parentView.addSubview(self)
        
        let viewsDictionary = ["view":self]
        let constraintH = NSLayoutConstraint.constraintsWithVisualFormat("H:[view(\(diameter))]", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)
        let constraintV = NSLayoutConstraint.constraintsWithVisualFormat("V:[view(\(diameter))]", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)
        
        parentView.addConstraints(constraintH)
        parentView.addConstraints(constraintV)
        
        parentView.addConstraint(
            NSLayoutConstraint(
                item: self,
                attribute: NSLayoutAttribute.CenterY,
                relatedBy: NSLayoutRelation.Equal,
                toItem: parentView,
                attribute: NSLayoutAttribute.CenterY,
                multiplier: 1.0,
                constant: 0.0)
        )
        
        parentView.addConstraint(
            NSLayoutConstraint(
                item: self,
                attribute: NSLayoutAttribute.CenterX,
                relatedBy: NSLayoutRelation.Equal,
                toItem: parentView,
                attribute: NSLayoutAttribute.CenterX,
                multiplier: 1.0,
                constant: 0.0)
        )
        
    }
    
    public func startAnimating() {

        if animating {
            return
        }
        
        animating = true
        let timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        let animationDuration = 0.4
        
        let sizingAnimation = CABasicAnimation(keyPath: "transform.scale")
        sizingAnimation.fromValue = 1
        sizingAnimation.toValue = 2
        sizingAnimation.timingFunction = timingFunction
        sizingAnimation.duration = animationDuration
        
        let fadeOut = CABasicAnimation(keyPath: "opacity")
        fadeOut.fromValue = 1
        fadeOut.toValue = 0
        fadeOut.timingFunction = timingFunction
        fadeOut.duration = animationDuration - 0.1
        fadeOut.removedOnCompletion = false
        fadeOut.fillMode = kCAFillModeForwards
        fadeOut.beginTime = 0.1
        
        let group = CAAnimationGroup()
        group.animations = [sizingAnimation, fadeOut]
        group.duration = animationDuration * 2.0
        group.repeatCount = HUGE
        
        layer.addSublayer(rectShape)
        rectShape.addAnimation(group, forKey: nil)

    }
    
    public func stopAnimating() {
        
        animating = false
        rectShape.removeAllAnimations()
        rectShape.removeFromSuperlayer()
    }

}
