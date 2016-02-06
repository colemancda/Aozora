//
//  UIImageView+PFFile.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 7/31/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import Parse

extension UIImageView {
    public func setImageWithPFFile(file: PFFile, animated: Bool = false) {
        if let url = file.url {
            self.setImageFrom(urlString: url, animated: animated)
        }
    }
}