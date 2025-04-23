//
//  GlobalUI.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 4/14/18.
//  Copyright © 2018 Yevhenii Zozulia. All rights reserved.
//

import UIKit

struct GlobalUI {
    
    struct Sizes {
        static var elementHeight:       CGFloat     {
            return 40.0
        }
    }
    
    struct Offsets {
        static var buttonsSide:         CGFloat     {
            return 9.0
        }
        static var side:                CGFloat     {
            return 30.0
        }
        static var verticalSpacing:     CGFloat     {
            return 24.0
        }
    }
    
    struct Fonts {
        static var mainSize: CGFloat {
            return 17.0
        }
    }
    
    struct Oblique {
        static var ratio: CGFloat {
            return 0.5
        }
        static var cornerRadius: CGFloat {
            return 4.0
        }
    }
    
    struct NavigationBar {
        static let defaultButtonSize                = CGSize(width: 58.0, height: 40.0)
        static let menuIconSideOffset               = CGFloat(10.0)
        static let backIconSideOffset               = CGFloat(15.0)
        static let tableViewSectionTitleOffset      = CGFloat(5.0)
    }
}
