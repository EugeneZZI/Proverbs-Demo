//
//  Payable.swift
//  Proverbs
//
//  Created by Eugene Zozulya on 4/28/18.
//  Copyright © 2018 Eugene Zozulya. All rights reserved.
//

import Foundation

enum UnlockableType {
    case pay
    case payOrShare
    case free
}

protocol Unlockable {
    
    var unlockType:         UnlockableType { get }
    var canBePerformed:     Bool { get }
    
}
