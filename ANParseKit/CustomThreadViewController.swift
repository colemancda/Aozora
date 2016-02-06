//
//  AnimeThreadViewController.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 8/8/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import Parse
import TTTAttributedLabel
import ANCommonKit
import ANParseKit

public class CustomThreadViewController: ThreadViewController {
    
    @IBOutlet weak var imageContent: UIImageView!
    @IBOutlet weak var threadTitle: UILabel!
    @IBOutlet weak var threadContent: TTTAttributedLabel!
    @IBOutlet weak var tagsLabel: TTTAttributedLabel!
    @IBOutlet weak var avatar: UIImageView!
    @IBOutlet weak var username: UILabel!
    @IBOutlet weak var postedDate: UILabel!
    @IBOutlet weak var commentsButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var onlineIndicator: UIImageView!
    
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    
    var episode: Episode?
    var anime: Anime?
    
    public override func initWithThread(thread: Thread) {
        self.thread = thread
        self.threadType = .Custom
    }
    
    public func initWithEpisode(episode: Episode, anime: Anime) {
        self.episode = episode
        self.anime = anime
        self.threadType = .Episode
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override public func updateUIWithThread(thread: Thread) {
        super.updateUIWithThread(thread)
        
        title = "Loading..."
        
        threadContent.linkAttributes = [kCTForegroundColorAttributeName: UIColor.peterRiver()]
        threadContent.enabledTextCheckingTypes = NSTextCheckingType.Link.rawValue
        threadContent.delegate = self;
        
        if let _ = episode {
            updateUIWithEpisodeThread(thread)
        } else {
            updateUIWithGeneralThread(thread)
        }
        
        if thread.locked {
            commentsButton.setTitle("Locked", forState: .Normal)
            navigationItem.rightBarButtonItem?.enabled = false
        } else {
            let repliesTitle = repliesButtonTitle(thread.replyCount)
            commentsButton.setTitle(repliesTitle, forState: .Normal)
        }
        
        tagsLabel.updateTags(thread.tags, delegate: self)
        prepareForVideo(playButton, imageView: imageContent, imageHeightConstraint: imageHeightConstraint, youtubeID: thread.youtubeID)
    }
    
    var resizedTableHeader = false
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !resizedTableHeader && title != nil {
            resizedTableHeader = true
            sizeHeaderToFit()
        }
    }
    
    func updateUIWithEpisodeThread(thread: Thread) {
        
        moreButton.hidden = true
        if let episode = thread.episode, let anime = thread.anime, let animeTitle = anime.title {
            onlineIndicator.hidden = true
            if anime.type != "Movie" {
                threadTitle.text = episode.title ?? ""
                threadContent.text = episode.overview ?? ""
                title = "\(animeTitle) - Episode \(episode.number)"
                postedDate.text = episode.firstAired != nil ? "Aired on \(episode.firstAired!.mediumDate())" : ""
            } else {
                threadTitle.text = ""
                threadContent.text = ""
                title = animeTitle
                imageHeightConstraint.constant = 360
                postedDate.text = anime.startDate != nil ? "Movie aired on \(anime.startDate!.mediumDate())" : ""
                anime.details.fetchIfNeededInBackgroundWithBlock({ (details, error) -> Void in
                    if let _ = error {
                        
                    } else {
                        if let string = (details as! AnimeDetail).attributedSynopsis() {
                            print(string.string)
                            self.threadContent.text = string.string
                        } else {
                            self.threadContent.text = ""
                        }
                        
                        self.sizeHeaderToFit()
                    }
                })
            }
            username.text = title
            
            imageContent.setImageFrom(urlString: episode.imageURLString(), animated: true)
            avatar.setImageFrom(urlString: anime.imageUrl)
        }
    }
    
    func updateUIWithGeneralThread(var thread: Thread) {
        
        title = thread.title
        threadTitle.text = thread.title
        
        if let content = thread.content {
            threadContent.setText(content, afterInheritingLabelAttributesAndConfiguringWithBlock: { (attributedString) -> NSMutableAttributedString! in
                return attributedString
            })
        }
        
        // TODO: Merge this repeated code
        if let startedBy = thread.startedBy {
            if let avatarThumb = startedBy.avatarThumb {
                avatar.setImageWithPFFile(avatarThumb)
            }
            
            username.text = startedBy.aozoraUsername
            onlineIndicator.hidden = !startedBy.active
            var postedAt = thread.createdAt!.timeAgo()
            if thread.edited {
                postedAt += " · Edited"
            }
            postedDate.text = postedAt
            
            guard let currentUser = User.currentUser() else {
                return
            }
            
            let administrating = currentUser.isAdmin() && !startedBy.isAdmin() || currentUser.isTopAdmin()
            
            moreButton.hidden = startedBy != currentUser ?? false && !administrating
        }
        
        setImages(thread.imagesData, imageView: imageContent, imageHeightConstraint: imageHeightConstraint, baseWidth: baseWidth)
    }
    
