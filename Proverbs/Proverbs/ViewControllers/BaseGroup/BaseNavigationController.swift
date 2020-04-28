//
//  BaseNavigationController.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 4/20/18.
//  Copyright © 2018 Yevhenii Zozulia. All rights reserved.
//

import UIKit

class BaseNavigationController: UINavigationController, UINavigationControllerDelegate, ViewControllerConstructor {
    
    static var storyboardType: StoryboardType { return self._storyboardType }
    class var _storyboardType: StoryboardType { return .Main }
    
    // MARK: - UINavigationControllerDelegate

    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        self.delegate = self
    }
    
    override init(navigationBarClass: AnyClass?, toolbarClass: AnyClass?) {
        super.init(navigationBarClass: navigationBarClass, toolbarClass: toolbarClass)
        self.delegate = self
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.delegate = self
    }
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animation = BaseTransitionAnimation()
        animation.reverse = operation == .pop
        return animation
    }
}

