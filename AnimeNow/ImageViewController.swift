//
//  ImageViewController.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 8/6/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import FLAnimatedImage

protocol ImageViewControllerDelegate: class {
    func imageViewControllerSelected(imageData imageData: ImageData)
}

public class ImageViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: FLAnimatedImageView!
    
    weak var delegate: ImageViewControllerDelegate?
    var imageData: ImageData!
    var animatedImage: FLAnimatedImage?
    
    func initWith(imageData imageData: ImageData) {
        self.imageData = imageData
    }
    
    func initWith(imageData imageData: ImageData, animatedImage: FLAnimatedImage) {
        initWith(imageData: imageData)
        self.animatedImage = animatedImage
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        if let animatedImage = animatedImage {
            imageView.animatedImage = animatedImage
        } else {
            imageView.setImageFrom(urlString: imageData.url, animated: true)
        }
        
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: UIStatusBarAnimation.Fade)
    }
    
    override public func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.Fade)
    }
    
    // MARK: - IBActions
    
    @IBAction func backPressed(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func selectPressed(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: { () -> Void in
            self.delegate?.imageViewControllerSelected(imageData: self.imageData)
        })
    }
}

extension ImageViewController: UIScrollViewDelegate {
    public func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    public func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView?, atScale scale: CGFloat) {
        
    }
}