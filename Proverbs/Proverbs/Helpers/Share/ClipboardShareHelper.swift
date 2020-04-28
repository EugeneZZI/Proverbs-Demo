//
//  FacebookMessengerMediaShareHelper.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 4/11/18.
//  Copyright © 2018 Yevhenii Zozulia. All rights reserved.
//

import UIKit

class ClipboardShareHelper: ContentShareHelper {

    override class func canShare() -> Bool {
        return true
    }
    
    // MARK: - Properties
    
    override var serviceType: ContentShareServiceType { return .clipboard }
    
    // MARK: - Private Methods
    
    override func share(withLink link: String) {
        let pasteboard = UIPasteboard.general
        pasteboard.string = link
    }
    
}
