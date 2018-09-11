//
//  FacebookMediaShareHelper.swift
//  Proverbs
//
//  Created by Eugene Zozulya on 4/11/18.
//  Copyright © 2018 Eugene Zozulya. All rights reserved.
//

import UIKit
import Social
import FBSDKShareKit

class FacebookShareHelper: ContentShareHelper {
    
    override class func canShare() -> Bool {
        if #available(iOS 11.0, *) {
            return true
        } else {
            return SLComposeViewController.isAvailable(forServiceType: SLServiceTypeFacebook)
        }
    }
    
    // MARK: - Properties
    
    override var serviceType: ContentShareServiceType { return .facebook }
    
    // MARK: - Private Methods
    
    override func share(withLink link: String) {
        if #available(iOS 11.0, *) {
            let linkContent = FBSDKShareLinkContent()
            linkContent.contentURL = URL(string: link)
            FBSDKShareDialog.show(from: self.delegate, with: linkContent, delegate: self)
        } else {
            if let facebookShare = SLComposeViewController(forServiceType: SLServiceTypeFacebook), let url = URL(string: link) {
                
                facebookShare.add(url)
                facebookShare.completionHandler = { (result) in
                    if (result == .done) {
                        self.delegate.contentShareHelperDidShare(self)
                    } else {
                        self.delegate.contentShareHelperDidCancelShare(self)
                    }
                }
                self.delegate.present(facebookShare, animated: true, completion: nil)
            } else {
                self.delegate.contentShareHelperDidFailToShare(self, error: nil)
            }
        }
    }
    
}

extension FacebookShareHelper: FBSDKSharingDelegate {
    
    func sharer(_ sharer: FBSDKSharing!, didCompleteWithResults results: [AnyHashable : Any]!) {
        self.delegate.contentShareHelperDidShare(self)
    }
    
    func sharer(_ sharer: FBSDKSharing!, didFailWithError error: Error!) {
        self.delegate.contentShareHelperDidFailToShare(self, error: nil)
    }
    
    func sharerDidCancel(_ sharer: FBSDKSharing!) {
        self.delegate.contentShareHelperDidCancelShare(self)
    }
    
}
