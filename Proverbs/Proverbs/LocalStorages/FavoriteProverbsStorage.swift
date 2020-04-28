//
//  FavoriteProverbsStorage.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 4/28/18.
//  Copyright © 2018 Yevhenii Zozulia. All rights reserved.
//



class FavoriteProverbsStorage: LocalStorage<RFavoriteProverb> {

    // MARK: - Public Methods
    
    func getAll() -> [RFavoriteProverb] {
        return [RFavoriteProverb]()
    }
    
    func save(favoriteProverb: RFavoriteProverb) {
        _ = self.realmAddOrUpdate([favoriteProverb])
    }
    
    func delete(favoriteProverb: RFavoriteProverb) {
        _ = self.realmDelete([favoriteProverb])
    }
    
}
