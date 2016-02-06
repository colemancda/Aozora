//
//  PostCell.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 7/28/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import TTTAttributedLabel

public protocol PostCellDelegate: class {
    func postCellSelectedImage(postCell: PostCell)
    func postCellSelectedUserProfile(postCell: PostCell)
    func postCellSelectedToUserProfile(postCell: PostCell)
    func postCellSelectedComment(postCell: PostCell)
    func postCellSelectedLike(postCell: PostCell)
}

public class PostCell: UITableViewCell {
    
    @IBOutlet weak public var avatar: UIImageView!
    @IBOutlet weak public var username: UILabel?
    @IBOutlet weak public var date: UILabel!
    
    @IBOutlet weak public var toIcon: UILabel?
    @IBOutlet weak public var toUsername: UILabel?
    
    @IBOutlet weak public var imageContent: UIImageView?
    @IBOutlet weak public var imageHeightConstraint: NSLayoutConstraint?
    @IBOutlet weak public var textContent: TTTAttributedLabel!
    @IBOutlet weak public var onlineIndicator: UIImageView!
    
    @IBOutlet weak public var replyButton: UIButton!
    @IBOutlet weak public var likeButton: UIButton!
    @IBOutlet weak public var playButton: UIButton?
    
    public weak var delegate: PostCellDelegate?
    
    public enum PostType {
        case Text
        case Image
        case Image2
        case Image3
        case Image4
        case Image5
        case Video
    }
    
    public class func registerNibFor(tableView tableView: UITableView) {

        let listNib = UINib(nibName: "PostTextCell", bundle: ANCommonKit.bundle())
        tableView.registerNib(listNib, forCellReuseIdentifier: "PostTextCell")
        let listNib2 = UINib(nibName: "PostImageCell", bundle: ANCommonKit.bundle())
        tableView.registerNib(listNib2, forCellReuseIdentifier: "PostImageCell")
        
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        
        do {
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: "pressedUserProfile:")
            gestureRecognizer.numberOfTouchesRequired = 1
            gestureRecognizer.numberOfTapsRequired = 1
            avatar.addGestureRecognizer(gestureRecognizer)
        }
        
        if let imageContent = imageContent {
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: "pressedOnImage:")
            gestureRecognizer.numberOfTouchesRequired = 1
            gestureRecognizer.numberOfTapsRequired = 1
            imageContent.addGestureRecognizer(gestureRecognizer)
        }
        
        if let username = username {
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: "pressedUserProfile:")
            gestureRecognizer.numberOfTouchesRequired = 1
            gestureRecognizer.numberOfTapsRequired = 1
            username.addGestureRecognizer(gestureRecognizer)
        }
        
        if let toUsername = toUsername {
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: "pressedToUserProfile:")
            gestureRecognizer.numberOfTouchesRequired = 1
            gestureRecognizer.numberOfTapsRequired = 1
            toUsername.addGestureRecognizer(gestureRecognizer)
        }
        
    }
    
    // MARK: - IBActions
    
    func pressedUserProfile(sender: AnyObject) {
        delegate?.postCellSelectedUserProfile(self)
    }
    
    func pressedToUserProfile(sender: AnyObject) {
        delegate?.postCellSelectedToUserProfile(self)
    }
    
    func pressedOnImage(sender: AnyObject) {
        delegate?.postCellSelectedImage(self)
    }
    
    @IBAction func replyPressed(sender: AnyObject) {
        delegate?.postCellSelectedComment(self)
        replyButton.animateBounce()
    }
    
    @IBAction func likePressed(sender: AnyObject) {
        delegate?.postCellSelectedLike(self)
        likeButton.animateBounce()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        textContent.preferredMaxLayoutWidth = textContent.frame.size.width
    }
    
    public override func prepareForReuse() {
        super.prepareForReuse()
        textContent.preferredMaxLayoutWidth = textContent.frame.size.width
    }
}
