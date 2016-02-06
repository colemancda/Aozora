//
//  TTTAttributedLabel+Tags.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 8/24/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import TTTAttributedLabel
import Parse

extension TTTAttributedLabel {
    public func updateTags(tags: [PFObject], delegate: TTTAttributedLabelDelegate, addLinks: Bool = true) {
        linkAttributes = [kCTForegroundColorAttributeName: UIColor.peterRiver()]
        textColor = UIColor.peterRiver()
        self.delegate = delegate
        
        var tagsString = ""
        
        for tag in tags {
            if let tag = tag as? ThreadTag {
                tagsString += "#\(tag.name)  "
            } else if let anime = tag as? Anime {
                tagsString += "#\(anime.title!)  "
            }
        }
        
        setText(tagsString, afterInheritingLabelAttributesAndConfiguringWithBlock: { (attributedString) -> NSMutableAttributedString! in
            return attributedString
        })
        
        if addLinks {
            var idx = 0
            for tag in tags {
                var tagName: String?
                if let tag = tag as? ThreadTag {
                    tagName = "#\(tag.name)  "
                } else if let anime = tag as? Anime {
                    tagName = "#\(anime.title!)  "
                }
                
                if let tag = tagName {
                    let url = NSURL(string: "aozoraapp://tag/\(idx)")
                    let range = (tagsString as NSString).rangeOfString(tag)
                    addLinkToURL(url, withRange: range)
                    idx += 1
                }
            }
        }
    }
}