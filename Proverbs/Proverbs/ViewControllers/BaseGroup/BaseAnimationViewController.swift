//
//  BaseAnimationViewController.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 9/6/18.
//  Copyright © 2018 Yevhenii Zozulia. All rights reserved.
//

import UIKit

class BaseAnimationViewController: BaseViewController {
    
    // MARK: - Properties
    
    var animateSubviews: [UIView] {
        return []
    }
    
    // MARK: Public Methods
    
    func hideSubviews(withAnimationDuration duration: TimeInterval, completion: @escaping ClosureVoid) {
        UIView.animate(withDuration: duration, animations: {
            self.animateSubviews.forEach { $0.alpha = 0.0 }
        }) { (_) in
            completion()
        }
    }
    
    func showSubviews(withAnimationDuration duration: TimeInterval, completion: @escaping ClosureVoid) {
        self.animateSubviews.forEach { $0.alpha = 0.0 }
        
        UIView.animate(withDuration: duration, animations: {
            self.animateSubviews.forEach { $0.alpha = 1.0 }
        }) { (_) in
            completion()
        }
    }
    
}

