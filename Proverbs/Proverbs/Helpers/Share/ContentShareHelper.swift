//
//  ContentShareHelper.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 4/11/18.
//  Copyright © 2018 Yevhenii Zozulia. All rights reserved.
//

import UIKit

enum ContentShareServiceType {
    case facebook
    case twitter
    case clipboard
    case undefined
    
    func title() -> String {
        switch self {
        case .facebook:             return "Facebook"
        case .twitter:              return "Twitter"
        case .clipboard:            return "Clipboard"
        case .undefined:            return "Undefined"
        }
    }
}

protocol ContentShareHelperDelegate: class {
    
    func contentShareHelperDidShare(_ helper: ContentShareHelper)
    func contentShareHelperDidCancelShare(_ helper: ContentShareHelper)
    func contentShareHelperDidFailToShare(_ helper: ContentShareHelper, error: Error?)
    
}

class ContentShareHelper: NSObject {

    typealias Delegate = (ContentShareHelperDelegate & UIViewController)
    
    class func shareTypes() -> [ContentShareServiceType] {
        var retInfo = [ContentShareServiceType]()

        if FacebookShareHelper.canShare()   { retInfo.append(.facebook) }
        if TwitterShareHelper.canShare()    { retInfo.append(.twitter) }
        if ClipboardShareHelper.canShare()  { retInfo.append(.clipboard) }

        return retInfo
    }
    
    class func canShare() -> Bool {
        return false
    }
    
    static func createShareHelper(withServiceType serviceType: ContentShareServiceType, proverb: Proverb, delegate: Delegate) -> ContentShareHelper? {
        switch serviceType {
        case .facebook:     return FacebookShareHelper(withProverb: proverb, delegate: delegate)
        case .twitter:      return TwitterShareHelper(withProverb: proverb, delegate: delegate)
        case .clipboard:    return ClipboardShareHelper(withProverb: proverb, delegate: delegate)
        default: return nil
        }
    }
    
    // MARK: - Properties
    
    var serviceType: ContentShareServiceType { return .undefined }
    
    private(set) var proverb:       Proverb
    private(set) weak var delegate: Delegate?
    
    // MARK: - Life Cycle Methods
    
    init(withProverb proverb: Proverb, delegate: Delegate) {
        self.proverb = proverb
        self.delegate = delegate
        super.init()
    }
    
    // MARK: - Public Methods

    func share() {
        let baseURLString = "https://www.saypro.me/share/"
        var identifier = proverb.identifier
        if let favoriteProverb = self.proverb as? FavoriteProverb {
            identifier = favoriteProverb.originIdentifier
        }
        let shareURLString = baseURLString + identifier + ".html"
        self.share(withLink: shareURLString)
    }
    
    // MARK: - Private Methods
    
    func share(withLink link: String) {
        
    }
    
}
