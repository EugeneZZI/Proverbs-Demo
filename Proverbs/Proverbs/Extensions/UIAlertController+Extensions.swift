//
//  UIAlertController+Extensions.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 5/5/18.
//  Copyright © 2018 Yevhenii Zozulia. All rights reserved.
//

import UIKit

typealias UIAlertControllerActionBlock = (UIAlertAction) -> Void

extension UIAlertController {
    
    class func show(withTitle title: String? = App.realName, message alertMessage: String, completion: ClosureVoid? = nil) {
        let alert = UIAlertController(title: title,
                                      message: alertMessage,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { _ in completion?() }))
        if let vc = UIViewController.getVisible() {
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    class func show(forViewController vc: UIViewController,
                         title: String? = App.realName,
                         message: String?,
                         hideDelay: TimeInterval = 3,
                         confirmButtonTitle: String?,
                         cancelButtonTitle: String?,
                         confirmBlock: UIAlertControllerActionBlock?,
                         cancelBlock: UIAlertControllerActionBlock?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        if let confirm = confirmButtonTitle {
            let action = UIAlertAction(title: confirm, style: .default, handler: { (action) in
                confirmBlock?(action)
                alert.dismiss(animated: true, completion: nil)
            })
            alert.addAction(action)
            alert.preferredAction = action
        }
        
        if let cancel = cancelButtonTitle {
            let action = UIAlertAction(title: cancel, style: .cancel, handler: { (action) in
                cancelBlock?(action)
                alert.dismiss(animated: true, completion: nil)
            })
            alert.addAction(action)
        }
        
        vc.present(alert, animated: true, completion: {
            if confirmButtonTitle == nil && cancelButtonTitle == nil {
                after(hideDelay, closure: {
                    alert.dismiss(animated: true, completion: nil)
                })
            }
        })
    }
    
}
