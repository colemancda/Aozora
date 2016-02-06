//
//  RateViewController.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 7/24/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import HCSStarRatingView
import ANParseKit

public protocol RateViewControllerProtocol: class {
    func rateControllerDidFinishedWith(anime anime: Anime, rating: Float)
}

public class RateViewController: UIViewController {
    
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var starRating: HCSStarRatingView!
    @IBOutlet weak var rateView: UIView!
    
    weak var delegate: RateViewControllerProtocol?
    
    var currentRating: Float = 0
    var message: String = ""
    var anime: Anime!
    
    public class func showRateDialogWith(viewController: UIViewController, title: String, initialRating: Float, anime: Anime, delegate: RateViewControllerProtocol) {
        
        let controller = UIStoryboard(name: "Rate", bundle: nil).instantiateInitialViewController() as! RateViewController
        
        controller.initWith(anime, title: title, initialRating: initialRating, delegate: delegate)
        
        controller.modalTransitionStyle = .CrossDissolve
        controller.modalPresentationStyle = .OverCurrentContext
        viewController.presentViewController(controller, animated: true, completion: nil)
    }
    
    public class func updateAnime(anime: Anime, withRating rating: Float) {
        
        if let progress = anime.progress {
            
            progress.score = Int(rating)
            progress.saveInBackground()
            LibrarySyncController.updateAnime(progress)
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(LibraryUpdatedNotification, object: nil)
    }
    
    func initWith(anime: Anime, title: String, initialRating: Float, delegate: RateViewControllerProtocol) {
        
        message = title
        currentRating = initialRating
        self.anime = anime
        self.delegate = delegate
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        messageLabel.text = message
        starRating.value = CGFloat(currentRating)
    
        rateView.transform = CGAffineTransformMakeScale(0, 0)
        
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        UIView.animateWithDuration(0.8, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            self.rateView.transform = CGAffineTransformIdentity
            }) { (completed) -> Void in
                
        }
    }
    
    
    // MARK: - IBActions
    
    @IBAction func ratingChanged(sender: HCSStarRatingView) {
        UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: [UIViewAnimationOptions.BeginFromCurrentState, UIViewAnimationOptions.CurveEaseOut], animations: { () -> Void in
            let scale = 1+0.05*sender.value
            self.starRating.transform = CGAffineTransformMakeScale(scale, scale)
            }) { (completed) -> Void in
                
        }
    }
    
    @IBAction func ratingEnded(sender: HCSStarRatingView) {
        
        UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 0.3, initialSpringVelocity: 1.0, options: [UIViewAnimationOptions.BeginFromCurrentState, UIViewAnimationOptions.CurveEaseOut], animations: { () -> Void in
            self.starRating.transform = CGAffineTransformIdentity
            }) { (completed) -> Void in
                
        }
        delegate?.rateControllerDidFinishedWith(anime: anime, rating: Float(sender.value))
    }
    
    @IBAction func dismissViewController(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}