//
//  UIImageView+SDWebImage.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/10/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit
import SDWebImage

extension UIImageView {
    
    public func setImageFrom(urlString urlString:String!, animated:Bool = false, options: SDWebImageOptions? = nil)
    {
        if let url = NSURL(string: urlString) {
            if !animated {
                if let options = options {
                    self.sd_setImageWithURL(url, placeholderImage: nil, options: options)
                } else {
                    self.sd_setImageWithURL(url, placeholderImage: nil)
                }
            } else {
                self.layer.removeAllAnimations()
                self.sd_cancelCurrentImageLoad()

                if let options = options {
                    self.sd_setImageWithURL(url, placeholderImage: nil, options: options, completed: { (image, error, cacheType, url) -> Void in
                        self.alpha = 0
                        UIView.transitionWithView(self, duration: 0.5, options: [], animations: { () -> Void in
                            self.image = image
                            self.alpha = 1
                            }, completion: nil)
                    })
                } else {
                    self.sd_setImageWithURL(url, placeholderImage: nil, completed: { (image, error, cacheType, url) -> Void in
                        self.alpha = 0
                        UIView.transitionWithView(self, duration: 0.5, options: [], animations: { () -> Void in
                            self.image = image
                            self.alpha = 1
                            }, completion: nil)
                    })
                }
            }
        }
    }
}