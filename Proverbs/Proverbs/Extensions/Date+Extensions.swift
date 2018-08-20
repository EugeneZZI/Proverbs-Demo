//
//  Date+Extensions.swift
//  Proverbs
//
//  Created by Eugene Zozulya on 4/11/18.
//  Copyright © 2018 Eugene Zozulya. All rights reserved.
//

import Foundation

extension Date {
    
    static func zero() -> Date {
        return Date(timeIntervalSince1970: 0.0)
    }
    
    func isZero() -> Bool {
        return self.timeIntervalSince1970 == 0.0
    }
    
}
