//
//  UserFriendsViewController.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/22/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit
import Alamofire
import Bolts
import Parse
import ANCommonKit
import ANParseKit

class UserListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var loadingView: LoaderView!
    
    var dataSource: [User] = []
    var user: User?
    var query: PFQuery!
    var titleToSet = ""
    var animator: ZFModalTransitionAnimator!
    
    func initWithQuery(query: PFQuery, title: String, user: User? = nil) {
        self.user = user
        self.query = query
        titleToSet = title
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = titleToSet
        
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
        
        loadingView = LoaderView(parentView: view)
        
        fetchUserFriends()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    func fetchUserFriends() {
        
        loadingView.startAnimating()
        query.limit = 1000
        query.findObjectsInBackground().continueWithSuccessBlock { (task: BFTask!) -> AnyObject? in
            let result = task.result as! [User]
            
            self.dataSource = result
            
            let userIDs = result.map( {$0.objectId!} )
            
            // Find all relations
            let relationQuery = User.currentUser()!.following().query()
            relationQuery.whereKey("objectId", containedIn: userIDs)
            return relationQuery.findAllObjectsInBackground()
            
        }.continueWithExecutor(BFExecutor.mainThreadExecutor(), withSuccessBlock:  { (task: BFTask!) -> AnyObject? in
            
            if let result = task.result as? [User] {
                for user in result {
                    user.followingThisUser = true
                }
            }
            
            self.loadingView.stopAnimating()
            self.tableView.reloadData()
            self.tableView.animateFadeIn()
            
            return nil
        })
    }
}

extension UserListViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return dataSource.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("UserCell") as! UserCell
        
        let profile = dataSource[indexPath.row]
        if let avatarFile = profile.avatarThumb {
            cell.avatar.setImageWithPFFile(avatarFile)
        }
        cell.username.text = profile.aozoraUsername
        cell.delegate = self
        
        let isCurrentUserList = user?.isTheCurrentUser() ?? false
        if profile.isTheCurrentUser() || !isCurrentUserList {
            cell.followButton.hidden = true
        } else {
            cell.followButton.hidden = false
            cell.configureFollowButtonWithState(profile.followingThisUser ?? false)
        }
        
        cell.layoutIfNeeded()
        
        return cell
    }
}

extension UserListViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let profile = dataSource[indexPath.row]
        let profileController = ANAnimeKit.profileViewController()
        profileController.initWithUser(profile)
        navigationController?.pushViewController(profileController, animated: true)
    }
}

extension UserListViewController: UserCellDelegate {
    func userCellPressedFollow(userCell: UserCell) {
        if let currentUser = User.currentUser(), let indexPath = tableView.indexPathForCell(userCell) {
            let user = dataSource[indexPath.row]
            let follow = !(user.followingThisUser ?? false)
            currentUser.followUser(user, follow: follow)
            tableView.reloadData()
        }
    }
}
