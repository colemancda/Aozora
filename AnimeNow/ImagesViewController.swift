//
//  ImagesViewController.swift
//  Aozora
//
//  Created by Paul Chavarria Podoliako on 8/5/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import ANCommonKit
import Bolts
import SDWebImage
import FLAnimatedImage

protocol ImagesViewControllerDelegate: class {
    func imagesViewControllerSelected(imageData imageData: ImageData)
}

public class ImagesViewController: UIViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    weak var delegate: ImagesViewControllerDelegate?
    var dataSource: [ImageData] = []
    var imageScrapper: ImageScrapper!
    var loadingView: LoaderView!

    var imageDatasource: [String: FLAnimatedImage] = [:]
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        loadingView = LoaderView(parentView: view)
        imageScrapper = ImageScrapper(viewController: self)
        
        let searchBarTextField = searchBar.valueForKey("searchField") as? UITextField
        searchBarTextField?.textColor = UIColor.blackColor()
        
        searchBar.becomeFirstResponder()
        
        guard let collectionView = collectionView,
            let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
                return
        }
        let height: CGFloat = UIDevice.isPad() ? 260 : 120
        let size = CGSize(width: view.bounds.size.width/2-3, height: height)
        layout.itemSize = size
    }
    
    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
    }
    
    deinit {
        imageDatasource = [:]
    }
    
    func findImagesWithQuery(query: String, animated: Bool) {
        dataSource = []
        imageDatasource = [:]
        collectionView.reloadData()
        loadingView.startAnimating()
        
        imageScrapper.findImagesWithQuery(query, animated: animated).continueWithExecutor(BFExecutor.mainThreadExecutor(), withSuccessBlock: { (task: BFTask!) -> AnyObject! in
            
            let result = task.result as! [ImageData]
            self.dataSource = result
            self.collectionView.reloadData()
            self.loadingView.stopAnimating()
            return nil
        })
    }
    
    // MARK: - IBAction
    
    @IBAction func segmentedControlValueChanged(sender: AnyObject) {
        dataSource = []
        collectionView.reloadData()
        view.endEditing(true)
        let animated = segmentedControl.selectedSegmentIndex == 0 ? false : true
        findImagesWithQuery(searchBar.text!, animated: animated)
    }
    
}

extension ImagesViewController: UICollectionViewDataSource {
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("imageCell", forIndexPath: indexPath) as! BasicCollectionCell
        let imageData = dataSource[indexPath.row]
        cell.loadingURL = imageData.url
        cell.animatedImageView.animatedImage = nil
        cell.animatedImageView.image = nil
        if segmentedControl.selectedSegmentIndex == 1 {
            if let image = imageDatasource[imageData.url] {
                cell.animatedImageView.animatedImage = image
            } else {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                    // do some task
                    let image = FLAnimatedImage(GIFData: NSData(contentsOfURL: NSURL(string: imageData.url)!))
                    dispatch_async(dispatch_get_main_queue(), {
                        // update some UI
                        self.imageDatasource[imageData.url] = image
                        if cell.loadingURL == imageData.url {
                            cell.animatedImageView.animatedImage = image
                        }
                    });
                });
            }
        } else {
            cell.animatedImageView.setImageFrom(urlString: imageData.url, animated: false, options: SDWebImageOptions.CacheMemoryOnly)
        }
        
        return cell
    }
}

extension ImagesViewController: UICollectionViewDelegate {
    
    public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let imageData = dataSource[indexPath.row]
        
        let imageController = ANParseKit.commentStoryboard().instantiateViewControllerWithIdentifier("Image") as! ImageViewController
        
        if let image = imageDatasource[imageData.url] {
            imageController.initWith(imageData: imageData, animatedImage: image)
        } else {
            imageController.initWith(imageData: imageData)
        }
        
        imageController.delegate = self
        imageController.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        presentViewController(imageController, animated: true, completion: nil)
    }
}

extension ImagesViewController: UISearchBarDelegate {
    
    public func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        let animated = segmentedControl.selectedSegmentIndex == 0 ? false : true
        findImagesWithQuery(searchBar.text!, animated: animated)
        view.endEditing(true)
        searchBar.enableCancelButton()
    }
    
    public func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}

extension ImagesViewController: ImageViewControllerDelegate {
    
    func imageViewControllerSelected(imageData imageData: ImageData) {
        delegate?.imagesViewControllerSelected(imageData: imageData)
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}

extension ImagesViewController: ModalTransitionScrollable {
    public var transitionScrollView: UIScrollView? {
        return collectionView
    }
}