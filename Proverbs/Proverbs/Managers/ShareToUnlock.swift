//
//  ShareManager.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 9/10/18.
//  Copyright © 2018 Yevhenii Zozulia. All rights reserved.
//

import TrueTime

class ShareToUnlock {
    
    static let shared = ShareToUnlock()
    
    private struct DefaultsKeys {
        static let Unlock       = "ShareManager.isUnlocked.key"
        static let LastDate     = "ShareManager.LastDate.key"
        static let CurrentCount = "ShareManager.CurrentCount.key"
    }
    
    struct NotificationName {
        static let DidUnlock  = "ShareToUnlock.DidUnlock"
    }
    
    // MARK: - Properties
    
    var daysLeftToUnlock: Int { return self.requiredShareDays - self.currentShareCount }
    
    private(set) var isUnlocked: Bool {
        get {
            #warning("Change to test unlocked with sharing version")
            return UserDefaults.standard.bool(forKey: DefaultsKeys.Unlock)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: DefaultsKeys.Unlock)
            UserDefaults.standard.synchronize()
            if newValue == true {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: ShareToUnlock.NotificationName.DidUnlock), object: nil, userInfo: nil)
            }
        }
    }
    private(set) var currentShareCount: Int {
        get {
            return UserDefaults.standard.integer(forKey: DefaultsKeys.CurrentCount)
        }
        set {
            if newValue >= self.requiredShareDays && !self.isUnlocked {
                self.isUnlocked = true
            }
            
            UserDefaults.standard.set(newValue, forKey: DefaultsKeys.CurrentCount)
            UserDefaults.standard.synchronize()
        }
    }
    private(set) var lastShareDate: Date? {
        get {
            return UserDefaults.standard.object(forKey: DefaultsKeys.LastDate) as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: DefaultsKeys.LastDate)
            UserDefaults.standard.synchronize()
        }
    }
    
    private let requiredShareDays = 5
    
    // MARK: - Life Cycle Methods
    
    private init() {
        if !self.isUnlocked {
            TrueTimeClient.sharedInstance.start()
        }
    }
    
    // MARK: - Public Methods
    
    func checkAndChangeCounter(completion: @escaping ClosureBool) {
        if self.isUnlocked {
            completion(false)
            return
        }
        
        self.getCurrentDate { (currentDate) in
            
            let updateLastShareDate = {
                self.lastShareDate = currentDate
                self.currentShareCount = self.currentShareCount + 1
            }
            
            DLog("---> Current date \(currentDate)")
            guard let lastShareDate = self.lastShareDate else {
                updateLastShareDate()
                completion(true)
                return
            }
            
            DLog("---> Last date \(lastShareDate)")
            let result = !lastShareDate.isToday && currentDate.isLater(than: lastShareDate)
            if result { updateLastShareDate() }
            completion(result)            
        }
    }
    
    // MARK: - Private Methods
    
    private func getCurrentDate(completion: @escaping (Date) -> Void) {
        TrueTimeClient.sharedInstance.fetchIfNeeded() {
            result in
            switch result {
            case let .success(referenceTime):
                completion(referenceTime.now())
            case let .failure(error):
                DLog("Error! \(error)")
                completion(Date())
            }
        }
    }
    
}

