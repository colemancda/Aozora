//
//  ThreadViewController.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 8/7/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit
import ANCommonKit
import TTTAttributedLabel
import XCDYouTubeKit
import Parse
import ANParseKit

// Class intended to be subclassed
public class ThreadViewController: UIViewController {
   
    public let FetchLimit = 12
    
    @IBOutlet public weak var tableView: UITableView!
    
    public var thread: Thread?
    public var threadType: ThreadType!
    
    public var fetchController = FetchController()
    public var refreshControl = UIRefreshControl()
    public var loadingView: LoaderView!
    
    var animator: ZFModalTransitionAnimator!
    var playerController: XCDYouTubeVideoPlayerViewController?
    
    var baseWidth: CGFloat {
        get {
            if UIDevice.isPad() {
                return 600
            } else {
                return view.bounds.size.width
            }
        }
    }
    
    public func initWithThread(thread: Thread) {
        self.thread = thread
        self.threadType = .Custom
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "moviePlayerPlaybackDidFinish:", name: MPMoviePlayerPlaybackDidFinishNotification, object: nil)
        
        tableView.alpha = 0.0
        tableView.estimatedRowHeight = 112.0
        tableView.rowHeight = UITableViewAutomaticDimension
        
        CommentCell.registerNibFor(tableView: tableView)
        LinkCell.registerNibFor(tableView: tableView)
        WriteACommentCell.registerNibFor(tableView: tableView)
        ShowMoreCell.registerNibFor(tableView: tableView)
        
        loadingView = LoaderView(parentView: view)
        addRefreshControl(refreshControl, action:"fetchPosts", forTableView: tableView)
        