    func sizeHeaderToFit() {
        guard let header = tableView.tableHeaderView else {
            return
        }
        
        header.setNeedsLayout()
        header.layoutIfNeeded()
        
        username.preferredMaxLayoutWidth = username.frame.size.width
        threadTitle.preferredMaxLayoutWidth = threadTitle.frame.size.width
        threadContent.preferredMaxLayoutWidth = threadContent.frame.size.width
        tagsLabel.preferredMaxLayoutWidth = tagsLabel.frame.size.width
        
        let height = header.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
        var frame = header.frame
        
        frame.size.height = height
        header.frame = frame
        tableView.tableHeaderView = header
    }
    
    override public func fetchThread() {
        super.fetchThread()

        let query = Thread.query()!
        query.limit = 1
        
        if let episode = episode {
            query.whereKey("episode", equalTo: episode)
            query.includeKey("episode")
        } else if let thread = thread, let objectId = thread.objectId {
            query.whereKey("objectId", equalTo: objectId)
        }
        
        query.includeKey("anime")
        query.includeKey("startedBy")
        query.includeKey("tags")
        query.findObjectsInBackgroundWithBlock({ (result, error) -> Void in
            
            if let _ = error {
                // TODO: Show error
            } else if let result = result, let thread = result.last as? Thread {
                self.thread = thread
                self.updateUIWithThread(thread)
            } else if let episode = self.episode, let anime = self.anime where self.threadType == ThreadType.Episode {
                
                // Create episode threads lazily
                let parameters = [
                    "animeID":anime.objectId!,
                    "episodeID":episode.objectId!,
                    "animeTitle": anime.title!,
                    "episodeNumber": anime.type == "Movie" ? -1 : episode.number
                ] as [String : AnyObject]
                
                PFCloud.callFunctionInBackground("createEpisodeThread", withParameters: parameters, block: { (result, error) -> Void in
                    
                    if let _ = error {
                        
                    } else {
                        print("Created episode thread")
                        self.fetchThread()
                    }
                })
            }
        })
        
    }
    
    override public func fetchPosts() {
        super.fetchPosts()
        fetchController.configureWith(self, queryDelegate: self, tableView: tableView, limit: FetchLimit, datasourceUsesSections: true)
    }
    
    // MARK: - FetchControllerQueryDelegate
    
    public override func queriesForSkip(skip skip: Int) -> [PFQuery]? {
        
        let innerQuery = Post.query()!
        innerQuery.skip = skip
        innerQuery.limit = FetchLimit
        innerQuery.whereKey("thread", equalTo: thread!)
        innerQuery.whereKey("replyLevel", equalTo: 0)
        innerQuery.orderByDescending("updatedAt")
        
        let query = innerQuery.copy() as! PFQuery
        query.includeKey("postedBy")
        
        let repliesQuery = Post.query()!
        repliesQuery.skip = 0
        repliesQuery.whereKey("parentPost", matchesKey: "objectId", inQuery: innerQuery)
        repliesQuery.orderByAscending("createdAt")
        repliesQuery.includeKey("postedBy")
        
        return [query, repliesQuery]
    }
    
    // MARK: - TTTAttributedLabelDelegate
    
