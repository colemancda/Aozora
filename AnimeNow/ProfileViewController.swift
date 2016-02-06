//
//  UserProfileViewController.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/22/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit
import ANCommonKit
import TTTAttributedLabel
import XCDYouTubeKit
import Parse
import ANParseKit

public class ProfileViewController: ThreadViewController {
    
    enum SelectedFeed: Int {
        case Feed = 0
        case Popular
        case Me
    }
    
    @IBOutlet weak var settingsButton: UIButton!
    
    @IBOutlet weak var userAvatar: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var userBanner: UIImageView!
    @IBOutlet weak var animeListButton: UIButton!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var followingButton: UIButton!
    @IBOutlet weak var followersButton: UIButton!
    @IBOutlet weak var aboutLabel: TTTAttributedLabel!
    @IBOutlet weak var activeAgo: UILabel!
    
    @IBOutlet weak var proBadge: UILabel!
    @IBOutlet weak var postsBadge: UILabel!
    @IBOutlet weak var tagBadge: UILabel!
    
    @IBOutlet weak var segmentedControlView: UIView!
    
    @IBOutlet weak var proBottomLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var settingsTrailingSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableBottomSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var segmentedControlTopSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableHeaderViewBottomSpaceConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var segmentedControlHeight: NSLayoutConstraint!
    
    public var userProfile: User?
    var username: String?
    
    public func initWithUser(user: User) {
        self.userProfile = user
    }
    
