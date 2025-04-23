//
//  UIViewController+Extensions.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 5/5/18.
//  Copyright © 2018 Yevhenii Zozulia. All rights reserved.
//

import UIKit

extension UIViewController {
    
    class var window:UIWindow {
        get {
            return UIApplication.shared.delegate!.window!!
        }
    }
    
    class var rootViewController: UIViewController? {
        get {
            return self.window.rootViewController
        }
        set {
            self.window.rootViewController = newValue
        }
    }
    
    class func getVisible(from rootViewController: UIViewController? = nil) -> UIViewController? {
        var rootViewController = rootViewController
        if rootViewController == nil { rootViewController = self.rootViewController }
        
        if let nav = rootViewController as? UINavigationController {
            return getVisible(from: nav.visibleViewController)
        }
        
        if let tab = rootViewController as? UITabBarController {
            let moreNavigationController = tab.moreNavigationController
            
            if let top = moreNavigationController.topViewController, top.view.window != nil {
                return getVisible(from: top)
            } else if let selected = tab.selectedViewController {
                return getVisible(from: selected)
            }
        }
        
        if let presented = rootViewController?.presentedViewController {
            return getVisible(from: presented)
        }
        
        return rootViewController
    }
    
}