        if let thread = thread {
            updateUIWithThread(thread)
        } else {
            fetchThread()
        }
        
    }
    
    deinit {
        fetchController.tableView = nil
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    public func updateUIWithThread(thread: Thread) {
        fetchPosts()
    }
    
    // MARK: - Fetching
    public func fetchThread() {
        
    }
    
    public func fetchPosts() {

    }
    
    // MARK: - Internal functions
    
    public func openProfile(user: User) {
        if let profileController = self as? ProfileViewController {
            if profileController.userProfile != user && !user.isTheCurrentUser() {
                openProfileNow(user)
            }
        } else if !user.isTheCurrentUser() {
            openProfileNow(user)
        }
    }
    
    func openProfileNow(user: User? = nil, username: String? = nil) {
        let profileController = ANAnimeKit.profileViewController()
        if let user = user  {
            profileController.initWithUser(user)
        } else if let username = username {
            profileController.initWithUsername(username)
        }

        navigationController?.pushViewController(profileController, animated: true)
    }
    
    public func showImage(imageURLString: String, imageView: UIImageView) {
        if let imageURL = NSURL(string: imageURLString) {
            presentImageViewController(imageView, imageUrl: imageURL)
        }
    }
    
    public func playTrailer(videoID: String) {
        playerController = XCDYouTubeVideoPlayerViewController(videoIdentifier: videoID)
        presentMoviePlayerViewControllerAnimated(playerController)
    }
    
    public func replyTo(post: Commentable) {
        guard User.currentUserLoggedIn() else {
            presentBasicAlertWithTitle("Login first", message: "Select 'Me' tab")
            return
        }
        
        let comment = ANParseKit.newPostViewController()
        if let post = post as? ThreadPostable, let thread = thread where !thread.locked {
            if thread.locked {
                presentBasicAlertWithTitle("Thread is locked")
            } else {
                comment.initWith(thread, threadType: threadType, delegate: self, parentPost: post)
                animator = presentViewControllerModal(comment)
            }
            
        } else if let post = post as? TimelinePostable {
            comment.initWithTimelinePost(self, postedIn:post.userTimeline, parentPost: post)
            animator = presentViewControllerModal(comment)
        }
    }
    
    func shouldShowAllRepliesForPost(post: Commentable, forIndexPath indexPath: NSIndexPath? = nil) -> Bool {
        var indexPathIsSafe = true
        if let indexPath = indexPath {
            indexPathIsSafe = indexPath.row - 1 < post.replies.count
        }
        return (post.replies.count <= 3 || post.showAllReplies) && indexPathIsSafe
    }
    
    func shouldShowContractedRepliesForPost(post: Commentable, forIndexPath indexPath: NSIndexPath) -> Bool {
        return post.replies.count > 3 && indexPath.row < 5
    }
    
    func indexForContactedReplyForPost(post: Commentable, forIndexPath indexPath: NSIndexPath) -> Int {
        return post.replies.count - 5 + indexPath.row
    }
    
    public func postForCell(cell: UITableViewCell) -> Commentable? {
        if let indexPath = tableView.indexPathForCell(cell), let post = fetchController.objectAtIndex(indexPath.section) as? Commentable {
            if indexPath.row == 0 {
                return post
            // TODO organize this code better it has dup lines everywhere D:
            } else if shouldShowAllRepliesForPost(post, forIndexPath: indexPath) {
                return post.replies[indexPath.row - 1] as? Commentable
            } else if shouldShowContractedRepliesForPost(post, forIndexPath: indexPath) {
                let index = indexForContactedReplyForPost(post, forIndexPath: indexPath)
                return post.replies[index] as? Commentable
            }
        }
        
        return nil
    }
    
    public func like(post: Commentable) {
        if !User.currentUserLoggedIn() {
            presentBasicAlertWithTitle("Login first", message: "Select 'Me' tab")
            return
        }
        
        if let post = post as? PFObject where !post.dirty {
            let likedBy = (post as! Commentable).likedBy ?? []
            let currentUser = User.currentUser()!
            if likedBy.contains(currentUser) {
                post.removeObject(currentUser, forKey: "likedBy")
            } else {
                post.addUniqueObject(currentUser, forKey: "likedBy")
            }
            post.saveInBackground()
        }
    }
    
    // MARK: - IBAction
    
    @IBAction public func dismissPressed(sender: AnyObject) {
        navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction public func replyToThreadPressed(sender: AnyObject) {
        
    }
}


extension ThreadViewController: UITableViewDataSource {
    
    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchController.dataCount()
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let post = fetchController.objectInSection(section) as! Commentable
        if post.replies.count > 0 {
            if shouldShowAllRepliesForPost(post) {
                return 1 + (post.replies.count ?? 0) + 1
            } else {
                // 1 post, 1 show more, 3 replies, 1 reply to post
                return 1 + 1 + 3 + 1
            }
        } else {
            return 1
        }
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var post = fetchController.objectAtIndex(indexPath.section) as! Commentable
        
        if indexPath.row == 0 {
            
            var reuseIdentifier = ""
            if post.imagesData?.count != 0 || post.youtubeID != nil {
                // Post image or video cell
                reuseIdentifier = "PostImageCell"
            } else if post.linkData != nil {
                // Post link cell
                reuseIdentifier = "LinkCell"
            } else {
                // Text post update
                reuseIdentifier = "PostTextCell"
            }
            
            let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier) as! PostCell
            cell.delegate = self
            updateCell(cell, withPost: post)
            cell.layoutIfNeeded()
            return cell
            
        } else if shouldShowAllRepliesForPost(post, forIndexPath: indexPath) {
            
            let replyIndex = indexPath.row - 1
            return reuseCommentCellFor(post, replyIndex: replyIndex)
            
        } else if shouldShowContractedRepliesForPost(post, forIndexPath: indexPath) {
            // Show all
            if indexPath.row == 1 {
                let cell = tableView.dequeueReusableCellWithIdentifier("ShowMoreCell") as! ShowMoreCell
                cell.layoutIfNeeded()
                return cell
            } else {
                let replyIndex = indexForContactedReplyForPost(post, forIndexPath: indexPath)
                return reuseCommentCellFor(post, replyIndex: replyIndex)
            }
        } else {
            
            // Write a comment cell
            let cell = tableView.dequeueReusableCellWithIdentifier("WriteACommentCell") as! WriteACommentCell
            cell.layoutIfNeeded()
            return cell
        }
    }
    
    func reuseCommentCellFor(comment: Commentable, replyIndex: Int) -> CommentCell {
        var comment = comment.replies[replyIndex] as! Commentable
        
        var reuseIdentifier = ""
        if comment.imagesData?.count != 0 || comment.youtubeID != nil {
            // Comment image cell
            reuseIdentifier = "CommentImageCell"
        } else {
            // Text comment update
            reuseIdentifier = "CommentTextCell"
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier) as! CommentCell
        cell.delegate = self
        updateCell(cell, withPost: comment)
        cell.layoutIfNeeded()
        return cell
    }
    
    func updateCell(cell: PostCell, var withPost post: Commentable) {
        // Updates to both styles
        
        // Text content
        var textContent = ""
        if let content = post.content {
            textContent = content
        }
        
        // Setting images and youtube
        if post.hasSpoilers && post.isSpoilerHidden {
            textContent += "\n\n(Show Spoilers)"
            cell.imageHeightConstraint?.constant = 0
            cell.playButton?.hidden = true
        } else {
            if let spoilerContent = post.spoilerContent {
                textContent += "\n\n\(spoilerContent)"
            }
            let calculatedBaseWidth = post.replyLevel == 0 ? baseWidth : baseWidth - 60
            setImages(post.imagesData, imageView: cell.imageContent, imageHeightConstraint: cell.imageHeightConstraint, baseWidth: calculatedBaseWidth)
            prepareForVideo(cell.playButton, imageView: cell.imageContent, imageHeightConstraint: cell.imageHeightConstraint, youtubeID: post.youtubeID)
        }
        
        // Poster information
        if let postedBy = post.postedBy, let avatarFile = postedBy.avatarThumb {
            cell.avatar.setImageWithPFFile(avatarFile)
            cell.username?.text = postedBy.aozoraUsername
            cell.onlineIndicator.hidden = !postedBy.active
        }
        
        // Edited date
        cell.date.text = post.createdDate?.timeAgo()
        if var postedAgo = cell.date.text where post.edited {
            postedAgo += " · Edited"
            cell.date.text = postedAgo
        }
        
        // Like button
        updateLikeButton(cell, post: post)
        
        let postedByUsername = post.postedBy?.aozoraUsername ?? ""
        // Updates to each style
        if let _ = cell as? CommentCell {
            textContent = postedByUsername + " " + textContent
        } else {
            updatePostCell(cell, withPost: post)
        }
        
        // Adding links to text content
        updateAttributedTextProperties(cell.textContent)
        cell.textContent.setText(textContent, afterInheritingLabelAttributesAndConfiguringWithBlock: { (attributedString) -> NSMutableAttributedString! in
            return attributedString
        })
        
        if let encodedUsername = postedByUsername.stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet()),
            let url = NSURL(string: "aozoraapp://profile/"+encodedUsername) {
                let range = (textContent as NSString).rangeOfString(postedByUsername)
                cell.textContent.addLinkToURL(url, withRange: range)
        }
    }
    
    func updatePostCell(cell: PostCell, var withPost post: Commentable) {
        
        // Only embed links on post cells for now
        if let linkCell = cell as? LinkCell, let linkData = post.linkData, let linkUrl = linkData.url {
            linkCell.linkDelegate = self
            linkCell.linkTitleLabel.text = linkData.title
            linkCell.linkContentLabel.text = linkData.description
            linkCell.linkUrlLabel.text = NSURL(string: linkUrl)?.host?.uppercaseString
            if let imageURL = linkData.imageUrls.first {
                linkCell.imageContent?.setImageFrom(urlString: imageURL, animated: false)
                linkCell.imageHeightConstraint?.constant = (baseWidth - 16) * CGFloat(158)/CGFloat(305)
            } else {
                linkCell.imageContent?.image = nil
                linkCell.imageHeightConstraint?.constant = 0
            }
        }

        // From and to information
        if let timelinePostable = post as? TimelinePostable, postedBy = post.postedBy where timelinePostable.userTimeline != postedBy {
            cell.toUsername?.text = timelinePostable.userTimeline.aozoraUsername
            cell.toIcon?.text = ""
        } else {
            cell.toUsername?.text = ""
            cell.toIcon?.text = ""
        }
        
        // Reply button
        let repliesTitle = repliesButtonTitle(post.replies.count)
        cell.replyButton.setTitle(repliesTitle, forState: .Normal)
    }
    
    public func setImages(images: [ImageData]?, imageView: UIImageView?, imageHeightConstraint: NSLayoutConstraint?, baseWidth: CGFloat) {
        if let image = images?.first {
            imageHeightConstraint?.constant = baseWidth * CGFloat(image.height)/CGFloat(image.width)
            imageView?.setImageFrom(urlString: image.url, animated: false)
        } else {
            imageHeightConstraint?.constant = 0
        }
    }
    
    public func repliesButtonTitle(repliesCount: Int) -> String {
        if repliesCount > 0 {
            return " \(repliesCount)"
        } else {
            return " "
        }
    }
    
    public func prepareForVideo(playButton: UIButton?, imageView: UIImageView?, imageHeightConstraint: NSLayoutConstraint?, youtubeID: String?) {
        if let playButton = playButton {
            if let youtubeID = youtubeID {
                let urlString = "https://i.ytimg.com/vi/\(youtubeID)/maxresdefault.jpg"
                imageView?.setImageFrom(urlString: urlString, animated: false)
                imageHeightConstraint?.constant = baseWidth * CGFloat(180)/CGFloat(340)
                
                playButton.hidden = false
                playButton.layer.borderWidth = 1.0;
                playButton.layer.borderColor = UIColor(white: 1.0, alpha: 0.5).CGColor;
            } else {
                playButton.hidden = true
            }
        }
    }
    
    func updateAttributedTextProperties(textContent: TTTAttributedLabel) {
        textContent.linkAttributes = [kCTForegroundColorAttributeName: UIColor.peterRiver()]
        textContent.enabledTextCheckingTypes = NSTextCheckingType.Link.rawValue
        textContent.delegate = self;
    }
    
    func updateLikeButton(cell: PostCell, post: Commentable) {
        if let likedBy = post.likedBy where likedBy.count > 0 {
            cell.likeButton.setTitle(" \(likedBy.count)", forState: .Normal)
        } else {
            cell.likeButton.setTitle(" ", forState: .Normal)
        }
        
        if let likedBy = post.likedBy, let currentUser = User.currentUser() where likedBy.contains(currentUser) {
            cell.likeButton.setImage(UIImage(named: "icon-like-red"), forState: .Normal)
        } else {
            cell.likeButton.setImage(UIImage(named: "icon-like-gray"), forState: .Normal)
        }
    }
}

