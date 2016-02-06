//
//  InAppBrowserSelectorViewController.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 8/6/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import WebKit
import ANCommonKit

public protocol InAppBrowserSelectorViewControllerDelegate: class {
    func inAppBrowserSelectorViewControllerSelectedSite(siteURL: String)
}

public class InAppBrowserSelectorViewController: InAppBrowserViewController {
    
    public weak var delegate: InAppBrowserSelectorViewControllerDelegate?
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        // Insert UIBarButtonAction
        let selectBBI = UIBarButtonItem(title: "Select", style: UIBarButtonItemStyle.Plain, target: self, action: "selectedWebSite:")
        navigationItem.rightBarButtonItem = selectBBI
    }
    
    func selectedWebSite(sender: AnyObject) {
        if let urlString = webView.URL?.absoluteString {
            delegate?.inAppBrowserSelectorViewControllerSelectedSite(urlString)
        }
        dismissViewControllerAnimated(true, completion: nil)
    }

}
