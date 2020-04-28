//
//  LocalStorage.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 4/11/18.
//  Copyright © 2018 Yevhenii Zozulia. All rights reserved.
//


import RealmSwift

class LocalStorage<RModel: Object>: BaseStorage {

    // MARK: - Public Methods
    
    func get(objectWithKey key: String, withValue value: Any) -> RModel? {
        return self.currentThreadRealm?.objects(RModel.self).filter("\(key) == %@", value).first
    }
    
    func get(objectWithDict dict: [String: Any]) -> RModel? {
        var filterString = ""
        var args = [Any]()
        
        for (key, value) in dict {
            if filterString.isEmpty {
                filterString += "\(key) == %@"
            } else {
                filterString += " AND \(key) == %@"
            }
            args.append(value)
        }
        
        let predicate = NSPredicate(format: filterString, argumentArray: args)
        return self.currentThreadRealm?.objects(RModel.self).filter(predicate).first
    }
    
    func get(objectWithIdentifier identifier: String) -> RModel? {
        return self.get(objectWithKey: RBase.SecondaryIndex.identifier, withValue: identifier)
    }
    
    func getAll() -> Results<RModel>? {
        return self.currentThreadRealm?.objects(RModel.self)
    }
    
    func saveUpdate(withModel model: RModel) -> Bool {
        return self.saveUpdate(withModelsList: [model])
    }
    
    func saveUpdate(withModelsList modelsList: [RModel]) -> Bool {
        return self.realmAddOrUpdate(modelsList).objects != nil
    }
    
    func delete(objectWithIdentifier identifier: String) -> Bool {
        if let rObj = self.get(objectWithIdentifier: identifier) {
            return self.delete(object: rObj)
        }
        
        return false
    }
    
    func delete(object: RModel) -> Bool {
        if self.realmDelete([object]) == nil {
            return true
        }

        return false
    }
    
    func deleteAll(exceptID: String? = nil) {
        if let exceptID = exceptID, let delObjects = self.findAll(exceptID: exceptID) {
            let _ = self.realmDelete(delObjects)
        } else {
            _ = self.realmDeleteAll(RModel.self)
        }
    }
    
    // MARK: - Private Methods
    
    private func findAll(exceptID: String) -> [RModel]? {
        if let results = self.currentThreadRealm?.objects(RModel.self).filter("_identifier != %@", exceptID) {
            return Array(results)
        }
        
        return nil
    }

}
