//
//  ViewControllerConstructor.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 4/11/18.
//  Copyright © 2018 Yevhenii Zozulia. All rights reserved.
//

import UIKit

enum StoryboardType: String {
    case Main
}

protocol ViewControllerConstructor: class {
    static var storyboardType: StoryboardType { get }
    static func create() -> Self?
}

extension ViewControllerConstructor {

    private static func storyboardInfo() -> (identifier: String, type: StoryboardType)? {
        guard self is UIViewController.Type else {
            DLog("I'm not a view controller - \(String(describing: self))")
            return nil
        }
        
        let identifier = String(describing: self)
        let type = self.storyboardType
        
        return (identifier: identifier, type: type)
    }
    
    static func create() -> Self? {
        guard let vcInfo = self.storyboardInfo() else {
            return nil
        }
        
        return UIStoryboard.get(withType: vcInfo.type).instantiateViewController(withIdentifier: vcInfo.identifier) as? Self
    }
    
}

extension UIStoryboard {
    
    class func get(withType type: StoryboardType) -> UIStoryboard {
        let storyboardName = type.rawValue
        return UIStoryboard(name: storyboardName, bundle: nil)
    }

}