extension ThreadViewController: UITableViewDelegate {
    public func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.1
    }
    
    public func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UIDevice.isPad() ? 6.0 : 4.0
    }
    
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        var post = fetchController.objectAtIndex(indexPath.section) as! Commentable
        
        if indexPath.row == 0 {
            if post.hasSpoilers && post.isSpoilerHidden == true {
                post.isSpoilerHidden = false
                tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            } else {
                showSheetFor(post: post, indexPath: indexPath)
            }
            
        } else if shouldShowAllRepliesForPost(post, forIndexPath: indexPath) {
            if let comment = post.replies[indexPath.row - 1] as? Commentable {
                pressedOnAComment(post, comment: comment, indexPath: indexPath)
            }
        } else if shouldShowContractedRepliesForPost(post, forIndexPath: indexPath) {
            // Show all
            if indexPath.row == 1 {
                post.showAllReplies = true
                tableView.reloadData()
            } else {
                let index = indexForContactedReplyForPost(post, forIndexPath: indexPath)
                if let comment = post.replies[index] as? Commentable {
                    pressedOnAComment(post, comment: comment, indexPath: indexPath)
                }
            }
        } else {
            // Write a comment cell
            replyTo(post)
        }
    }
    func pressedOnAComment(post: Commentable, var comment: Commentable, indexPath: NSIndexPath) {
        if comment.hasSpoilers && comment.isSpoilerHidden == true {
            comment.isSpoilerHidden = false
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        } else {
            showSheetFor(post: comment, parentPost: post, indexPath: indexPath)
        }
    }
    func showSheetFor(post post: Commentable, parentPost: Commentable? = nil, indexPath: NSIndexPath) {
        // If user's comment show delete/edit
        
        guard let currentUser = User.currentUser(), let postedBy = post.postedBy, let cell = tableView.cellForRowAtIndexPath(indexPath) else {
            return
        }
        
        let administrating = currentUser.isAdmin() && !postedBy.isAdmin() || currentUser.isTopAdmin()
        if let postedBy = post.postedBy where postedBy.isTheCurrentUser() ||
            // Current user is admin and posted by non-admin user
            administrating {
            
                let alert: UIAlertController!
                
                if administrating {
                    alert = UIAlertController(title: "Warning: Editing \(postedBy.aozoraUsername) post", message: "Only edit user posts if they are breaking guidelines", preferredStyle: UIAlertControllerStyle.ActionSheet)
                    alert.popoverPresentationController?.sourceView = cell.superview
                    alert.popoverPresentationController?.sourceRect = cell.frame
                } else {
                    alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
                    alert.popoverPresentationController?.sourceView = cell.superview
                    alert.popoverPresentationController?.sourceRect = cell.frame
                }
                
                alert.addAction(UIAlertAction(title: "Edit", style: administrating ? UIAlertActionStyle.Destructive : UIAlertActionStyle.Default, handler: { (alertAction: UIAlertAction!) -> Void in
                    let comment = ANParseKit.newPostViewController()
                    if let post = post as? TimelinePost {
                        comment.initWithTimelinePost(self, postedIn: currentUser, editingPost: post)
                    } else if let post = post as? Post, let thread = self.thread {
                        comment.initWith(thread, threadType: self.threadType, delegate: self, editingPost: post)
                    }
                    self.animator = self.presentViewControllerModal(comment)
                }))

                alert.addAction(UIAlertAction(title: "Delete", style: UIAlertActionStyle.Destructive, handler: { (alertAction: UIAlertAction!) -> Void in
                    if let post = post as? PFObject {
                        if let parentPost = parentPost as? PFObject {
                            // Just delete child post
                            self.deletePosts([post], parentPost: parentPost, removeParent: false)
                        } else {
                            // This is parent post, remove child too
                            var className = ""
                            if let _ = post as? Post {
                                className = "Post"
                            } else if let _ = post as? TimelinePost {
                                className = "TimelinePost"
                            }
                            
                            let childPostsQuery = PFQuery(className: className)
                            childPostsQuery.whereKey("parentPost", equalTo: post)
                            childPostsQuery.findObjectsInBackgroundWithBlock({ (result, error) -> Void in
                                if let result = result {
                                    self.deletePosts(result, parentPost: post, removeParent: true)
                                } else {
                                    // TODO: Show error
                                }
                            })
                        }
                    }
                }))
                
                
                alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler:nil))
                
                self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func deletePosts(childPosts: [PFObject] = [], parentPost: PFObject, removeParent: Bool) {
        var allPosts = childPosts
        
        if removeParent {
            allPosts.append(parentPost)
        }
        
        PFObject.deleteAllInBackground(allPosts, block: { (success, error) -> Void in
            if let _ = error {
                // Show some error
            } else {
                
                func decrementPostCount() {
                    for post in allPosts {
                        (post["postedBy"] as? User)?.incrementPostCount(-1)
                    }
                }
                
                if let thread = self.thread where !thread.isForumGame {
                    // Decrement post counts only if thread does not contain #ForumGame tag
                    decrementPostCount()
                } else {
                    decrementPostCount()
                }
                
                self.thread?.incrementReplyCount(byAmount: -allPosts.count)
                self.thread?.saveInBackground()
                
                if removeParent {
                    // Delete parent post, and entire section
                    if let section = self.fetchController.dataSource.indexOf(parentPost) {
                        self.fetchController.dataSource.removeAtIndex(section)
                        self.tableView.reloadData()
                    }
                } else {
                    // Delete child post
                    var parentPost = parentPost as! Commentable
                    if let index = parentPost.replies.indexOf(childPosts.last!) {
                        parentPost.replies.removeAtIndex(index)
                        self.tableView.reloadData()
                    }
                }
            }
        })
    }
    
    func moviePlayerPlaybackDidFinish(notification: NSNotification) {
        playerController = nil;
    }
}

