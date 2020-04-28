//
//  ColorsRandomizer.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 28.04.2020.
//  Copyright © 2020 Yevhenii Zozulia. All rights reserved.
//

import UIKit

class ColorsRandomizer {
    
    class func randomColor() -> UIColor {
        return UIColor.allAppColors.randomElement()!
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
