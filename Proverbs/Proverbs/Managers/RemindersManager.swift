//
//  RemindersManager.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 4/23/18.
//  Copyright © 2018 Yevhenii Zozulia. All rights reserved.
//


import UserNotifications
import DateToolsSwift

class RemindersManager {
    
    static let shared = RemindersManager()
    
    struct Completion {
        typealias Settings  = (UNAuthorizationStatus) -> Void
    }
    
    struct NotificationName {
        static let DidUpdateNotifications = "RemindersManager.DidUpdateNotifications"
    }
    
    private struct SettingsKeys {
        static let ReminderTime = "RemindersManager.SettingsKeys.ReminderTime"
        static let Enabled      = "RemindersManager.SettingsKeys.Enabled"
    }
    
    // MARK: - Properties
    
    var reminderTime: Date {
        get {
            if let date = self.userDefaults.object(forKey: SettingsKeys.ReminderTime) as? Date {
                return date
            }
            
            let time = self.defaultTime()
            self.userDefaults.set(time, forKey: SettingsKeys.ReminderTime)
            self.userDefaults.synchronize()
            
            return time
        }
        set {
            self.userDefaults.set(newValue, forKey: SettingsKeys.ReminderTime)
            self.userDefaults.synchronize()
            self.notifications(schedule: self.enabled)
        }
    }
    
    var enabled: Bool {
        get {
            return self.userDefaults.bool(forKey: SettingsKeys.Enabled)
        }
        set {
            if enabled != newValue {
                self.userDefaults.set(newValue, forKey: SettingsKeys.Enabled)
                self.userDefaults.synchronize()
                self.notifications(schedule: newValue)
                NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationName.DidUpdateNotifications), object: nil)
            }
        }
    }
    
    private let userDefaults        = UserDefaults.standard
    private let notificationsCenter = UNUserNotificationCenter.current()
    
    // MARK: - Life Cycle Methods
    
    private init() {}
    
    // MARK: - Public Methods
    
    func start() {
        self.waitAndCheckNotifications()
    }
    
    func checkIfUserChangedSettings() {
        self.checkNotificationsSettings { (status) in
            if status == .authorized && !self.enabled {
                self.enabled = true
            } else if status == .denied && self.enabled {
                self.enabled = false
            }
        }
    }
    
    func registerNotifications() {
        self.notificationsCenter.requestAuthorization(options: [.alert, .sound]) { (result, error) in
            async_main {
                DLog("Notifications auth result \(result) - \(String(describing: error))")
                self.enabled = result
            }
        }
    }
    
    func checkNotificationsSettings(withCompletion completion: Completion.Settings? = nil) {
        self.notificationsCenter.getNotificationSettings(completionHandler: { (settings) in
            async_main {
                completion?(settings.authorizationStatus)
            }
        })
    }

    // MARK: - Private Methods
    
    private func waitAndCheckNotifications() {
        after(90) {
            self.checkNotificationsSettings(withCompletion: { (settings) in
                if settings == .notDetermined {
                    self.registerNotifications()
                }
            })
        }
    }
    
    private func defaultTime() -> Date {
        var date = Date()
        date.hour(13)
        date.minute(0)
        date.second(0)
        
        return date
    }
    
    private func notifications(schedule: Bool) {        
        self.notificationsCenter.removeAllPendingNotificationRequests()
        
        if schedule {
            let content = UNMutableNotificationContent()
            content.title = "It's time!"
            content.body = "Check proverb of the day!"
            content.sound = UNNotificationSound.default
            
            let date = self.reminderTime
            let triggerDaily = Calendar.current.dateComponents([.hour, .minute, .second,], from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDaily, repeats: true)
            
            let identifier = "RemindersManager.DailyReminder"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            self.notificationsCenter.add(request) { (error) in
                if let error = error {
                    DLog("Failed to schedule notifications with error \(error)")
                }
            }
        }
    }
    
    private func printNotificationsInfo() {
        DLog("---> PRINT NOTIFICATIONS")
        self.notificationsCenter.getPendingNotificationRequests { (requests) in
            for request in requests {
                DLog("---> Time \(request.trigger.debugDescription)")
            }
        }
    }
}
