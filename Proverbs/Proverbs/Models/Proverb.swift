//
//  Proverb.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 4/28/18.
//  Copyright © 2018 Yevhenii Zozulia. All rights reserved.
//

import Foundation
import RealmSwift

protocol Proverb: BaseModelProtocol {
    
    var text:                       String          { get }
    var meaning:                    String          { get }
    var section:                    String          { get }
    
    func realmModel() -> Object?
    func firestoreModel() -> Any?
    
}
