//
//  IAPController.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 4/26/18.
//  Copyright © 2018 Yevhenii Zozulia. All rights reserved.
//


import SwiftyStoreKit

class IAPController {

    static let shared = IAPController()
    
    private static let PurchaseKey          = "IAPController.isPurchased.key"
    private static let ProductIdentifier    = "demo.EnglishProverbsAndSayings.fullaccess"
    
    struct NotificationName {
        static let DidPurchase  = "IAPController.DidPurchase"
    }
    
    // MARK: - Properties
    
    private(set) var isPurchased: Bool {
        get {
            #warning("Change to test paid version")
            return UserDefaults.standard.bool(forKey: IAPController.PurchaseKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: IAPController.PurchaseKey)
            UserDefaults.standard.synchronize()
            if newValue == true {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: IAPController.NotificationName.DidPurchase), object: nil, userInfo: nil)
            }
        }
    }
    
    // MARK: - Life Cycle Methods
    
    private init() {}
    
    // MARK: - Public Methods
    
    func start() {
        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    if purchase.needsFinishTransaction {
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                    DLog("\(purchase.transaction.transactionState.debugDescription): \(purchase.productId)")
                    self.isPurchased = true
                case .failed, .purchasing, .deferred:
                    self.isPurchased = false
                @unknown default: break
                }
            }
        }
    }
    
    func purchase(withCompletion completion: ClosureBool? = nil) {
        NetworkActivityIndicatorManager.networkOperationStarted()
        SwiftyStoreKit.purchaseProduct(IAPController.ProductIdentifier, atomically: true) { result in
            NetworkActivityIndicatorManager.networkOperationFinished()
            
            switch result {
            case .success(let purchase):
                let downloads = purchase.transaction.downloads
                if !downloads.isEmpty {
                    SwiftyStoreKit.start(downloads)
                }
                if purchase.needsFinishTransaction {
                    SwiftyStoreKit.finishTransaction(purchase.transaction)
                }
                self.isPurchased = true
                completion?(true)
            case .error(let error):
                DLog("Failed to purchase product with error \(error)")
                self.isPurchased = false
                completion?(false)
            }
        }
    }
    
    func restore(withCompletion completion: ClosureBool? = nil) {
        NetworkActivityIndicatorManager.networkOperationStarted()
        SwiftyStoreKit.restorePurchases(atomically: true) { results in
            NetworkActivityIndicatorManager.networkOperationFinished()
            
            if results.restoredPurchases.count <= 0 {
                self.isPurchased = false
                completion?(false)
                return
            }
            
            for purchase in results.restoredPurchases {
                let downloads = purchase.transaction.downloads
                if !downloads.isEmpty {
                    SwiftyStoreKit.start(downloads)
                } else if purchase.needsFinishTransaction {
                    SwiftyStoreKit.finishTransaction(purchase.transaction)
                }
            }
            
            self.isPurchased = true
            completion?(true)
        }
    }
    
}
