//
//  TwitterMediaShareHelper.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 4/11/18.
//  Copyright © 2018 Yevhenii Zozulia. All rights reserved.
//

import UIKit
import Social
import TwitterKit

class TwitterShareHelper: ContentShareHelper {
    
    override class func canShare() -> Bool {
        if #available(iOS 11.0, *) {
            return true
        } else {
            return SLComposeViewController.isAvailable(forServiceType: SLServiceTypeTwitter)
        }
    }
    
    // MARK: - Properties
    
    override var serviceType: ContentShareServiceType { return .twitter }
    
    // MARK: - Private Methods
    
    override func share(withLink link: String) {
        guard let delegate = self.delegate else { return }
        
        if #available(iOS 11.0, *) {
            let composer = TWTRComposer()
            composer.setURL(URL(string: link))
            composer.show(from: delegate, completion: { [weak self] (result) in
                guard let self = self else { return }
                if (result == .done) {
                    self.delegate?.contentShareHelperDidShare(self)
                } else {
                    self.delegate?.contentShareHelperDidCancelShare(self)
                }
            })
        } else {
            if let tweetShare = SLComposeViewController(forServiceType: SLServiceTypeTwitter), let url = URL(string: link) {
                
                tweetShare.add(url)
                tweetShare.completionHandler = { [weak self] (result) in
                    guard let self = self else { return }
                    if (result == .done) {
                        self.delegate?.contentShareHelperDidShare(self)
                    } else {
                        self.delegate?.contentShareHelperDidCancelShare(self)
                    }
                }
                
                self.delegate?.present(tweetShare, animated: true, completion: nil)
            } else {
                self.delegate?.contentShareHelperDidFailToShare(self, error: nil)
            }
        }
    }
    
}
