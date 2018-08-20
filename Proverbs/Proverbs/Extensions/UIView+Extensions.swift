//
//  UIView+Extensions.swift
//  Proverbs
//
//  Created by Eugene Zozulya on 4/14/18.
//  Copyright © 2018 Eugene Zozulya. All rights reserved.
//

import UIKit

extension UIView {
    
    func image() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0.0)
        defer { UIGraphicsEndImageContext() }
        if let context = UIGraphicsGetCurrentContext() {
            self.layer.render(in: context)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            return image
        }
        return nil
    }
    
}
