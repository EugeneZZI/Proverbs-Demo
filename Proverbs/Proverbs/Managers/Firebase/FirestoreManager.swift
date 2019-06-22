//
//  FirestoreManager.swift
//  Proverbs
//
//  Created by Eugene Zozulya on 4/28/18.
//  Copyright © 2018 Eugene Zozulya. All rights reserved.
//

import UIKit
import Firebase

class FirestoreManager: NSObject {
    
    struct CompletionClosure {
        typealias Check   = ClosureBool
        typealias Save    = (FFavoriteProverb?, Error?) -> Void
        typealias Delete  = (Error?) -> Void
        typealias Get     = (FFavoriteProverb?, Error?) -> Void
        typealias GetAll  = ([FFavoriteProverb]?, Error?) -> Void
    }
    
    
    private struct Collections {
        static let Users            = "Users"
        static let FavoriteProverbs = "FavoriteProverbs"
    }
    
    // MARK: - Properties
    
    private let currentUserIdentifier: String
    private lazy var fireStore: Firestore = {
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        let db = Firestore.firestore()
        db.settings = settings
        
        return db
    }()
    private lazy var usersCollection: CollectionReference = {
        return self.fireStore.collection(Collections.Users)
    }()
    private var userDocument: DocumentReference?
    private var favoritesCollection: CollectionReference? {
        return self.userDocument?.collection(Collections.FavoriteProverbs)
    }
    
    // MARK: - Life Cycle Methods
    
    init(withUserIdentifier identifier: String) {
        self.currentUserIdentifier = identifier
        super.init()
    }
    
    // MARK: - Public Methods
    
    func loadOrCreateUserDocument(withCompletion completion: @escaping ClosureBool) {
        NetworkActivityIndicatorManager.networkOperationStarted()
        self.userDocument = self.usersCollection.document(self.currentUserIdentifier)
        self.checkAndCreateCurrentUser { result in
            NetworkActivityIndicatorManager.networkOperationFinished()
            
            if !result {
                self.userDocument = nil
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    func getAllFavoriteProverbs(withCompletion completion: @escaping CompletionClosure.GetAll) {
        guard let favoritesCollection = self.favoritesCollection else {
            completion(nil, nil)
            return
        }
        
        NetworkActivityIndicatorManager.networkOperationStarted()
        favoritesCollection.getDocuments { (snapshot, error) in
            NetworkActivityIndicatorManager.networkOperationFinished()
            
            if let error = error {
                DLog("Failed to load favorite documents with error \(error)")
                completion(nil, error)
            } else if let snapshot = snapshot {
                var fProverbs = [FFavoriteProverb]()
                
                for document in snapshot.documents {
                    let fProverb = FFavoriteProverb(dictionary: document.data())
                    fProverbs.append(fProverb)
                }
                
                completion(fProverbs, nil)
            } else {
                DLog("Failed to load favorite documents")
                completion(nil, nil)
            }
        }
    }
    
    func getFavorite(withOriginIdentifier identifier: String, completion: @escaping CompletionClosure.Get) {
        guard let collection = self.favoritesCollection else {
            completion(nil, self.getInternalError())
            return
        }
        
        NetworkActivityIndicatorManager.networkOperationStarted()
        collection.whereField(FFavoriteProverb.SecondaryIndex.originIdentifier, isEqualTo: identifier).getDocuments { (snapshot, error) in
            NetworkActivityIndicatorManager.networkOperationFinished()
            
            if let error = error {
                DLog("Failed to get favorite document with error \(error)")
                completion(nil, error)
            } else if let snapshot = snapshot {
                if let document = snapshot.documents.first?.data() {
                    completion(FFavoriteProverb(dictionary: document), nil)
                } else {
                    completion(nil, nil)
                }
            } else {
                DLog("Failed to get favorite document")
                completion(nil, nil)
            }
        }
    }
    
    func save(proverbs: [FFavoriteProverb], completion: @escaping ClosureBool) {
        guard let collection = self.favoritesCollection else {
            completion(false)
            return
        }
        
        if proverbs.count == 0 {
            completion(true)
            return
        }
        
        NetworkActivityIndicatorManager.networkOperationStarted()
        let batch = self.fireStore.batch()
        
        for proverb in proverbs {
            let document = collection.document(proverb.identifier)
            batch.setData(proverb.dictionary(), forDocument: document)
        }
        
        batch.commit() { err in
            NetworkActivityIndicatorManager.networkOperationFinished()
            
            if let err = err {
                DLog("Error writing batch \(err)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    func save(proverb: FFavoriteProverb, completion: @escaping CompletionClosure.Save) {
        guard let collection = self.favoritesCollection else {
            completion(nil, self.getInternalError())
            return
        }
        
        NetworkActivityIndicatorManager.networkOperationStarted()
        collection.document(proverb.identifier).setData(proverb.dictionary()) { error in
            NetworkActivityIndicatorManager.networkOperationFinished()
            
            if let error = error {
                DLog("Failed to save proverb \(error)")
                completion(nil, error)
            } else {
                completion(proverb, nil)
            }
        }
    }
    
    func delete(proverb: FFavoriteProverb, completion: @escaping CompletionClosure.Delete) {
        guard let collection = self.favoritesCollection else {
            completion(self.getInternalError())
            return
        }
        
        NetworkActivityIndicatorManager.networkOperationStarted()
        collection.document(proverb.identifier).delete() { error in
            NetworkActivityIndicatorManager.networkOperationFinished()
            
            if let error = error {
                DLog("Failed to delete proverb \(error)")
                completion(error)
            } else {
                completion(nil)
            }
        }
    }
    
    func isFavorite(proverbWithOriginIdentifier identifier: String, completion: @escaping CompletionClosure.Check) {
        guard let collection = self.favoritesCollection else {
            completion(false)
            return
        }
        
        NetworkActivityIndicatorManager.networkOperationStarted()
        collection.whereField(FFavoriteProverb.SecondaryIndex.originIdentifier, isEqualTo: identifier).getDocuments { (snapshot, error) in
            NetworkActivityIndicatorManager.networkOperationFinished()
            
            if let error = error {
                DLog("Failed to check favorite document with error \(error)")
                completion(false)
            } else if let snapshot = snapshot {
                if snapshot.documents.count > 1 {
                    DLog("---> We have too many favorite proverbs!")
                }
                completion(snapshot.documents.count > 0)
            } else {
                DLog("Failed to check favorite document")
                completion(false)
            }
        }
    }
    
    // MARK: - Private Methods
    
    func checkAndCreateCurrentUser(withCompletion completion: @escaping ClosureBool) {
        self.userDocument?.getDocument(completion: { (snapshot, error) in
            if let error = error {
                DLog("Failed to load user document with error \(error)")
                completion(false)
            } else if let userSnapshot = snapshot {
                if userSnapshot.data() == nil { // user doesn't exist
                    self.createNewUser(withCompletion: completion)
                } else {
                    completion(true)
                }
            } else {
                DLog("Failed to load user document")
                completion(false)
            }
        })
    }
    
    private func createNewUser(withCompletion completion: @escaping ClosureBool) {
        self.usersCollection.document(self.currentUserIdentifier).setData([String : Any]()) { error in
            if let error = error {
                DLog("failed to create new user \(error)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    private func getInternalError() -> Error {
        return NSError(domain: "FirestoreManagerDomain", code: 25235, userInfo: nil)
    }
}