extension ThreadViewController: FetchControllerDelegate {
    public func didFetchFor(skip skip: Int) {
        refreshControl.endRefreshing()
    }
}

extension ThreadViewController: TTTAttributedLabelDelegate {
    
    public func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL url: NSURL!) {
        
        if let host = url.host where host == "profile",
            let username = url.pathComponents?[1] {
                let isNotCurrentUser = username != User.currentUser()!.aozoraUsername
                if let profileController = self as? ProfileViewController {
                    if profileController.userProfile?.aozoraUsername != username && isNotCurrentUser {
                        openProfileNow(username: username)
                    }
                } else if isNotCurrentUser {
                    openProfileNow(username: username)
                }
            
        } else if url.scheme != "aozoraapp" {
            let (navController, webController) = ANParseKit.webViewController()
            webController.initWithInitialUrl(url)
            presentViewController(navController, animated: true, completion: nil)
        }
    }
}

extension ThreadViewController: CommentViewControllerDelegate {
    public func commentViewControllerDidFinishedPosting(newPost: PFObject, parentPost: PFObject?, edited: Bool) {
        if let thread = newPost as? Thread {
            self.thread = thread
        }
    }
}

extension ThreadViewController: PostCellDelegate {
    public func postCellSelectedImage(postCell: PostCell) {
        if var post = postForCell(postCell), let imageView = postCell.imageContent {
            print(post)
            if let imageData = post.imagesData?.first {
                showImage(imageData.url, imageView: imageView)
            } else if let videoID = post.youtubeID {
                playTrailer(videoID)
            }
        }
    }
    
