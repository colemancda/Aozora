//
//  EpisodeCell.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/24/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit
import FBSDKMessengerShareKit
import ANParseKit

protocol EpisodeCellDelegate: class {
    func episodeCellWatchedPressed(cell: EpisodeCell)
    func episodeCellMorePressed(cell: EpisodeCell)
}

class EpisodeCell: UICollectionViewCell {

    enum WatchStatus {
        case Disabled
        case Watched
        case NotWatched
    }
    
    weak var delegate: EpisodeCellDelegate?
    
    @IBOutlet weak var screenshotImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var overviewLabel: UILabel!
    @IBOutlet weak var firstAiredLabel: UILabel!
    
    @IBOutlet weak var watchedButton: UIButton!
    @IBOutlet weak var messengerButton: UIButton!
    @IBOutlet weak var moreButton: UIButton!

    let numberAttributes = [NSFontAttributeName: UIFont.boldSystemFontOfSize(16), NSForegroundColorAttributeName: UIColor.whiteColor()]
    let titleAttributes = [NSFontAttributeName: UIFont.systemFontOfSize(16)]

    func configureCellWithEpisode(episode: Episode, watchStatus: WatchStatus) {
        let episodeNumber = NSAttributedString(string: "Ep \(episode.number) · ", attributes: numberAttributes)
        let episodeTitle = NSAttributedString(string: episode.title ?? "", attributes: titleAttributes)

        let attributedString = NSMutableAttributedString()
        attributedString.appendAttributedString(episodeNumber)
        attributedString.appendAttributedString(episodeTitle)


        titleLabel.attributedText = attributedString
        screenshotImageView.setImageFrom(urlString: episode.imageURLString(), animated: true)

        firstAiredLabel.text = episode.firstAired?.mediumDate() ?? ""

        switch watchStatus {
        case .Disabled:
            watchedButton.enabled = false
            watchedButton.backgroundColor = UIColor.clearColor()
            watchedButton.setImage(UIImage(named: "icon-check"), forState: .Normal)
        case .Watched:
            watchedButton.enabled = true
            watchedButton.backgroundColor = UIColor.textBlue()
            watchedButton.setImage(UIImage(named: "icon-check-selected"), forState: .Normal)
        case .NotWatched:
            watchedButton.enabled = true
            watchedButton.backgroundColor = UIColor.clearColor()
            watchedButton.setImage(UIImage(named: "icon-check"), forState: .Normal)
        }
    }
    
    @IBAction func morePressed(sender: AnyObject) {
        delegate?.episodeCellMorePressed(self)
    }
    
    @IBAction func watchedPressed(sender: AnyObject) {
        delegate?.episodeCellWatchedPressed(self)
    }
    
    @IBAction func shareOnMessengerPressed(sender: AnyObject) {
        if UIApplication.sharedApplication().canOpenURL(NSURL(string: "fb-messenger://")!) {
            FBSDKMessengerSharer.shareImage(screenshotImageView.image, withOptions: nil)
        }
    }
}
