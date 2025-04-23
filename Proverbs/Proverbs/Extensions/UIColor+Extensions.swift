//
//  UIColor+Extensions.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 10/22/19.
//  Copyright © 2019 Yevhenii Zozulia. All rights reserved.
//

import UIKit

extension UIColor {
    
    static let appBlue             = UIColor(named: "appBlue")!
    static let appGrayBlue         = UIColor(named: "appGrayBlue")!
    static let appDarkGrayBlue     = UIColor(named: "appDarkGrayBlue")!
    static let appYellow           = UIColor(named: "appYellow")!
    static let appRed              = UIColor(named: "appRed")!
    static let appGrayCancel       = UIColor(named: "appGrayCancel")!

    static let appFacebookButton   = UIColor(named: "appFacebookButton")!
    static let appTwitterButton    = UIColor(named: "appTwitterButton")!
    static let appGoogleButton     = UIColor(named: "appGoogleButton")!

    static let appMainFont         = UIColor(named: "appMainFont")!
    static let appShadow           = UIColor(named: "appShadow")!

    class var mainAppColors: [UIColor] {
        return [UIColor.appBlue,
                UIColor.appDarkGrayBlue,
                UIColor.appRed,
                UIColor.appGrayBlue,
                UIColor.appYellow]
    }

    class var allAppColors: [UIColor] {
        return [UIColor.appBlue,
                UIColor.appDarkGrayBlue,
                UIColor.appRed,
                UIColor.appGrayBlue,
                UIColor.appYellow,
                UIColor.appFacebookButton,
                UIColor.appGoogleButton,
                UIColor.appTwitterButton]
    }
    
}

