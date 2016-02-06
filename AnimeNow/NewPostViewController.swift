//
//  NewPostViewController.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 8/24/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import Parse
import Bolts

public class NewPostViewController: CommentViewController {
    
    let EditingContentCacheKey = "NewPost.TextContent"
    
    @IBOutlet weak var spoilersButton: UIButton!
    @IBOutlet weak var spoilerContentHeight: NSLayoutConstraint!
    @IBOutlet weak var spoilerTextView: UITextView!
    
    var hasSpoilers = false {
        didSet {
            if hasSpoilers {
                spoilersButton.setTitle(" Spoilers", forState: .Normal)
                spoilersButton.setTitleColor(UIColor.dropped(), forState: .Normal)
                spoilerContentHeight.constant = 160
                
            } else {
                spoilersButton.setTitle("No Spoilers", forState: .Normal)
                spoilersButton.setTitleColor(UIColor(white: 0.75, alpha: 1.0), forState: .Normal)
                spoilerContentHeight.constant = 0
            }
            
            
            UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 0.85, initialSpringVelocity: 1.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                self.view.layoutIfNeeded()
                }) { (finished) -> Void in
            }
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if let content = NSUserDefaults.standardUserDefaults().objectForKey(EditingContentCacheKey) as? String {
            NSUserDefaults.standardUserDefaults().removeObjectForKey(EditingContentCacheKey)
            textView.text = content
        }
        
        spoilerContentHeight.constant = 0
        textView.becomeFirstResponder()
        
