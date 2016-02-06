//
//  AnimePresenter.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/27/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import Foundation
import ANParseKit
import ANCommonKit
import JTSImageViewController

extension UIViewController {
    
    public func presentAnimeModal(anime: Anime) -> ZFModalTransitionAnimator {
        
        let tabBarController = ANAnimeKit.rootTabBarController()
        tabBarController.initWithAnime(anime)
        
        let animator = ZFModalTransitionAnimator(modalViewController: tabBarController)
        animator.dragable = true
        animator.direction = .Bottom
        
        tabBarController.animator = animator
        tabBarController.transitioningDelegate = animator;
        tabBarController.modalPresentationStyle = UIModalPresentationStyle.Custom;
        
        presentViewController(tabBarController, animated: true, completion: nil)
        
        return animator
    }
    
    func presentSearchViewController(searchScope: SearchScope) {
        let (navigation, controller) = ANAnimeKit.searchViewController()
        controller.initWithSearchScope(searchScope)
        presentViewController(navigation, animated: true, completion: nil)
    }
    
}