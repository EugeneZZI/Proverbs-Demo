//
//  FavoriteProverbsManager.swift
//  Proverbs
//
//  Created by Eugene Zozulya on 4/13/18.
//  Copyright © 2018 Eugene Zozulya. All rights reserved.
//

import UIKit
import RealmSwift

class FavoriteProverbsManager: NSObject {

    static let freeMaxCount = 5
    
    struct ErrorInfo {
        static let Domain = "FavoriteProverbsManager"
        
        struct Code {
            static let Internal         = 2300
            static let MaxLimit         = 2301
            static let IsFavorite       = 2302
            static let IsNotFavorite    = 2303
        }
    }
    
    struct NotificationName {
        static let DidSave    = "FavoriteProverbsManager.DidSave"
        static let DidDelete  = "FavoriteProverbsManager.DidDelete"
    }
    
    struct NotificationKey {
        static let FavoriteProverbIdentifier    = "FavoriteProverbsManager.FavoriteProverbIdentifier"
        static let OriginProverbIdentifier      = "FavoriteProverbsManager.OriginProverbIdentifier"
    }
    
    struct CompletionClosure {
        typealias Check   = ClosureBool
        typealias Save    = (FavoriteProverb?, Error?) -> Void
        typealias Delete  = (Error?) -> Void
        typealias Get     = ([FavoriteProverb]?, Error?) -> Void
    }
    
    static let shared = FavoriteProverbsManager()
    
    // MARK: - Properties
    
    private let localStorage    = LocalStorage<RFavoriteProverb>()
    private var remoteStorage:  FirestoreManager?
    
    private var userPlan: UserManager.Plan {
        return UserManager.shared.currentPlan
    }
    private var hasRestriction: Bool {
        return !IAPController.shared.isPurchased
    }
    private var isLocalStorage: Bool {
        return self.userPlan != .paidRegistered
    }
    
    // MARK: - Life Cycle Methods
    
    private override init() {
        super.init()
        self.addNotificationsObserver()
    }
    
    deinit {
        self.removeNotificationsObserver()
    }
    
    // MARK: - Public Methods
    
    func start() {
        self.setupFirestoreManager()
    }
    
    func getAll(withCompletion completion: @escaping CompletionClosure.Get) {
        if self.isLocalStorage {
            if let results = self.localStorage.getAll() {
                completion(Array(results), nil)
            } else {
                completion(nil, NSError(domain: ErrorInfo.Domain, code: ErrorInfo.Code.Internal, userInfo: nil))
            }
        } else {
            guard let remoteStorage = self.remoteStorage else {
                completion(nil, NSError(domain: ErrorInfo.Domain, code: ErrorInfo.Code.Internal, userInfo: nil))
                return
            }
            
            remoteStorage.getAllFavoriteProverbs(withCompletion: completion)
        }
    }
    
    func isFavorite(proverb: Proverb, completion: @escaping CompletionClosure.Check) {
        if self.isLocalStorage {
            completion(self.isFavoriteLocal(proverb: proverb))
        } else {
            self.isFavoriteRemote(proverb: proverb, completion: completion)
        }
    }
    
    func save(proverb: Proverb, completion: @escaping CompletionClosure.Save) {
        let identifiers = self.identifiers(fromProverb: proverb)
        
        let saveCompletion: CompletionClosure.Save = { (proverb, error) in
            if proverb != nil && error == nil {
                self.sendDidSaveNotification(proverbIdentifier: identifiers.favoriteIdentifier, withOriginIdentifier: identifiers.originIdentifier)
            }
            
            completion(proverb, error)
        }
        
        if self.isLocalStorage {
            let result = self.checkAndSaveLocal(proverb: proverb)
            saveCompletion(result.0, result.1)
        } else {
            self.chackAndSaveRemote(proverb: proverb, completion: saveCompletion)
        }
    }
    
    func delete(proverb: Proverb, completion: @escaping CompletionClosure.Delete) {
        let identifiers = self.identifiers(fromProverb: proverb)
        
        let deleteCompletion: CompletionClosure.Delete = { (error) in
            if error == nil {
                self.sendDidDeleteNotification(proverbIdentifier: identifiers.favoriteIdentifier, withOriginIdentifier: identifiers.originIdentifier)
            }
            
            completion(error)
        }
        
        if self.isLocalStorage {
            deleteCompletion(self.checkAndDeleteLocal(proverb: proverb))
        } else {
            self.checkAndDeleteRemote(proverb: proverb, completion: deleteCompletion)
        }
    }
    
    // MARK: - Private Methods
    
