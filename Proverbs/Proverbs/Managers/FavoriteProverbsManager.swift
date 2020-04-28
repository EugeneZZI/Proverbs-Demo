//
//  FavoriteProverbsManager.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 4/13/18.
//  Copyright © 2018 Yevhenii Zozulia. All rights reserved.
//

import RealmSwift

enum FavoriteProverbsManagerError: Error {
    case undefined
    case maxLimit(Int)
    case isFavorite
    case isNotFavorite
}

class FavoriteProverbsManager {

    static let freeMaxCount = 5
    
    struct NotificationName {
        static let DidSave    = "FavoriteProverbsManager.DidSave"
        static let DidDelete  = "FavoriteProverbsManager.DidDelete"
    }
    
    struct NotificationKey {
        static let FavoriteProverbIdentifier    = "FavoriteProverbsManager.FavoriteProverbIdentifier"
        static let OriginProverbIdentifier      = "FavoriteProverbsManager.OriginProverbIdentifier"
    }
    
    struct Completion {
        typealias Check   = ClosureBool
        typealias Save    = (Result<FavoriteProverb, Error>) -> Void
        typealias Delete  = (Error?) -> Void
        typealias Get     = (Result<[FavoriteProverb], Error>) -> Void
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
    
    private init() {
        self.addNotificationsObserver()
    }
    
    deinit {
        self.removeNotificationsObserver()
    }
    
    // MARK: - Public Methods
    
    func start() {
        self.setupFirestoreManager()
    }
        
    func getAll(withCompletion completion: @escaping Completion.Get) {
        if self.isLocalStorage {
            if let results = self.localStorage.getAll() {
                completion(.success(Array(results)))
            } else {
                completion(.failure(FavoriteProverbsManagerError.undefined))
            }
        } else {
            guard let remoteStorage = self.remoteStorage else {
                completion(.failure(FavoriteProverbsManagerError.undefined))
                return
            }
            
            remoteStorage.getAllFavoriteProverbs { completion($0.map { $0 }) }
        }
    }
    
    func isFavorite(proverb: Proverb, completion: @escaping Completion.Check) {
        if self.isLocalStorage {
            completion(self.isFavoriteLocal(proverb: proverb))
        } else {
            self.isFavoriteRemote(proverb: proverb, completion: completion)
        }
    }
    
    func save(proverb: Proverb, completion: @escaping Completion.Save) {
        let identifiers = self.identifiers(fromProverb: proverb)
        
        let saveCompletion: Completion.Save = { result in
            switch result {
            case .success(_):
                self.sendDidSaveNotification(proverbIdentifier: identifiers.favoriteIdentifier, withOriginIdentifier: identifiers.originIdentifier)
            default: break
            }
            
            completion(result)
        }
        
        if self.isLocalStorage {
            switch self.checkAndSaveLocal(proverb: proverb) {
            case .success(let proverb): saveCompletion(.success(proverb))
            case .failure(let error): saveCompletion(.failure(error))
            }
        } else {
            self.chackAndSaveRemote(proverb: proverb, completion: saveCompletion)
        }
    }
    
    func delete(proverb: Proverb, completion: @escaping Completion.Delete) {
        let identifiers = self.identifiers(fromProverb: proverb)
        
        let deleteCompletion: Completion.Delete = { (error) in
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
            
            remoteStorage.getAllFavoriteProverbs(withCompletion: { result in
                switch result {
                case .success(let favorites):
                    if favorites.count > 0 { // compare and save
                        let toSave = self.filter(localProverbs: local, withRemoteProverbs: favorites)
                        if toSave.count > 0 {
                            self.saveToRemoteStorage(localFavoriteProverbs: toSave, completion: { result in completion?(result)})
                        } else {
                            completion?(true)
                        }
                    } else { // just save
                        self.saveToRemoteStorage(localFavoriteProverbs: local, completion: { result in completion?(result)})
                    }
                case .failure(let error):
                    DLog("Error \(error)")
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
    
    private func checkAndSaveLocal(proverb: Proverb) -> Result<RFavoriteProverb, Error> {
        guard let proverb = proverb as? RProverb else {
            return .failure(FavoriteProverbsManagerError.isFavorite)
        }
        
        if self.hasRestriction && self.getLocalCount() >= FavoriteProverbsManager.freeMaxCount {
            return .failure(FavoriteProverbsManagerError.maxLimit(FavoriteProverbsManager.freeMaxCount))
        }
        
        let saveProverb = RFavoriteProverb(rProverb: proverb)
        if self.localStorage.saveUpdate(withModel: saveProverb) {
            return .success(saveProverb)
        }
        
        return .failure(FavoriteProverbsManagerError.undefined)
    }
    
    private func checkAndDeleteLocal(proverb: Proverb) -> Error? {
        let delete: (RFavoriteProverb) -> Error? = { rFavoriteProverb in

            if self.localStorage.delete(object: rFavoriteProverb) {                
                return nil
            } else {
                return FavoriteProverbsManagerError.undefined
            }
        }
        
        if let rProverb = proverb as? RProverb {
            if let rFavoriteProverb = self.localStorage.get(objectWithKey: RFavoriteProverb.SecondaryIndex.originIdentifier, withValue: rProverb.identifier) {
                return delete(rFavoriteProverb)
            } else {
                return FavoriteProverbsManagerError.isNotFavorite
            }
        } else if let rFavoriteProverb = proverb as? RFavoriteProverb {
            return delete(rFavoriteProverb)
        } else {
            return FavoriteProverbsManagerError.isNotFavorite
        }
    }
    
    private func getLocalCount() -> Int {
        return self.localStorage.getAll()?.count ?? 0
    }
    
    // MARK: Remote Storage
    
    private func isFavoriteRemote(proverb: Proverb, completion: @escaping Completion.Check) {
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
    
    private func chackAndSaveRemote(proverb: Proverb, completion: @escaping Completion.Save) {
        guard let proverb = proverb as? RProverb else {
            completion(.failure(FavoriteProverbsManagerError.isFavorite))
            return
        }
        guard let remoteStorage = self.remoteStorage else {
            completion(.failure(FavoriteProverbsManagerError.undefined))
            return
        }
        
        let fProverb = FFavoriteProverb(rProverb: proverb)
        remoteStorage.save(proverb: fProverb) { completion( $0.map{ $0 }) }
    }
    
    private func checkAndDeleteRemote(proverb: Proverb, completion: @escaping Completion.Delete) {
        let delete: (FFavoriteProverb) -> Void = { fFavoriteProverb in
            guard let remoteStorage = self.remoteStorage else {
                completion(FavoriteProverbsManagerError.undefined)
                return
            }
            
            remoteStorage.delete(proverb: fFavoriteProverb, completion: completion)
        }
        
        if let rProverb = proverb as? RProverb {
            self.remoteStorage?.getFavorite(withOriginIdentifier: rProverb.identifier, completion: { result in
                switch result {
                case .success(let proverb):
                    delete(proverb)
                case .failure(let error):
                    completion(error)
                }
            })
        } else if let fFavoriteProverb = proverb as? FFavoriteProverb {
            return delete(fFavoriteProverb)
        } else {
            completion(FavoriteProverbsManagerError.isNotFavorite)
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

extension FavoriteProverbsManagerError: LocalizedError {
    
    var errorDescription: String? {
        switch self {
        case .isFavorite:
            return "Proverb is favorite"
        case .isNotFavorite:
            return "Proverb is not favorite"
        case .maxLimit(let limit):
            return "Proverbs limit \(limit) is reached"
        default:
            return "Undefined Error"
        }
    }
    
}