    public func initWithUsername(username: String) {
        self.username = username
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        segmentedControlView.hidden = true
        
        if userProfile == nil && username == nil {
            userProfile = User.currentUser()!
            segmentedControl.selectedSegmentIndex = SelectedFeed.Feed.rawValue
        } else {
            segmentedControl.selectedSegmentIndex = SelectedFeed.Me.rawValue
            tableBottomSpaceConstraint.constant = 0
        }
        
        if tabBarController == nil {
            navigationItem.rightBarButtonItem = nil
        }
        
        aboutLabel.linkAttributes = [kCTForegroundColorAttributeName: UIColor.peterRiver()]
        aboutLabel.enabledTextCheckingTypes = NSTextCheckingType.Link.rawValue
        aboutLabel.delegate = self;
        
        fetchPosts()
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(false, animated: true)

        if let profile = userProfile where profile.details.dataAvailable {
            updateFollowingButtons()
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func sizeHeaderToFit() {
        guard let header = tableView.tableHeaderView else {
            return
        }
        
        if let userProfile = userProfile where !userProfile.isTheCurrentUser() {
            tableHeaderViewBottomSpaceConstraint.constant = 8
            segmentedControl.hidden = true
        }
        
        header.setNeedsLayout()
        header.layoutIfNeeded()
        
        aboutLabel.preferredMaxLayoutWidth = aboutLabel.frame.size.width
        
        let height = header.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
        var frame = header.frame
        
        frame.size.height = height
        header.frame = frame
        tableView.tableHeaderView = header
    }
    
    
    
    // MARK: - Fetching
    
    override public func fetchPosts() {
        super.fetchPosts()
        let username = self.username ?? userProfile!.aozoraUsername
        fetchUserDetails(username)
    }
    
    func fetchUserDetails(username: String) {
        
        if let _ = self.userProfile {
            configureFetchController()
        }
        
        let query = User.query()!
        query.whereKey("aozoraUsername", equalTo: username)
        query.includeKey("details")
        query.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            
            guard let user = result?.last as? User else {
                return
            }

            self.userProfile = user
            self.updateViewWithUser(user)
            self.aboutLabel.setText(user.details.about, afterInheritingLabelAttributesAndConfiguringWithBlock: { (attributedString) -> NSMutableAttributedString! in
                return attributedString
            })

            let activeEndString = user.activeEnd.timeAgo()
            let activeEndStringFormatted = activeEndString == "Just now" ? "active now" : "\(activeEndString) ago"
            self.activeAgo.text = user.active ? "active now" : activeEndStringFormatted

            if user.details.posts >= 1000 {
                self.postsBadge.text = String(format: "%.1fk", Float(user.details.posts-49)/1000.0 )
            } else {
                self.postsBadge.text = user.details.posts.description
            }

            self.updateFollowingButtons()
            self.sizeHeaderToFit()
            // Start fetching if didn't had User class
            if let _ = self.username {
                self.configureFetchController()
            }


            if !user.isTheCurrentUser() && !User.currentUserIsGuest() {
                let relationQuery = User.currentUser()!.following().query()
                relationQuery.whereKey("aozoraUsername", equalTo: username)
                relationQuery.findObjectsInBackgroundWithBlock { (result, error) -> Void in
                    if let _ = result?.last as? User {
                        // Following this user
                        self.followButton.setTitle("  Following", forState: .Normal)
                        user.followingThisUser = true
                    } else if let _ = error {
                        // TODO: Show error

                    } else {
                        // NOT following this user
                        self.followButton.setTitle("  Follow", forState: .Normal)
                        user.followingThisUser = false
                    }
                    self.followButton.layoutIfNeeded()
                }
            }
        }
    }
    
    func updateViewWithUser(user: User) {
        usernameLabel.text = user.aozoraUsername
        title = user.aozoraUsername
        if let avatarFile = user.avatarThumb {
            userAvatar.setImageWithPFFile(avatarFile)
        }
        
        if let bannerFile = user.banner {
            userBanner.setImageWithPFFile(bannerFile)
        }
        
        if let _ = tabBarController {
            navigationItem.leftBarButtonItem = nil
        }
        
        let proPlusString = "PRO+"
        let proString = "PRO"
        
        proBadge.hidden = true
        
        if user.isTheCurrentUser() {
            // If is current user, only show PRO when unlocked in-apps
            if let _ = InAppController.purchasedProPlus() {
                proBadge.hidden = false
                proBadge.text = proPlusString
            } else if let _ = InAppController.purchasedPro() {
                proBadge.hidden = false
                proBadge.text = proString
            }
        } else {
            if user.badges.indexOf(proPlusString) != nil {
                proBadge.hidden = false
                proBadge.text = proPlusString
            } else if user.badges.indexOf(proString) != nil {
                proBadge.hidden = false
                proBadge.text = proString
            }
        }
        
        
        if user.isAdmin() {
            tagBadge.backgroundColor = UIColor.aozoraPurple()
        }
        
        if User.currentUserIsGuest() {
            followButton.hidden = true
            settingsButton.hidden = true
        } else if user.isTheCurrentUser() {
            followButton.hidden = true
            settingsTrailingSpaceConstraint.constant = -10
        } else {
            followButton.hidden = false
        }
        
        var hasABadge = false
        for badge in user.badges where badge != proString && badge != proPlusString {
            tagBadge.text = badge
            hasABadge = true
            break
        }
        
        if hasABadge {
            tagBadge.hidden = false
        } else {
            tagBadge.hidden = true
            proBottomLayoutConstraint.constant = 4
        }
    }
    
    func updateFollowingButtons() {
        if let profile = userProfile {
            followingButton.setTitle("\(profile.details.followingCount) FOLLOWING", forState: .Normal)
            followersButton.setTitle("\(profile.details.followersCount) FOLLOWERS", forState: .Normal)
        }
    }
    
    func configureFetchController() {
        var offset = tableView.contentOffset
        if offset.y > 345 {
           offset.y = 345
        }
        fetchController.configureWith(self, queryDelegate: self, tableView: self.tableView, limit: self.FetchLimit, datasourceUsesSections: true)
        tableView.setContentOffset(offset, animated: false)
    }
    
    // MARK: - IBAction
    @IBAction func segmentedControlValueChanged(sender: AnyObject) {
        configureFetchController()
    }
    
    @IBAction func followOrUnfollow(sender: AnyObject) {
    
        if let thisProfileUser = userProfile,
            let followingUser = thisProfileUser.followingThisUser,
            let currentUser = User.currentUser() where !thisProfileUser.isTheCurrentUser() {
            
            currentUser.followUser(thisProfileUser, follow: !followingUser)
            
            if !followingUser {
                // Follow
                self.followButton.setTitle("  Following", forState: .Normal)
                updateFollowingButtons()
            } else {
                // Unfollow
                self.followButton.setTitle("  Follow", forState: .Normal)
                updateFollowingButtons()
            }
        }
    }
    
    @IBAction func searchPressed(sender: AnyObject) {
        if let tabBar = tabBarController {
            tabBar.presentSearchViewController(.AllAnime)
        }
    }
    
    public override func replyToThreadPressed(sender: AnyObject) {
        super.replyToThreadPressed(sender)
        
        if let profile = userProfile where User.currentUserLoggedIn() {
            let comment = ANParseKit.newPostViewController()
            comment.initWithTimelinePost(self, postedIn: profile)
            animator = presentViewControllerModal(comment)
        } else {
            presentBasicAlertWithTitle("Login first", message: "Select 'Me' tab")
        }
    }
    
    
    // MARK: - FetchControllerQueryDelegate
    
    public override func queriesForSkip(skip skip: Int) -> [PFQuery]? {
        
        let innerQuery = TimelinePost.query()!
        innerQuery.skip = skip
        innerQuery.limit = FetchLimit
        innerQuery.whereKey("replyLevel", equalTo: 0)
        innerQuery.orderByDescending("createdAt")
        
        let selectedFeed = SelectedFeed(rawValue: segmentedControl.selectedSegmentIndex)!
        switch selectedFeed {
        case .Feed:
            let followingQuery = userProfile!.following().query()
            followingQuery.orderByDescending("activeStart")
            followingQuery.limit = 1000
            innerQuery.whereKey("userTimeline", matchesKey: "objectId", inQuery: followingQuery)
        case .Popular:
            innerQuery.whereKeyExists("likedBy")
        case .Me:
            innerQuery.whereKey("userTimeline", equalTo: userProfile!)
        }
        
        // 'Feed' query
        let query = innerQuery.copy() as! PFQuery
        query.includeKey("episode")
        query.includeKey("postedBy")
        query.includeKey("userTimeline")
        
        let repliesQuery = TimelinePost.query()!
        repliesQuery.skip = 0
        repliesQuery.whereKey("parentPost", matchesKey: "objectId", inQuery: innerQuery)
        repliesQuery.orderByAscending("createdAt")
        repliesQuery.includeKey("episode")
        repliesQuery.includeKey("postedBy")
        repliesQuery.includeKey("userTimeline")
        
        return [query, repliesQuery]
    }
    
    
    // MARK: - CommentViewControllerDelegate
    
    public override func commentViewControllerDidFinishedPosting(newPost: PFObject, parentPost: PFObject?, edited: Bool) {
        super.commentViewControllerDidFinishedPosting(newPost, parentPost: parentPost, edited: edited)
        
        if edited {
            // Don't insert if edited
            tableView.reloadData()
            return
        }
        
        if let parentPost = parentPost {
            // Inserting a new reply in-place
            var parentPost = parentPost as! Commentable
            parentPost.replies.append(newPost)
            tableView.reloadData()
        } else if parentPost == nil {
            // Inserting a new post in the top, if we're in the top of the thread
            fetchController.dataSource.insert(newPost, atIndex: 0)
            tableView.reloadData()
        }
    }
    
    
    // MARK: - FetchControllerDelegate
    
    public override func didFetchFor(skip skip: Int) {
        super.didFetchFor(skip: skip)
        if let userProfile = userProfile where userProfile.isTheCurrentUser() && segmentedControlView.hidden {
            segmentedControlView.hidden = false
            scrollViewDidScroll(tableView)
            segmentedControlView.animateFadeIn()
        }
    }
    
    func addMuteUserAction(alert: UIAlertController) {
        alert.addAction(UIAlertAction(title: "Mute", style: UIAlertActionStyle.Destructive, handler: {
            (alertAction: UIAlertAction) -> Void in
            
            let alertController = UIAlertController(title: "Mute", message: "Enter duration in minutes to mute", preferredStyle: .Alert)
            
            alertController.addTextFieldWithConfigurationHandler(
                {(textField: UITextField!) in
                    textField.placeholder = "Enter duration in minutes"
                    textField.textColor = UIColor.blackColor()
                    textField.keyboardType = UIKeyboardType.NumberPad
                })
            
            let action = UIAlertAction(title: "Submit",
                style: UIAlertActionStyle.Default,
                handler: {[weak self]
                    (paramAction:UIAlertAction!) in
                    
                    if let textField = alertController.textFields {
                        
                        let durationTextField = textField as [UITextField]
                        
                        guard let controller = self, let userProfile = self?.userProfile, let durationText = durationTextField[0].text, let duration = Double(durationText) else {
                            self?.presentBasicAlertWithTitle("Woops", message: "Your mute duration is too long or you have entered characters.")
                            return
                        }
                        
                        let date = NSDate().dateByAddingTimeInterval(duration * 60.0)
                        userProfile.details.mutedUntil = date
                        userProfile.saveInBackground()
                        
                        controller.presentBasicAlertWithTitle("Muted user", message: "You have muted " + self!.userProfile!.username!)

                    }
                })
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) {
                action -> Void in
            }
            
            alertController.addAction(action)
            alertController.addAction(cancelAction)
            
            self.presentViewController(alertController, animated: true, completion: nil)
            alert.view.tintColor = UIColor.redColor()
            
        }))
        
    }
    
