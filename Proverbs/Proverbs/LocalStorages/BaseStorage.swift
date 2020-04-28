//
//  BaseStorage.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 4/11/18.
//  Copyright © 2018 Yevhenii Zozulia. All rights reserved.
//

import Foundation
import RealmSwift

class BaseStorage {
    
    typealias ProcessClosure = (_ realm: Realm?) -> Void
    
    fileprivate class func createRealm() -> Realm? {
        var retRealm: Realm?
        do {
            try retRealm = Realm()
        } catch let error {
            DLog("Failed to init Realm \(error)")
        }
        return retRealm
    }
    
    class func migrate() {
        let config = Realm.Configuration( schemaVersion: 1,
                                          migrationBlock: { migration, oldSchemaVersion in
                                        })
        
        Realm.Configuration.defaultConfiguration = config
    }
    
    fileprivate class func hardReset() {
        let realmURL = Realm.Configuration.defaultConfiguration.fileURL!
        let realmURLs = [
            realmURL,
            realmURL.appendingPathExtension("lock"),
            realmURL.appendingPathExtension("log_a"),
            realmURL.appendingPathExtension("log_b"),
            realmURL.appendingPathExtension("note")
        ]
        for url in realmURLs {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                DLog("Failed to delete realm URL \(url)")
            }
        }
    }
    
    // MARK: - Properties
    
    var currentThreadRealm: Realm? {
        if Thread.isMainThread {
            return self.mainRealm
        } else {
            return BaseStorage.createRealm()
        }
    }
    
    fileprivate var mainRealm: Realm? {
        return MainStorage.shared.realm
    }
    
    // MARK: - Public Methods
    
    func realmWrite(_ realm: Realm? = nil, processBlock: BaseStorage.ProcessClosure) -> Error? {
        let writeRealm = realm ?? self.currentThreadRealm
        var retError: Error?
        
        do {
            try writeRealm?.write({ processBlock(writeRealm) })
        } catch let error {
            retError = error
        }
        
        return retError
    }
    
    func realmFindAll<T: Object>(_ type: T.Type) -> Results<T>? {
        return self.currentThreadRealm?.objects(type)
    }
    
    func realmAddOrUpdate<T: Object>(_ objects: [T], realm: Realm? = nil) -> (objects: [T]?, error: Error?) {
        let error = self.realmWrite(realm, processBlock: { (realm) in
            realm?.add(objects, update: .all)
        })
        
        return error == nil ? (objects, nil) : (nil, error)
    }
    
    func realmDelete(_ objects: [Object]) -> Error? {
        let error = self.realmWrite(processBlock: { (realm) in
            realm?.delete(objects)
        })
        
        return error
    }
    
    func realmDeleteAll<T: Object>(_ type: T.Type) -> Error? {
        guard let results = self.realmFindAll(type) else {
            DLog("Did not find any objects with type \(type)")
            return nil
        }
        
        let realm = results.realm
        let error = self.realmWrite(realm, processBlock: { (realm) in
            realm?.delete(results)
        })
        
        return error
    }
    
    func cleanRealm() {
        if let error = self.realmWrite(processBlock: { realm in realm?.deleteAll() }) {
            DLog("Failed to clean realm \(error)")
        }
    }
    
}

private class MainStorage {
    
    static let shared = MainStorage()
    
    lazy var realm: Realm? = {
        
        var retRealm = BaseStorage.createRealm()
        if retRealm == nil {
            let _ = self.lazyResetVar
            retRealm = BaseStorage.createRealm()
        }
        
        return retRealm
    }()
    
    private lazy var lazyResetVar: Bool = {
        BaseStorage.hardReset()
        return true
    }()
    
}