    public func postCellSelectedUserProfile(postCell: PostCell) {
        if let post = postForCell(postCell), let postedByUser = post.postedBy {
            openProfile(postedByUser)
        }
    }
    
    public func postCellSelectedComment(postCell: PostCell) {
        if let post = postForCell(postCell) {
            replyTo(post)
        }
    }
    
    public func postCellSelectedToUserProfile(postCell: PostCell) {
        if let post = postForCell(postCell) as? TimelinePostable {
            openProfile(post.userTimeline)
        }
    }
    
    public func postCellSelectedLike(postCell: PostCell) {
        if let post = postForCell(postCell) {
            like(post)
            updateLikeButton(postCell, post: post)
        }
    }
}

extension ThreadViewController: LinkCellDelegate {
    public func postCellSelectedLink(linkCell: LinkCell) {
        guard let indexPath = tableView.indexPathForCell(linkCell),
            var postable = fetchController.objectAtIndex(indexPath.section) as? Commentable,
            let linkData = postable.linkData,
            let url = linkData.url else {
            return
        }
        
        let (navController, webController) = ANParseKit.webViewController()
        let initialUrl = NSURL(string: url)
        webController.initWithInitialUrl(initialUrl)
        presentViewController(navController, animated: true, completion: nil)
    }
}

