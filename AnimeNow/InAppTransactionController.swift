//
//  InAppPurchaseController.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 7/9/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import RMStore
import ANParseKit

let PurchasedProNotification = "InApps.Purchased.Pro"

class InAppTransactionController {
    
    class func purchaseProductWithID(productID: String) -> BFTask {
        let completionSource = BFTaskCompletionSource()
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        RMStore.defaultStore().addPayment(productID, success: { (transaction: SKPaymentTransaction!) -> Void in
            self.purchaseCompleted([transaction])
            completionSource.setResult([transaction])
        }) { (transaction: SKPaymentTransaction!, error: NSError!) -> Void in
            self.purchaseFailed(nil, error: error)
            completionSource.setError(error)
        }
        
        return completionSource.task
    }
    
    class func restorePurchases() -> BFTask {
        let completionSource = BFTaskCompletionSource()
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        RMStore.defaultStore().restoreTransactionsOnSuccess({ (transactions) -> Void in
            let allTransactions = transactions as! [SKPaymentTransaction]
            self.purchaseCompleted(allTransactions)
            completionSource.setResult(allTransactions)
        }, failure: { (error) -> Void in
            self.purchaseFailed(nil, error: error)
            completionSource.setError(error)
        })
        
        return completionSource.task
    }
    
    class func purchaseCompleted(transactions: [SKPaymentTransaction]) {
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        
        for transaction in transactions {
            let productIdentifier = transaction.payment.productIdentifier
            
            if productIdentifier == ProPlusInAppPurchase {
                User.currentUser()!.addUniqueObject("PRO+", forKey: "badges")
            } else if productIdentifier == ProInAppPurchase {
                User.currentUser()!.addUniqueObject("PRO", forKey: "badges")
            }
            User.currentUser()!.saveInBackground()
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: productIdentifier)
        }
        NSUserDefaults.standardUserDefaults().synchronize()
        
        // Unlock..
        NSNotificationCenter.defaultCenter().postNotificationName(PurchasedProNotification, object: nil)
        
    }
    
    class func purchaseFailed(transaction: SKPaymentTransaction?, error: NSError) {
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        
        let alert = UIAlertController(title: "Payment Transaction Failed", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        
        if let window = UIApplication.sharedApplication().delegate?.window {
            window?.rootViewController!.presentViewController(alert, animated: true, completion: nil)
        }

    }
}