        if let editingPost = editingPost {
            
            var postable = editingPost as! Commentable
            hasSpoilers = postable.hasSpoilers
            
            if hasSpoilers {
                spoilerTextView.text = postable.spoilerContent
                textView.text = postable.content
            } else {
                textView.text = postable.content
            }
            
            if let youtubeID = postable.youtubeID {
                selectedVideoID = youtubeID
                videoCountLabel.hidden = false
            } else if let imageData = postable.imagesData?.last {
                selectedImageData = imageData
                photoCountLabel.hidden = false
            } else if let linkData = postable.linkData {
                selectedLinkData = linkData
                linkCountLabel?.hidden = false
            }
            
            if let parentPost = parentPost as? TimelinePostable {
                inReply.text = "  Editing Reply to \(parentPost.userTimeline.aozoraUsername)"
            } else {
                inReply.text = "  Editing Post"
            }

        } else {
            if let parentPost = parentPost as? TimelinePostable {
                inReply.text = "  In Reply to \(parentPost.userTimeline.aozoraUsername)"
            } else {
                inReply.text = "  New Post"
            }
        }
    }
    
    public override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if !dataPersisted && editingPost == nil {
            NSUserDefaults.standardUserDefaults().setObject(textView.text, forKey: EditingContentCacheKey)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }

    override func performPost() {
        super.performPost()
        
        if !validPost() {
            return
        }
        
        if fetchingData {
            presentBasicAlertWithTitle("Fetching link data...", message: nil)
            return
        }
        
        self.sendButton.setTitle("Sending...", forState: .Normal)
        self.sendButton.backgroundColor = UIColor.watching()
        self.sendButton.userInteractionEnabled = false
        
        switch threadType {
        case .Timeline:
            var timelinePost = TimelinePost()
            timelinePost = updatePostable(timelinePost, edited: false) as! TimelinePost

            var parentSaveTask = BFTask(result: nil)
            
            if let parentPost = parentPost as? TimelinePost {
                parentPost.addUniqueObject(postedBy!, forKey: "subscribers")
                parentSaveTask = parentPost.saveInBackground()
            } else {
                if postedBy! != postedIn {
                    timelinePost.subscribers = [postedBy!, postedIn]
                } else {
                    timelinePost.subscribers = [postedBy!]
                }
            }
            
            if let parentPost = parentPost as? TimelinePostable {
                timelinePost.replyLevel = 1
                timelinePost.userTimeline = parentPost.userTimeline
                timelinePost.parentPost = parentPost as? TimelinePost
            } else {
                timelinePost.replyLevel = 0
                timelinePost.userTimeline = postedIn
            }
            
            let postSaveTask = timelinePost.saveInBackground()
            
            BFTask(forCompletionOfAllTasks: [parentSaveTask, postSaveTask])
                .continueWithExecutor(BFExecutor.mainThreadExecutor(), withBlock: { (task: BFTask!) -> AnyObject! in
                // Send timeline post notification
                if let parentPost = self.parentPost as? TimelinePost {
                    let parameters = [
                        "toUserId": self.postedIn.objectId!,
                        "timelinePostId": parentPost.objectId!,
                        "toUserUsername": self.postedIn.aozoraUsername
                        ] as [String : AnyObject]
                    PFCloud.callFunctionInBackground("sendNewTimelinePostReplyPushNotification", withParameters: parameters)
                } else {
                    let parameters = [
                        "toUserId": self.postedIn.objectId!,
                        "timelinePostId": timelinePost.objectId!
                        ] as [String : AnyObject]
                    PFCloud.callFunctionInBackground("sendNewTimelinePostPushNotification", withParameters: parameters)
                }
                
                self.postedBy?.incrementPostCount(1)
                self.completeRequest(timelinePost, parentPost: self.parentPost as? PFObject, error: task.error)
                return nil
            })
            
        default:
            var post = Post()
            post = updatePostable(post, edited: false) as! Post
            
            // Add subscribers to parent post or current post if there is no parent
            var parentSaveTask = BFTask(result: nil)
            
            if let parentPost = parentPost as? Post {
                parentPost.addUniqueObject(postedBy!, forKey: "subscribers")
                parentSaveTask = parentPost.saveInBackground()
            } else {
                post.subscribers = [postedBy!]
            }
            
            if let parentPost = parentPost as? ThreadPostable {
                post.replyLevel = 1
                post.thread = parentPost.thread
                post.parentPost = parentPost as? Post
            } else {
                post.replyLevel = 0
                post.thread = thread!
            }
            post.thread.incrementReplyCount()
            post.thread.lastPostedBy = postedBy
               
            let postSaveTask = post.saveInBackground()
            
            BFTask(forCompletionOfAllTasks: [parentSaveTask, postSaveTask])
                .continueWithExecutor(BFExecutor.mainThreadExecutor(), withBlock: { (task: BFTask!) -> AnyObject! in
                
                // Send post notification
                if let parentPost = self.parentPost as? Post {
                    let parameters = [
                        "toUserId": parentPost.postedBy!.objectId!,
                        "postId": parentPost.objectId!,
                        "threadName": post.thread.title
                        ] as [String : AnyObject]
                    PFCloud.callFunctionInBackground("sendNewPostReplyPushNotification", withParameters: parameters)
                } else {
                    var parameters = [
                        "postId": post.objectId!,
                        "threadName": post.thread.title
                        ] as [String : AnyObject]
                    
                    // Only on user threads, episode threads do not have startedBy
                    if let startedBy = post.thread.startedBy {
                        parameters["toUserId"] = startedBy.objectId!
                    }
                    
                    PFCloud.callFunctionInBackground("sendNewPostPushNotification", withParameters: parameters)
                }
                // Incrementing post counts only if thread does not contain #ForumGame tag
                if let thread = self.thread where !thread.isForumGame {
                    self.postedBy?.incrementPostCount(1)
                }
                self.completeRequest(post, parentPost: self.parentPost as? PFObject, error: task.error)
                return nil
            })
        }
    }
    
    func updatePostable(var post: Commentable, let edited: Bool) -> Commentable {
        if hasSpoilers {
            post.content = textView.text
            post.spoilerContent = spoilerTextView.text
        } else {
            post.content = textView.text
            post.spoilerContent = nil
        }
        
        if !edited {
            post.postedBy = postedBy
            post.edited = false
        } else {
            post.edited = true
        }
        
        post.hasSpoilers = hasSpoilers
        
        if let selectedImageData = selectedImageData {
            post.imagesData = [selectedImageData]
        } else {
            post.imagesData = []
        }
        
        if let youtubeID = selectedVideoID {
            post.youtubeID = youtubeID
        } else {
            post.youtubeID = nil
        }
        
        if let linkData = selectedLinkData {
            post.linkData = linkData
        } else {
            post.linkData = nil
        }
        
        return post
    }
    
    override func performUpdate(post: PFObject) {
        super.performUpdate(post)
        
        if !validPost() {
            return
        }
        
        self.sendButton.setTitle("Updating...", forState: .Normal)
        self.sendButton.backgroundColor = UIColor.watching()
        self.sendButton.userInteractionEnabled = false
        
        if var post = post as? Commentable {
            post = updatePostable(post, edited: true)
        }
        
        post.saveInBackgroundWithBlock ({ (result, error) -> Void in
            self.completeRequest(post, parentPost: self.parentPost as? PFObject, error: error)
        })
    }
    
    override func completeRequest(post: PFObject, parentPost: PFObject?, error: NSError?) {
        super.completeRequest(post, parentPost: parentPost, error: error)
        NSUserDefaults.standardUserDefaults().removeObjectForKey(EditingContentCacheKey)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func validPost() -> Bool {
        let content = max(textView.text.characters.count, spoilerTextView.text.characters.count)
        // Validate post
        if content < 2 && selectedImageData == nil && selectedVideoID == nil && selectedLinkData == nil {
            presentBasicAlertWithTitle("Too Short", message: "Message/spoiler should be 3 characters or longer")
            return false
        }
        if User.muted(self) {
            return false
        }
        return true
    }
    
  
    // MARK: - IBActions
    
    @IBAction func spoilersButtonPressed(sender: AnyObject) {
        hasSpoilers = !hasSpoilers
    }
}

extension NewPostViewController: ModalTransitionScrollable {
    public var transitionScrollView: UIScrollView? {
        return textView
    }
}


