//
//  FacebookMessengerMediaShareHelper.swift
//  Proverbs
//
//  Created by Eugene Zozulya on 4/11/18.
//  Copyright © 2018 Eugene Zozulya. All rights reserved.
//

import UIKit

class Clipboard: ContentShareHelper {

    override class func canShare() -> Bool {
        return true
    }
    
    // MARK: - Private Methods
    
    override func share(withLink link: String) {
        let pasteboard = UIPasteboard.general
        pasteboard.string = link
    }
    
}
