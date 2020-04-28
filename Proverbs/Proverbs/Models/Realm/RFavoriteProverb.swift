//
//  RFavoriteProverb.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 4/11/18.
//  Copyright © 2018 Yevhenii Zozulia. All rights reserved.
//


import RealmSwift

class RFavoriteProverb: Object, FavoriteProverb {

    struct SecondaryIndex {
        static let originIdentifier  = "_originIdentifier"
    }
    
    override static func primaryKey() -> String? {
        return "_identifier"
    }
    
    override static func indexedProperties() -> [String] {
        return ["_originIdentifier"]
    }
    
    // MARK: - Properties
    
    @objc dynamic var _identifier                    = ""
    @objc dynamic var _originIdentifier              = ""
    @objc dynamic var _createdAt                     = Date.zero()
    
    @objc dynamic var _text                          = ""
    @objc dynamic var _meaning                       = ""
    @objc dynamic var _section                       = ""
    
    // MARK: - FavoriteProverb
    
    var identifier:                 String          { return _identifier }
    var createdAt:                  Date            { return _createdAt }
    var isRealm:                    Bool            { return true }
    
    var text:                       String          { return _text }
    var meaning:                    String          { return _meaning }
    var section:                    String          { return _section }
    
    var originIdentifier:           String          { return _originIdentifier }
    
    func realmModel() -> Object? {
        return self
    }
    
    func firestoreModel() -> Any? {
        return nil
    }
    
    // MARK: - Life Cycle Methods
    
    convenience init(rProverb: RProverb) {
        self.init()
        
        self._identifier        = String.random()
        self._originIdentifier  = rProverb._identifier
        self._createdAt         = Date()
        self._text              = rProverb._text
        self._meaning           = rProverb._meaning
        self._section           = rProverb._section
    }
    
}
