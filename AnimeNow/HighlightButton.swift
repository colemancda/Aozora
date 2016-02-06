//
//  HighlightButton.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/6/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit

class HighlightButton: UIButton {
    
    let rectShape = CAShapeLayer()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        addTarget(self, action: "buttonHighlight:", forControlEvents: .TouchDown)
        addTarget(self, action: "buttonNormal:", forControlEvents: .TouchUpInside)
        addTarget(self, action: "buttonNormal:", forControlEvents: .TouchDragExit)
        addTarget(self, action: "buttonHighlight:", forControlEvents: .TouchDragEnter)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        configure()
    }
    
    func configure() {
        rectShape.opacity = 0.5
        rectShape.bounds = CGRectMake(0, 0, 20, 20)
        rectShape.position = CGPoint(x: CGRectGetMidX(bounds), y: CGRectGetMidY(bounds))
        rectShape.cornerRadius = bounds.height / 2
        rectShape.path = UIBezierPath(ovalInRect: rectShape.bounds).CGPath
        rectShape.fillColor = UIColor.midnightBlue().CGColor
    }
    
    func buttonHighlight(sender: UIButton) {
        
        layer.insertSublayer(rectShape, atIndex: 0)
        
        let timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        let animationDuration = 0.25
        
        let sizingAnimation = CABasicAnimation(keyPath: "transform.scale")
        sizingAnimation.fromValue = 1
        sizingAnimation.toValue = 20
        sizingAnimation.timingFunction = timingFunction
        sizingAnimation.duration = animationDuration
        sizingAnimation.removedOnCompletion = false
        sizingAnimation.fillMode = kCAFillModeForwards
    
        rectShape.addAnimation(sizingAnimation, forKey: nil)
    }
    
    func buttonNormal(sender: UIButton) {
        
        let timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        let animationDuration = 0.25
        
        let sizingAnimation = CABasicAnimation(keyPath: "transform.scale")
        sizingAnimation.fromValue = 20
        sizingAnimation.toValue = 0
        sizingAnimation.timingFunction = timingFunction
        sizingAnimation.duration = animationDuration
        sizingAnimation.removedOnCompletion = false
        sizingAnimation.fillMode = kCAFillModeForwards
        
        rectShape.addAnimation(sizingAnimation, forKey: nil)
    }


}

extension UIImage {
    class func imageWithColor(color: UIColor) -> UIImage {
        let rect = CGRectMake(0, 0, 1.0, 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillRect(context, rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }

}