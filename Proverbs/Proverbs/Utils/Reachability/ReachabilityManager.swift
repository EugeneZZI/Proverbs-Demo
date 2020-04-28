//
//  ReachabilityManager.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 4/11/18.
//  Copyright © 2018 Yevhenii Zozulia. All rights reserved.
//

import CoreTelephony
import Reachability

final class ReachabilityManager {
    
    static let shared = ReachabilityManager()
    
    // MARK: Properties
    
    fileprivate(set) var reachability: Reachability?
    var isReachable: Bool {
        if let r = self.reachability { return r.connection != .unavailable }
        return false
    }
    
    // MARK: Life Cycle Methods

    private init() {
        do {
            try self.reachability = Reachability()
        } catch {
            DLog("Failed to create reachability")
            return
        }
        
        self.startNotifier()
        after(1.0) { self.addNotificationsObserver() }
    }
    
    deinit {
        self.removeNotificationsObserver()
    }
    
    // MARK: Public Methods
    
    func isQuickConnection() -> Bool {
        guard let r = self.reachability else { return false }
        
        if r.connection == .wifi { return true }
        
        let telephonyInfo = CTTelephonyNetworkInfo()
        if let technology = telephonyInfo.currentRadioAccessTechnology {
            switch technology {
            case CTRadioAccessTechnologyGPRS,
                 CTRadioAccessTechnologyEdge,
                 CTRadioAccessTechnologyCDMA1x: return false
            default: return true
            }
        }
        
        return false
    }
    
    func connectionTechnologyDescription() -> String {
        guard let r = self.reachability else { return "Undefined" }
        
        if r.connection == .wifi { return "WiFi" }
        
        let telephonyInfo = CTTelephonyNetworkInfo()
        if let technology = telephonyInfo.currentRadioAccessTechnology {
            switch technology {
            case CTRadioAccessTechnologyGPRS:           return "GPRS"
            case CTRadioAccessTechnologyEdge:           return "Edge"
            case CTRadioAccessTechnologyWCDMA:          return "WCDMA"
            case CTRadioAccessTechnologyHSDPA:          return "HSDPA"
            case CTRadioAccessTechnologyHSUPA:          return "HSUPA"
            case CTRadioAccessTechnologyCDMA1x:         return "CDMA1x"
            case CTRadioAccessTechnologyCDMAEVDORev0:   return "CDMAEVDORev0"
            case CTRadioAccessTechnologyCDMAEVDORevA:   return "CDMAEVDORevA"
            case CTRadioAccessTechnologyCDMAEVDORevB:   return "CDMAEVDORevB"
            case CTRadioAccessTechnologyeHRPD:          return "eHRPD"
            case CTRadioAccessTechnologyLTE:            return "LTE"
            default: return "Undefined"
            }
        }
        
        return "Undefined"
    }
    
    // MARK: Private Methods
    
    fileprivate func addNotificationsObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(ReachabilityManager.reachabilityChangedNotification(_:)),    name: Notification.Name.reachabilityChanged, object: nil)
    }
    
    fileprivate func removeNotificationsObserver() {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func startNotifier() {
        do {
            try self.reachability?.startNotifier()
        } catch let error {
            DLog("Failed to start reachability notifier error \(error)")
        }
    }
    
    @objc func reachabilityChangedNotification(_ notif: Notification) {
        if self.isReachable == false {
        }
    }

}