    private func identifiers(fromProverb proverb: Proverb) -> (favoriteIdentifier: String?, originIdentifier: String) {
        if let favoriteProverb = proverb as? FavoriteProverb {
            return (favoriteProverb.identifier, favoriteProverb.originIdentifier)
        } else {
            return (nil, proverb.identifier)
        }
    }
    
    // MARK: Firestore Manager Initial
    
    fileprivate func setupFirestoreManager() {
        guard let currentUserIdentifier = UserManager.shared.currentUserIdentifier else {
            return
        }
        
        self.remoteStorage = FirestoreManager(withUserIdentifier: currentUserIdentifier)
        self.remoteStorage?.loadOrCreateUserDocument(withCompletion: { (result) in
            if result {
                self.checkAndMigrateLocalFavoriteProverbs() { _ in
                    self.localStorage.deleteAll()
                }
            }
        })
    }
    
    fileprivate func deleteFirestoreManager() {
        self.remoteStorage = nil
    }
    
    private func checkAndMigrateLocalFavoriteProverbs(withCompletion completion: ClosureBool? = nil) {
        guard let local = self.getAllLocal() else {
            completion?(true)
            return
        }
        
        if local.count > 0 {
            guard let remoteStorage = self.remoteStorage else {
                completion?(false)
                return
            }
            
            remoteStorage.getAllFavoriteProverbs(withCompletion: { (favorites, error) in
                if let fFavorites = favorites, fFavorites.count > 0 { // compare and save
                    let toSave = self.filter(localProverbs: local, withRemoteProverbs: fFavorites)
                    if toSave.count > 0 {
                        self.saveToRemoteStorage(localFavoriteProverbs: toSave, completion: { result in completion?(result)})
                    } else {
                        completion?(true)
                    }
                } else { // just save
                    self.saveToRemoteStorage(localFavoriteProverbs: local, completion: { result in completion?(result)})
                }
            })
        } else {
            completion?(true)
        }
    }
    
    private func filter(localProverbs: [RFavoriteProverb], withRemoteProverbs remoteProverbs: [FFavoriteProverb]) -> [RFavoriteProverb] {
        var retList = [RFavoriteProverb]()
        
        for rProverb in localProverbs {
            if remoteProverbs.filter({ $0.originIdentifier == rProverb.originIdentifier }).count <= 0 {
                retList.append(rProverb)
            }
        }
        
        return retList
    }
    
    private func saveToRemoteStorage(localFavoriteProverbs proverbs: [RFavoriteProverb], completion: @escaping ClosureBool) {
        guard let remoteStorage = self.remoteStorage else {
            completion(false)
            return
        }
        
        let saveProverbs = proverbs.map { FFavoriteProverb(rFavoriteProverb: $0) }
        remoteStorage.save(proverbs: saveProverbs, completion: { result in
            completion(result)
        })
    }
    
    // MARK: Local Storage
    
    private func isFavoriteLocal(proverb: Proverb) -> Bool {
        if proverb is RFavoriteProverb {
            return true
        } else if let proverb = proverb as? RProverb {
            return self.localStorage.get(objectWithKey: RFavoriteProverb.SecondaryIndex.originIdentifier, withValue: proverb.identifier) != nil
        }
        
        return false
    }
    
    private func getAllLocal() -> [RFavoriteProverb]? {
        guard let results = self.localStorage.getAll() else {
            return nil
        }
        
        return Array(results)
    }
    
    private func checkAndSaveLocal(proverb: Proverb) -> (RFavoriteProverb?, Error?) {
        guard let proverb = proverb as? RProverb else {
            return (nil, NSError(domain: ErrorInfo.Domain, code: ErrorInfo.Code.IsFavorite, userInfo: nil))
        }
        
        if self.hasRestriction && self.getLocalCount() >= FavoriteProverbsManager.freeMaxCount {
                return (nil, NSError(domain: ErrorInfo.Domain, code: ErrorInfo.Code.MaxLimit, userInfo: nil))
        }
        
        let saveProverb = RFavoriteProverb(rProverb: proverb)
        if self.localStorage.saveUpdate(withModel: saveProverb) {
            return (saveProverb, nil)
        }
        
        return (nil, nil)
    }
    
    private func checkAndDeleteLocal(proverb: Proverb) -> Error? {
        let delete: (RFavoriteProverb) -> Error? = { rFavoriteProverb in

            if self.localStorage.delete(object: rFavoriteProverb) {                
                return nil
            } else {
                return NSError(domain: ErrorInfo.Domain, code: ErrorInfo.Code.Internal, userInfo: nil)
            }
        }
        
        if let rProverb = proverb as? RProverb {
            if let rFavoriteProverb = self.localStorage.get(objectWithKey: RFavoriteProverb.SecondaryIndex.originIdentifier, withValue: rProverb.identifier) {
                return delete(rFavoriteProverb)
            } else {
                return NSError(domain: ErrorInfo.Domain, code: ErrorInfo.Code.IsNotFavorite, userInfo: nil)
            }
        } else if let rFavoriteProverb = proverb as? RFavoriteProverb {
            return delete(rFavoriteProverb)
        } else {
            return NSError(domain: ErrorInfo.Domain, code: ErrorInfo.Code.IsNotFavorite, userInfo: nil)
        }
    }
    
