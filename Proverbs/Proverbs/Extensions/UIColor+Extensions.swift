//
//  UIColor+Extensions.swift
//  Proverbs
//
//  Created by Eugene Zozulya on 10/22/19.
//  Copyright © 2019 Eugene Zozulya. All rights reserved.
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
    
    public convenience init(hex: String) {
        let hexString: String = hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let scanner = Scanner(string: hexString)
        if (hexString.hasPrefix("#")) {
            scanner.scanLocation = 1
        }
        var color: UInt32 = 0
        scanner.scanHexInt32(&color)
        let mask = 0x000000FF
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask
        let red   = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue  = CGFloat(b) / 255.0
        self.init(red:red, green:green, blue:blue, alpha:1.0)
    }
    
}

