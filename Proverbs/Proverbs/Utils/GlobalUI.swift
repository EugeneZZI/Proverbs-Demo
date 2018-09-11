//
//  GlobalUI.swift
//  Proverbs
//
//  Created by Eugene Zozulya on 4/14/18.
//  Copyright © 2018 Eugene Zozulya. All rights reserved.
//

import UIKit
import SwiftHEXColors

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
    
    struct Colors {
        static let blue             = UIColor(hexString:"349FC4")!
        static let grayBlue         = UIColor(hexString:"51838E")!
        static let darkGrayBlue     = UIColor(hexString:"566B6F")!
        static let yellow           = UIColor(hexString:"EFB63D")!
        static let red              = UIColor(hexString:"EF5C3D")!
        static let grayCancel       = UIColor(hexString:"9B9B9B")!
        
        static let facbookButton    = UIColor(hexString:"3C5A99")!
        static let twitterButton    = UIColor(hexString:"3AAAE1")!
        static let googleButton     = UIColor(hexString:"EC4338")!
        
        static let mainFont         = UIColor.white //.withAlphaComponent(0.8)
        
        var mainColors: [UIColor] {
            return [Colors.blue, Colors.darkGrayBlue, Colors.red, Colors.grayBlue, Colors.yellow]
        }
        
        var allColors: [UIColor] {
            return [Colors.blue, Colors.darkGrayBlue, Colors.red, Colors.grayBlue, Colors.yellow, Colors.facbookButton, Colors.googleButton, Colors.twitterButton]
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

class ColorsRandomizer {
    
    class func randomColor() -> UIColor {
        let allColors = GlobalUI.Colors().allColors
        let randomIndex = Int(arc4random_uniform(UInt32(allColors.count)))
        return allColors[randomIndex]
    }
    
    private let colorsCount: Int
    private var colors = [UIColor]()
    
    init(colorsCount: Int) {
        self.colorsCount = colorsCount
        self.setColorList()
    }
    
    func nextRandomColor() -> UIColor {
        if self.colors.count == 0 {
            assert(false, "Not enought colors")
            return UIColor.white
        }
        
        let randomIndex = Int(arc4random_uniform(UInt32(self.colors.count)))
        let retColor = self.colors[randomIndex]
        self.colors.remove(at: randomIndex)
        
        return retColor
    }
    
    private func setColorList() {
        let globalColors    = GlobalUI.Colors()
        let mainCount       = globalColors.mainColors.count
        let allCount        = globalColors.allColors.count
        
        if self.colorsCount < mainCount {
            self.colors = Array(globalColors.mainColors[0...self.colorsCount])
        } else if self.colorsCount < allCount {
            self.colors = Array(globalColors.allColors[0...self.colorsCount])
        } else {
            let allColors = globalColors.allColors
            let count = self.colorsCount / allColors.count + 1
            for _ in 0..<count {
                self.colors.append(contentsOf: allColors)
            }
        }
    }
    
}
