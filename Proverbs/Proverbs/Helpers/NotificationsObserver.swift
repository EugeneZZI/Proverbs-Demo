//
//  NotificationsObserver.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 4/29/18.
//  Copyright © 2018 Yevhenii Zozulia. All rights reserved.
//

import Foundation

typealias NotificationInfo = (name: String, selector: Selector)

protocol NotificationsObserver: class {
    func notificationsInfo() -> [NotificationInfo]
}

extension NotificationsObserver {
    
    func addNotificationsObserver() {
        let notificationCenter = NotificationCenter.default
        
        self.notificationsInfo().forEach { info in
            notificationCenter.addObserver(self, selector: info.selector, name: NSNotification.Name(rawValue: info.name), object: nil)
        }
    }
    
    func removeNotificationsObserver() {
        NotificationCenter.default.removeObserver(self)
    }
    
}