    public override func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL url: NSURL!) {
        super.attributedLabel(label, didSelectLinkWithURL: url)
        
        if let host = url.host where host == "tag",
            let index = url.pathComponents?[1],
            let idx = Int(index) {
                if let thread = thread, let anime = thread.tags[idx] as? Anime {
                    self.animator = presentAnimeModal(anime)
                }
        }
    }
    
    // MARK: - CommentViewControllerDelegate

    public override func commentViewControllerDidFinishedPosting(post: PFObject, parentPost: PFObject?, edited: Bool) {
        super.commentViewControllerDidFinishedPosting(post, parentPost: parentPost, edited: edited)
        
        if let _ = post as? Postable {
            if edited {
                // Don't insert if edited
                tableView.reloadData()
                return
            }
            
            // Only posts and TimelinePosts
            if let parentPost = parentPost {
                // Inserting a new reply in-place
                var parentPost = parentPost as! Commentable
                parentPost.replies.append(post)
                tableView.reloadData()
            } else if parentPost == nil {
                // Inserting a new post in the top
                fetchController.dataSource.insert(post, atIndex: 0)
                tableView.reloadData()
            }
        } else if let thread = post as? Thread {
            updateUIWithThread(thread)
            sizeHeaderToFit()
        }
    }


    // MARK: - IBAction
    
    public override func replyToThreadPressed(sender: AnyObject) {
        super.replyToThreadPressed(sender)
        
        if let thread = thread where User.currentUserLoggedIn() {
            let comment = ANParseKit.newPostViewController()
            comment.initWith(thread, threadType: threadType, delegate: self)
            animator = presentViewControllerModal(comment)
        } else if let thread = thread where thread.locked {
            presentBasicAlertWithTitle("Thread is locked", message: nil)
        } else {
            presentBasicAlertWithTitle("Login first", message: "Select 'Me' tab")
        }
    }
    
    @IBAction func playTrailerPressed(sender: AnyObject) {
        if let thread = thread, let youtubeID = thread.youtubeID {
            playTrailer(youtubeID)
        }
    }
    
    @IBAction func openUserProfile(sender: AnyObject) {
        if let startedBy = thread?.startedBy {
            openProfile(startedBy)
        }
    }
    
    @IBAction func editThread(sender: AnyObject) {
        if let thread = thread {
            
            guard let currentUser = User.currentUser() else {
                return
            }
            let administrating = currentUser.isAdmin() && !thread.startedBy!.isAdmin() || currentUser.isTopAdmin()
            
            let alert: UIAlertController!
            
            if administrating {
                alert = UIAlertController(title: "NOTE: Editing \(thread.startedBy!.aozoraUsername) thread", message: "Only edit user threads if they are breaking guidelines", preferredStyle: UIAlertControllerStyle.ActionSheet)
            } else {
                alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
            }
            alert.popoverPresentationController?.sourceView = sender.superview
            alert.popoverPresentationController?.sourceRect = sender.frame
            
            alert.addAction(UIAlertAction(title: "Edit", style: UIAlertActionStyle.Default, handler: { (alertAction: UIAlertAction!) -> Void in
                let comment = ANParseKit.newThreadViewController()
                comment.initWith(thread, threadType: self.threadType, delegate: self, editingPost: thread)
                self.animator = self.presentViewControllerModal(comment)
            }))
            
            if User.currentUser()!.isAdmin() {
                let locked = thread.locked
                alert.addAction(UIAlertAction(title: locked ? "Unlock" : "Lock", style: UIAlertActionStyle.Default, handler: { (alertAction: UIAlertAction!) -> Void in
                    thread.locked = !locked
                    thread.saveInBackgroundWithBlock({ (success, error) -> Void in
                        if success {
                            self.presentBasicAlertWithTitle(thread.locked ? "Locked!" : "Unlocked!")
                        } else {
                            self.presentBasicAlertWithTitle("Failed saving")
                        }
                    })
                }))
                
                let pinned = thread.pinType != nil
                
                // TODO: Refactor all this
                if pinned {
                    alert.addAction(UIAlertAction(title: "Unpin", style: UIAlertActionStyle.Default, handler: { (alertAction: UIAlertAction!) -> Void in
                        thread.pinType = nil
                        thread.saveInBackgroundWithBlock({ (success, error) -> Void in
                            var alertTitle = ""
                            if success {
                                alertTitle = "Unpinned!"
                            } else {
                                alertTitle = "Failed unpinning"
                            }
                            self.presentBasicAlertWithTitle(alertTitle)
                        })
                    }))
                } else {
                    alert.addAction(UIAlertAction(title: "Pin Global", style: UIAlertActionStyle.Default, handler: { (alertAction: UIAlertAction!) -> Void in
                        thread.pinType = "global"
                        thread.saveInBackgroundWithBlock({ (success, error) -> Void in
                            var alertTitle = ""
                            if success {
                                alertTitle = "Pinned Globally!"
                            } else {
                                alertTitle = "Failed pinning"
                            }
                            
                            self.presentBasicAlertWithTitle(alertTitle)
                        })
                    }))
                    alert.addAction(UIAlertAction(title: "Pin Tag", style: UIAlertActionStyle.Default, handler: { (alertAction: UIAlertAction!) -> Void in
                        thread.pinType = "tag"
                        thread.saveInBackgroundWithBlock({ (success, error) -> Void in
                            var alertTitle = ""
                            if success {
                                alertTitle = "Pinned on Tag!"
                            } else {
                                alertTitle = "Failed pinning"
                            }
                            
                            self.presentBasicAlertWithTitle(alertTitle)
                        })
                    }))
                }
                
            }
            
            alert.addAction(UIAlertAction(title: "Delete", style: UIAlertActionStyle.Destructive, handler: { (alertAction: UIAlertAction!) -> Void in
                
                let childPostsQuery = Post.query()!
                childPostsQuery.whereKey("thread", equalTo: thread)
                childPostsQuery.includeKey("postedBy")
                childPostsQuery.findObjectsInBackgroundWithBlock({ (result, error) -> Void in
                    if let result = result {
                        
                        PFObject.deleteAllInBackground(result+[thread], block: { (success, error) -> Void in
                            if let _ = error {
                                // Show some error
                            } else {
                                thread.startedBy?.incrementPostCount(-1)
                                if !thread.isForumGame {
                                    for post in result {
                                        (post["postedBy"] as? User)?.incrementPostCount(-1)
                                    }
                                }
                                
                                self.navigationController?.popViewControllerAnimated(true)
                            }
                        })
                        
                    } else {
                        // TODO: Show error
                    }
                })
            }))
        
            
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler:nil))
            
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
}
