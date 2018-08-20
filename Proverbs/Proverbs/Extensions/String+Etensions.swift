//
//  String+Etensions.swift
//  Proverbs
//
//  Created by Eugene Zozulya on 4/11/18.
//  Copyright © 2018 Eugene Zozulya. All rights reserved.
//

import Foundation

extension String {
    
    static func randomString() -> String {
        return UUID().uuidString
    }
    
}

