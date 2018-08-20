//
//  Payable.swift
//  Proverbs
//
//  Created by Eugene Zozulya on 4/28/18.
//  Copyright © 2018 Eugene Zozulya. All rights reserved.
//

import Foundation

protocol Payable {
    
    var isPayable:                  Bool { get }
    var payedAndCanBePerformed:     Bool { get }
    
}
