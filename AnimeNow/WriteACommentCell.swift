//
//  WriteACommentCell.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 7/31/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation

public class WriteACommentCell: UITableViewCell {
    public class func registerNibFor(tableView tableView: UITableView) {

        let listNib = UINib(nibName: "WriteACommentCell", bundle: ANCommonKit.bundle())
        tableView.registerNib(listNib, forCellReuseIdentifier: "WriteACommentCell")
    }
}