    func addUnmuteUserAction(alert: UIAlertController) {
        alert.addAction(UIAlertAction(title: "Unmute", style: UIAlertActionStyle.Destructive, handler: { (alertAction: UIAlertAction) -> Void in
            
            guard let userProfile = self.userProfile, let username = userProfile.username else {
                return
            }
            userProfile.details.mutedUntil = nil
            userProfile.saveInBackground()
            
            self.presentBasicAlertWithTitle("Unmuted user", message: "You have unmuted " + username)
            
            
        }))
    }
    
    // MARK: - IBActions
    
    func presentSmallViewController(viewController: UIViewController, sender: AnyObject) {
        viewController.modalPresentationStyle = .Popover
        viewController.preferredContentSize = CGSizeMake(320, 500)
        
        let popoverMenuViewController = viewController.popoverPresentationController
        popoverMenuViewController?.permittedArrowDirections = .Any
        popoverMenuViewController?.sourceView = sender.superview
        popoverMenuViewController?.sourceRect = sender.frame
        
        if UIDevice.isPad() {
            navigationController?.presentViewController(viewController, animated: true, completion: nil)
        } else {
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    @IBAction func showFollowingUsers(sender: AnyObject) {
        let userListController = UIStoryboard(name: "Profile", bundle: nil).instantiateViewControllerWithIdentifier("UserList") as! UserListViewController
        let query = userProfile!.following().query()
        query.orderByAscending("aozoraUsername")
        userListController.initWithQuery(query, title: "Following", user: userProfile!)
        presentSmallViewController(userListController, sender: sender)
    }
    
    @IBAction func showFollowers(sender: AnyObject) {
        let userListController = UIStoryboard(name: "Profile", bundle: nil).instantiateViewControllerWithIdentifier("UserList") as! UserListViewController
        let query = User.query()!
        query.whereKey("following", equalTo: userProfile!)
        query.orderByAscending("aozoraUsername")
        userListController.initWithQuery(query, title: "Followers", user: userProfile!)
        presentSmallViewController(userListController, sender: sender)
    }
    
    @IBAction func showSettings(sender: AnyObject) {
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        alert.popoverPresentationController?.sourceView = sender.superview
        alert.popoverPresentationController?.sourceRect = sender.frame
        
        alert.addAction(UIAlertAction(title: "View Library", style: UIAlertActionStyle.Default, handler: { (alertAction: UIAlertAction) -> Void in
            if let userProfile = self.userProfile {
                let navVC = UIStoryboard(name: "Library", bundle: nil).instantiateViewControllerWithIdentifier("PublicLibraryNav") as! UINavigationController
                let publicList = navVC.viewControllers.first as! PublicListViewController
                publicList.initWithUser(userProfile)
                self.animator = self.presentViewControllerModal(navVC)
            }
        }))
        
        guard let currentUser = User.currentUser() else {
            return
        }
    
        if currentUser.isAdmin() && !userProfile!.isAdmin() || currentUser.isTopAdmin() {
        
            guard let userProfile = userProfile else {
                return
            }
            
            if let _ = userProfile.details.mutedUntil {
                addUnmuteUserAction(alert)
            } else {
                addMuteUserAction(alert)
            }
        }
        
        if let userProfile = userProfile where userProfile.isTheCurrentUser() {
            alert.addAction(UIAlertAction(title: "Edit Profile", style: UIAlertActionStyle.Default, handler: { (alertAction: UIAlertAction) -> Void in
                let editProfileController =  UIStoryboard(name: "Profile", bundle: nil).instantiateViewControllerWithIdentifier("EditProfile") as! EditProfileViewController
                editProfileController.delegate = self
                if UIDevice.isPad() {
                    self.presentSmallViewController(editProfileController, sender: sender)
                } else {
                    self.presentViewController(editProfileController, animated: true, completion: nil)
                }
            }))
            
            alert.addAction(UIAlertAction(title: "Settings", style: UIAlertActionStyle.Default, handler: { (alertAction: UIAlertAction) -> Void in
                let settings = UIStoryboard(name: "Settings", bundle: nil).instantiateInitialViewController() as! UINavigationController
                if UIDevice.isPad() {
                    self.presentSmallViewController(settings, sender: sender)
                } else {
                    self.animator = self.presentViewControllerModal(settings)
                }
            }))
            
            alert.addAction(UIAlertAction(title: "Online Users", style: UIAlertActionStyle.Default, handler: { (alertAction: UIAlertAction) -> Void in
                let userListController = UIStoryboard(name: "Profile", bundle: nil).instantiateViewControllerWithIdentifier("UserList") as! UserListViewController
                let query = User.query()!
                query.whereKeyExists("aozoraUsername")
                query.whereKey("active", equalTo: true)
                query.limit = 100
                userListController.initWithQuery(query, title: "Online Users")
                
                self.presentSmallViewController(userListController, sender: sender)
            }))
            
            alert.addAction(UIAlertAction(title: "New Users", style: UIAlertActionStyle.Default, handler: { (alertAction: UIAlertAction) -> Void in
                let userListController = UIStoryboard(name: "Profile", bundle: nil).instantiateViewControllerWithIdentifier("UserList") as! UserListViewController
                let query = User.query()!
                query.orderByDescending("joinDate")
                query.whereKeyExists("aozoraUsername")
                query.limit = 100
                userListController.initWithQuery(query, title: "New Users")
                self.presentSmallViewController(userListController, sender: sender)
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler:nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: - Overrides
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        let topSpace = tableView.tableHeaderView!.bounds.size.height - 44 - scrollView.contentOffset.y
        if topSpace < 64 {
            segmentedControlTopSpaceConstraint.constant = 64
        } else {
            segmentedControlTopSpaceConstraint.constant = topSpace
        }
    }
}

// MARK: - EditProfileViewControllerProtocol
extension ProfileViewController: EditProfileViewControllerProtocol {
    
    func editProfileViewControllerDidEditedUser(user: User) {
        userProfile = user
        fetchUserDetails(user.aozoraUsername)
    }
}


