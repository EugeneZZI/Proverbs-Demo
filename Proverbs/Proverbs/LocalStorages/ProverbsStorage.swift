//
//  ProverbsStorage.swift
//  Proverbs
//
//  Created by Eugene Zozulya on 4/13/18.
//  Copyright © 2018 Eugene Zozulya. All rights reserved.
//

import UIKit

class ProverbsStorage: LocalStorage<RProverb> {

    // MARK: - Public Methods
    
    func getProverb(withIdentifier identifier: String) -> RProverb? {
        return self.realmFindAll(RProverb.self)?.filter("_identifier == %@", identifier).first
    }
    
    func getAll() -> [RProverb] {
        guard let list = self.realmFindAll(RProverb.self) else {
            return [RProverb]()
        }
        
        return Array(list)
    }
    
    func getAllUnviewed() -> [RProverb] {
        if let unviewed = self.realmFindAll(RProverb.self)?.filter("_viewed == false") {
            return Array(unviewed)
        }
        
        return [RProverb]()
    }
    
    func markAsViewed(proverb: RProverb) {
        _ = self.realmWrite { (_) in
            proverb._viewed = true
        }
    }
    
    func markAllAsUnviewed() {
        if let all = self.realmFindAll(RProverb.self)    {
            _ = self.realmWrite(processBlock: { (_) in
                all.forEach { $0._viewed = false }
            })
        }
    }
    
}
