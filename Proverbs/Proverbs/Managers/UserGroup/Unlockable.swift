//
//  Payable.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 4/28/18.
//  Copyright © 2018 Yevhenii Zozulia. All rights reserved.
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
