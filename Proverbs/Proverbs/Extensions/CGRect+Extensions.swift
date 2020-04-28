//
//  CGRect+Extensions.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 4/30/18.
//  Copyright © 2018 Yevhenii Zozulia. All rights reserved.
//

import UIKit

extension CGRect {
    
    static func makeCenter(forView: UIView , atView: UIView) -> CGRect {
        return CGRect.makeCenter(forRect: forView.frame, atRect: atView.frame)
    }
    
    static func makeCenter(forRect: CGRect, atView: UIView) -> CGRect {
        return CGRect.makeCenter(forRect: forRect, atRect: atView.frame)
    }
    
    static func makeCenter(forView: UIView , atRect: CGRect) -> CGRect {
        return CGRect.makeCenter(forRect: forView.frame, atRect: atRect)
    }
    
    static func makeCenter(forRect: CGRect , atRect: CGRect) -> CGRect {
        let x: CGFloat = (atRect.width - forRect.width) / 2
        let y: CGFloat = (atRect.height - forRect.height) / 2
        let width: CGFloat = forRect.width
        let height: CGFloat = forRect.height
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
}
