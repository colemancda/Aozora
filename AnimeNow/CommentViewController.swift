//
//  CommentViewController.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 8/5/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import Parse
import Bolts
import ANCommonKit
import SDWebImage

public protocol CommentViewControllerDelegate: class {
    func commentViewControllerDidFinishedPosting(newPost: PFObject, parentPost: PFObject?, edited: Bool)
}

public enum ThreadType {
    case Timeline
    case Episode
    case Custom
}

public class CommentViewController: UIViewController {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textViewBottomSpaceConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var inReply: UILabel!
    @IBOutlet weak var photoButton: UIButton!
    @IBOutlet weak var videoButton: UIButton!
    @IBOutlet weak var linkButton: UIButton?
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var photoCountLabel: UILabel!
    @IBOutlet weak var videoCountLabel: UILabel!
    @IBOutlet weak var linkCountLabel: UILabel?
    @IBOutlet weak var spoilersSwitch: UISwitch!
    
    public weak var delegate: CommentViewControllerDelegate?
    
    var animator: ZFModalTransitionAnimator!
    var dataPersisted = false
    
    var selectedImageData: ImageData? {
        didSet {
            updateMediaCountLabels()
        }
    }
    
    var selectedVideoID: String? {
        didSet {
            updateMediaCountLabels()
        }
    }
    
    var selectedLinkData: LinkData?
    var selectedLinkUrl: NSURL? {
        didSet {
            updateMediaCountLabels()
        }
    }
    
    var initialStatusBarStyle: UIStatusBarStyle!
    var postedBy = User.currentUser()
    var postedIn: User!
    var parentPost: Postable?
    var thread: Thread?
    var threadType: ThreadType = .Timeline
    var editingPost: PFObject?
    var anime: Anime?
    
    var fetchingData = false
    
    public func initWithTimelinePost(delegate: CommentViewControllerDelegate?, postedIn: User, editingPost: PFObject? = nil, parentPost: Postable? = nil) {
        self.postedIn = postedIn
        self.threadType = .Timeline
        self.editingPost = editingPost
        self.delegate = delegate
        self.parentPost = parentPost
    }
    
