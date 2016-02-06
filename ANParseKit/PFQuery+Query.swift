//
//  PFQuery+Query.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 11/3/15.
//  Copyright © 2015 AnyTap. All rights reserved.
//

import Foundation
import Parse
import Bolts

extension PFQuery {
    
    public func findAllObjectsInBackground(with skip: Int? = 0) -> BFTask {

        limit = 1000
        self.skip = skip!
    
        return findObjectsInBackground()
            .continueWithBlock { (task: BFTask!) -> BFTask! in
                
                let result = task.result as! [PFObject]
                if result.count == self.limit {
                    return self.findAllObjectsInBackground(with: self.skip + self.limit)
                        .continueWithBlock({ (previousTask: BFTask!) -> AnyObject! in
                            let newResults = previousTask.result as! [PFObject]
                            return BFTask(result: result+newResults)
                        })
                } else {
                    return task
                }
        }
    }
}