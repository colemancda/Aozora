//
//  ActionListViewController.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/5/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit
public protocol ActionListDelegate: class {
    func selectedAction(action: String)
}
public class ActionListViewController: UIViewController {
    
    let CellHeight: Int = 44
    
    @IBOutlet weak var tableTopSpaceConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var titleLabel: UILabel!
    
    weak var delegate: ActionListDelegate?
    var dataSource = [String]()
    var actionTitle = ""
    var showTableView = true
    func setDataSource(dataSource: [String], title: String) {
        self.dataSource = dataSource
        actionTitle = title
        
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        // Set variables
        titleLabel.text = actionTitle
        
        // Set header height
        var headerRect = tableView.tableHeaderView?.bounds ?? CGRectZero
        let space = (dataSource.count+1)*CellHeight
        headerRect.size.height = CGRectGetHeight(view.bounds) - CGFloat(space)
        tableView.tableHeaderView?.bounds = headerRect
    }
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if showTableView {
            showTableView = false
            UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 0.85, initialSpringVelocity: 1.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                
                self.tableTopSpaceConstraint.constant = 0
                self.view.layoutIfNeeded()
                
                }) { (finished) -> Void in
                    
            }
        }
    }
    
    @IBAction func dismissPressed(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}

extension ActionListViewController: UITableViewDataSource {
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("OptionCell") as! BasicTableCell
        let title = dataSource[indexPath.row]
        cell.titleLabel.text = title
        return cell
    }
}

extension ActionListViewController: UITableViewDelegate {
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let action = dataSource[indexPath.row]
        delegate?.selectedAction(action)
        dismissPressed(self)
    }
}