extension ThreadViewController: FetchControllerQueryDelegate {
    
    public func queriesForSkip(skip skip: Int) -> [PFQuery]? {
        let query = PFQuery()
        return [query]
    }
    
    public func processResult(result result: [PFObject], dataSource: [PFObject]) -> [PFObject] {
        
        let posts = result.filter({ $0["replyLevel"] as? Int == 0 })
        let replies = result.filter({ $0["replyLevel"] as? Int == 1 })
        
        // If page 0 was loaded and there are new posts, page 1 could return repeated results,
        // For this, we need to remove duplicates
        var searchIn: [PFObject] = []
        if dataSource.count > result.count {
            let b = dataSource.count
            let a = b-result.count
            searchIn = Array(dataSource[a..<b])
        } else {
            searchIn = dataSource
        }
        var uniquePosts: [PFObject] = []
        for post in posts {
            let exists = searchIn.filter({$0.objectId! == post.objectId!})
            if exists.count == 0 {
                uniquePosts.append(post)
            }
        }
        
        for post in uniquePosts {
            let postReplies = replies.filter({ ($0["parentPost"] as! PFObject) == post }) as [PFObject]
            var postable = post as! Commentable
            postable.replies = postReplies
        }

        return uniquePosts
    }
}

extension ThreadViewController: ModalTransitionScrollable {
    public var transitionScrollView: UIScrollView? {
        return tableView
    }
}