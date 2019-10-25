//
//  GlobalUI.swift
//  Proverbs
//
//  Created by Eugene Zozulya on 4/14/18.
//  Copyright © 2018 Eugene Zozulya. All rights reserved.
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

class ColorsRandomizer {
    
    class func randomColor() -> UIColor {
        let allAppColors = UIColor.allAppColors
        let randomIndex = Int(arc4random_uniform(UInt32(allAppColors.count)))
        return allAppColors[randomIndex]
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
        let mainAppColors   = UIColor.mainAppColors
        let allAppColors    = UIColor.allAppColors
        let mainCount       = mainAppColors.count
        let allCount        = allAppColors.count
        
        if self.colorsCount < mainCount {
            self.colors = Array(mainAppColors[0...self.colorsCount])
        } else if self.colorsCount < allCount {
            self.colors = Array(allAppColors[0...self.colorsCount])
        } else {
            let count = self.colorsCount / allAppColors.count + 1
            for _ in 0..<count {
                self.colors.append(contentsOf: allAppColors)
            }
        }
    }
    
}