    public func initWith(thread: Thread? = nil, threadType: ThreadType, delegate: CommentViewControllerDelegate?, editingPost: PFObject? = nil, parentPost: Postable? = nil, anime: Anime? = nil) {
        self.postedBy = User.currentUser()!
        self.thread = thread
        self.threadType = threadType
        self.editingPost = editingPost
        self.delegate = delegate
        self.parentPost = parentPost
        self.anime = anime
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        
        photoCountLabel.hidden = true
        videoCountLabel.hidden = true
        linkCountLabel?.hidden = true
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if isBeingPresented() {
            initialStatusBarStyle = UIApplication.sharedApplication().statusBarStyle
        }
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.Default, animated: true)
    }
    
    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        if isBeingDismissed() {
            UIApplication.sharedApplication().setStatusBarStyle(initialStatusBarStyle, animated: true)
            view.endEditing(true)
        }
    }
    
    
    // MARK: - NSNotificationCenter
    
    func keyboardWillShow(notification: NSNotification) {
        let userInfo = notification.userInfo! as NSDictionary
        
        let endFrameValue = userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue
        let keyboardEndFrame = view.convertRect(endFrameValue.CGRectValue(), fromView: nil)
        
        updateInputForHeight(keyboardEndFrame.size.height)
    }
    
    func keyboardWillHide(notification: NSNotification) {
        updateInputForHeight(0)
    }
    
    // MARK: - Functions
    
    func updateInputForHeight(height: CGFloat) {
        
        textViewBottomSpaceConstraint.constant = height
        
        view.setNeedsUpdateConstraints()
        
        UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseOut, animations: {
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    // MARK: - Override
    func performPost() {
    }
    
    func performUpdate(post: PFObject) {
    }
    
    func completeRequest(post: PFObject, parentPost: PFObject?, error: NSError?) {
        if let _ = error {
            // TODO: Show error
            self.sendButton.setTitle("Send", forState: .Normal)
            self.sendButton.backgroundColor = UIColor.peterRiver()
            self.sendButton.userInteractionEnabled = true
        } else {
            // Success!
            dataPersisted = true
            self.delegate?.commentViewControllerDidFinishedPosting(post, parentPost:parentPost, edited: (editingPost != nil))
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func updateMediaCountLabels() {
        if let _ = selectedVideoID {
            videoCountLabel.hidden = false
        } else {
            videoCountLabel.hidden = true
        }
        
        if let _ = selectedImageData {
            photoCountLabel.hidden = false
        } else {
            photoCountLabel.hidden = true
        }
        
        if let _ = selectedLinkUrl {
            linkCountLabel?.hidden = false
        } else {
            linkCountLabel?.hidden = true
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func dimissViewControllerPressed(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func addImagePressed(sender: AnyObject) {
        
        if let _ = selectedImageData {
            selectedImageData = nil
        } else {
            let imagesController = ANParseKit.commentStoryboard().instantiateViewControllerWithIdentifier("Images") as! ImagesViewController
            imagesController.delegate = self
            animator = presentViewControllerModal(imagesController)
        }
        
    }
    
    @IBAction func addVideoPressed(sender: AnyObject) {
        
        if let _ = selectedVideoID {
            selectedVideoID = nil
        } else {
            let navController = ANParseKit.commentStoryboard().instantiateViewControllerWithIdentifier("BrowserSelector") as! UINavigationController
            let videoController = navController.viewControllers.last as! InAppBrowserSelectorViewController
            let initialURL = NSURL(string: "https://www.youtube.com")
            videoController.initWithInitialUrl(initialURL, overrideTitle: "Select a video")
            videoController.delegate = self
            presentViewController(navController, animated: true, completion: nil)
        }
        
    }

    @IBAction func addLinkPressed(sender: AnyObject) {
        if let _ = selectedLinkUrl {
            selectedLinkUrl = nil
        } else {
            presentBasicAlertWithTitle("Paste any link in text area", message: nil)
        }
    }
    
    @IBAction func sendPressed(sender: AnyObject) {
        if let editingPost = editingPost {
            performUpdate(editingPost)
        } else {
            performPost()
        }
    }
}

extension CommentViewController: ImagesViewControllerDelegate {
    func imagesViewControllerSelected(imageData imageData: ImageData) {
        selectedImageData = imageData
        selectedVideoID = nil
        selectedLinkUrl = nil
    }
}

extension CommentViewController: InAppBrowserSelectorViewControllerDelegate {
    public func inAppBrowserSelectorViewControllerSelectedSite(siteURL: String) {
        if let url = NSURL(string: siteURL), let parameters = BFURL(URL: url).inputQueryParameters, let videoID = parameters["v"] as? String {
            selectedVideoID = videoID
            selectedImageData = nil
            selectedLinkUrl = nil
        }
    }
}

extension CommentViewController: UITextViewDelegate {
    public func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        
        // Grab pasted urls
        if selectedLinkUrl == nil && text.characters.count > 1 {
            let types: NSTextCheckingType = .Link
            
            let detector = try? NSDataDetector(types: types.rawValue)
            
            guard let detect = detector else {
                return true
            }
            
            let matches = detect.matchesInString(text, options: .ReportCompletion, range: NSMakeRange(0, text.characters.count))
            
            for match in matches {
                if let url = match.URL {
                    
                    // Pin youtube videos separately
                    if let host = url.host where host.containsString("youtube.com") || host.containsString("youtu.be") {
                        if host.containsString("youtube.com") {
                            inAppBrowserSelectorViewControllerSelectedSite(url.absoluteString)
                        }
                        
                        if host.containsString("youtu.be") {
                            let videoID = url.pathComponents![1]
                            inAppBrowserSelectorViewControllerSelectedSite("http://www.youtube.com/watch?v=\(videoID)")
                        }
                        return false
                    }
                    
                    // Append image if it's an image
                    if let lastPathComponent = url.lastPathComponent where
                        lastPathComponent.endsWithInsensitiveCase(".png") ||
                        lastPathComponent.endsWithInsensitiveCase(".jpeg") ||
                        lastPathComponent.endsWithInsensitiveCase(".gif") ||
                        lastPathComponent.endsWithInsensitiveCase(".jpg") {
                            scrapeImageWithURL(url)
                            return false
                    }
                    
                    if let host = url.host, let imageId = url.lastPathComponent,
                        let imageURL = NSURL(string: "http://i.imgur.com/\(imageId).jpg")
                        where host.containsString("imgur.com") {
                        scrapeImageWithURL(imageURL)
                        return false
                    }
                    
                    selectedLinkUrl = url
                    scrapeLinkWithURL(url)
                    // If only added 1 link and it's the same as the added text, don't add it
                    if matches.count == 1 && match.range.length == text.characters.count {
                        return false
                    }
                }
                break
            }
        }
        return true
    }
    
    func scrapeLinkWithURL(url: NSURL) {
        linkCountLabel?.text = ""
        fetchingData = true
        
        let scapper = LinkScrapper(viewController: self)
        scapper.findInformationForLink(url).continueWithExecutor(BFExecutor.mainThreadExecutor(), withBlock: { (task: BFTask!) -> AnyObject? in
            
            self.fetchingData = false
            if let linkData = task.result as? LinkData {
                self.selectedLinkData = linkData
                self.linkCountLabel?.text = "1"
            } else {
                self.selectedLinkUrl = nil
            }
            
            return nil
        })
    }
    
    func scrapeImageWithURL(url: NSURL) {
        photoCountLabel.text = ""
        fetchingData = true
        
        let manager = SDWebImageManager.sharedManager()
        manager.downloadImageWithURL(url, options: [], progress: nil) { (image, error, cacheType, finished, imageUrl) -> Void in
            
            self.fetchingData = false
            
            if let error = error {
                print(error)
                self.photoCountLabel?.text = nil
            } else {
                self.photoCountLabel?.text = "1"
                let imageData = ImageData(url: url.absoluteString, width: Int(image.size.width), height: Int(image.size.height))
                self.imagesViewControllerSelected(imageData: imageData)
            }
        }
    }
}