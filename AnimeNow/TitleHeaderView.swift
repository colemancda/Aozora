//
//  TitleHeaderView.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 1/30/16.
//  Copyright © 2016 AnyTap. All rights reserved.
//

import Foundation

class TitleHeaderView: UITableViewCell {

    static let id = "TitleHeaderView"

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!

    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var actionContentView: UIView!

    var actionButtonCallback: (Int -> Void)?
    var section: Int = 0

    class func registerNibFor(tableView tableView: UITableView) {
        let chartNib = UINib(nibName: TitleHeaderView.id, bundle: nil)
        tableView.registerNib(chartNib, forCellReuseIdentifier: TitleHeaderView.id)
    }


    @IBAction func actionButtonPressed(sender: AnyObject) {
        actionButtonCallback?(section)
    }
}