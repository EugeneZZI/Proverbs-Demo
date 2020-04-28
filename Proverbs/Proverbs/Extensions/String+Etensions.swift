//
//  String+Etensions.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 4/11/18.
//  Copyright © 2018 Yevhenii Zozulia. All rights reserved.
//

import Foundation

extension String {
    
    static func random() -> String {
        return UUID().uuidString
    }
    
}

