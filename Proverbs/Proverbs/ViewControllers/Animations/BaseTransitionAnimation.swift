//
//  BaseTransitionAnimation.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 4/23/18.
//  Copyright © 2018 Yevhenii Zozulia. All rights reserved.
//

import UIKit

class BaseTransitionAnimation: NSObject, UIViewControllerAnimatedTransitioning {
    
    private let animationDurration: TimeInterval = 0.3
    var reverse = false
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return self.animationDurration
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView
        
        guard let fromViewController = transitionContext.viewController(forKey: .from) as? BaseViewController,
            let toViewController = transitionContext.viewController(forKey: .to) as? BaseViewController else {
                return
        }
        
        fromViewController.view.backgroundColor         = .clear
        fromViewController.backgroundImageView?.alpha   = 0.0
        fromViewController.view.layer.masksToBounds = true
        
        toViewController.view.backgroundColor           = .clear
        toViewController.backgroundImageView?.alpha     = 0.0
        toViewController.view.layer.masksToBounds = true
        
        let backgroundImageView = UIImageView(image: UIImage(named: "MainBackground")!)
        backgroundImageView.frame = CGRect(x: 0.0, y: 0.0, width: ScreenSize.width, height: ScreenSize.height)
        container.addSubview(backgroundImageView)
        
        let visibleFrame = container.bounds

        var leftFrame = visibleFrame
        leftFrame.origin.x = -ScreenSize.width
        
        var rightFrame = visibleFrame
        rightFrame.origin.x = ScreenSize.width
        
        
        fromViewController.view.frame = visibleFrame
        if reverse {
            toViewController.view.frame = leftFrame
        } else {
            toViewController.view.frame = rightFrame
        }
        
        container.addSubview(fromViewController.view)
        container.addSubview(toViewController.view)
        
        UIView.animate(withDuration: self.animationDurration, animations: {
            toViewController.view.frame = visibleFrame
            fromViewController.view.frame = self.reverse ? rightFrame : leftFrame
        }, completion: { _ in
            fromViewController.backgroundImageView?.alpha   = 1.0
            toViewController.backgroundImageView?.alpha     = 1.0
            backgroundImageView.removeFromSuperview()
            
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
    
}