    private func getLocalCount() -> Int {
        return self.localStorage.getAll()?.count ?? 0
    }
    
    // MARK: Remote Storage
    
    private func isFavoriteRemote(proverb: Proverb, completion: @escaping CompletionClosure.Check) {
        if proverb is RFavoriteProverb || proverb is FFavoriteProverb {
            completion(true)
        } else if let proverb = proverb as? RProverb {
            guard let remoteStorage = self.remoteStorage else {
                completion(false)
                return
            }
            
            remoteStorage.isFavorite(proverbWithOriginIdentifier: proverb.identifier, completion: completion)
        }
    }
    
    private func chackAndSaveRemote(proverb: Proverb, completion: @escaping CompletionClosure.Save) {
        guard let proverb = proverb as? RProverb else {
            completion(nil, NSError(domain: ErrorInfo.Domain, code: ErrorInfo.Code.IsFavorite, userInfo: nil))
            return
        }
        guard let remoteStorage = self.remoteStorage else {
            completion(nil, NSError(domain: ErrorInfo.Domain, code: ErrorInfo.Code.Internal, userInfo: nil))
            return
        }
        
        let fProverb = FFavoriteProverb(rProverb: proverb)
        remoteStorage.save(proverb: fProverb, completion: completion)
    }
    
    private func checkAndDeleteRemote(proverb: Proverb, completion: @escaping CompletionClosure.Delete) {
        let delete: (FFavoriteProverb) -> Void = { fFavoriteProverb in
            guard let remoteStorage = self.remoteStorage else {
                completion(NSError(domain: ErrorInfo.Domain, code: ErrorInfo.Code.Internal, userInfo: nil))
                return
            }
            
            remoteStorage.delete(proverb: fFavoriteProverb, completion: completion)
        }
        
        if let rProverb = proverb as? RProverb {
            self.remoteStorage?.getFavorite(withOriginIdentifier: rProverb.identifier, completion: { (fFavoriteProverb, error) in
                if let fFavoriteProverb = fFavoriteProverb {
                    delete(fFavoriteProverb)
                } else {
                    completion(NSError(domain: ErrorInfo.Domain, code: ErrorInfo.Code.IsNotFavorite, userInfo: nil))
                }
            })
        } else if let fFavoriteProverb = proverb as? FFavoriteProverb {
            return delete(fFavoriteProverb)
        } else {
            completion(NSError(domain: ErrorInfo.Domain, code: ErrorInfo.Code.IsNotFavorite, userInfo: nil))
        }
    }
    
    // MARK: Notifications
    
    private func sendDidSaveNotification(proverbIdentifier: String?, withOriginIdentifier: String) {
        let info = [NotificationKey.FavoriteProverbIdentifier: proverbIdentifier ?? "",
                    NotificationKey.OriginProverbIdentifier: withOriginIdentifier]
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationName.DidSave), object: nil, userInfo: info)
    }
    
    private func sendDidDeleteNotification(proverbIdentifier: String?, withOriginIdentifier: String) {
        let info = [NotificationKey.FavoriteProverbIdentifier: proverbIdentifier ?? "",
                    NotificationKey.OriginProverbIdentifier: withOriginIdentifier]
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationName.DidDelete), object: nil, userInfo: info)
    }
    
}

// MARK: - NotificationsObserver

extension FavoriteProverbsManager: NotificationsObserver {
    
    func notificationsInfo() -> [NotificationInfo] {
        return [(name: UserManager.NotificationName.DidSignIn, selector: #selector(FavoriteProverbsManager.userDidSignIn(_:))),
                (name: UserManager.NotificationName.WillSignOut, selector: #selector(FavoriteProverbsManager.userWillSignOut(_:))),
                (name: UserManager.NotificationName.DidSignOut, selector: #selector(FavoriteProverbsManager.userDidSignOut(_:)))]
    }
    
    @objc func userDidSignIn(_ notif: Notification) {
        self.setupFirestoreManager()
    }
    
    @objc func userWillSignOut(_ notif: Notification) {
        self.deleteFirestoreManager()
    }
    
    @objc func userDidSignOut(_ notif: Notification) {
    }
}
