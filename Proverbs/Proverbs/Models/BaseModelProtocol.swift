//
//  BaseModelProtocol.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 4/28/18.
//  Copyright © 2018 Yevhenii Zozulia. All rights reserved.
//

import Foundation

protocol BaseModelProtocol {
    
    var identifier:                 String          { get }
    var createdAt:                  Date            { get }
    var isRealm:                    Bool            { get }
}
