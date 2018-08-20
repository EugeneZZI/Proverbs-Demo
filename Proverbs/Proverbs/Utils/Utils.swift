//
//  Utils.swift
//  Proverbs
//
//  Created by Eugene Zozulya on 4/11/18.
//  Copyright © 2018 Eugene Zozulya. All rights reserved.
//

import Foundation
import UIKit

let BundleID = Bundle.main.bundleIdentifier


typealias ClosureVoid   = () -> ()
typealias ClosureText   = (String?) -> ()
typealias ClosureBool   = (Bool) -> Void
typealias ClosureError  = (NSError?) -> Void

#if targetEnvironment(simulator)
let IsSimulator = true
#else
let IsSimulator = false
#endif

// MARK: iOS Screen Constants

struct ScreenSize {
    static let width            = UIScreen.main.bounds.size.width
    static let height           = UIScreen.main.bounds.size.height
    static let maxLength        = max(ScreenSize.width, ScreenSize.height)
    static let minLength        = min(ScreenSize.width, ScreenSize.height)
}

struct DeviceType {
    static let iPhone_35          = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.maxLength < 568.0
    static let iPhone_40          = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.maxLength == 568.0
    static let iPhone_47          = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.maxLength == 667.0
    static let iPhone_55          = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.maxLength == 736.0
    static let iPhone_X           = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.maxLength == 812.0
    static let iPad               = UIDevice.current.userInterfaceIdiom == .pad
}

// MARK: Logging

func DLog(_ message: String, function: String = #function, line: Int = #line) {
    #if DEBUG
        let timeString = DateFormatter.loggingDateFormatter.string(from: Date())
        print("\(timeString) \(function):\(line) --- \(message)")
    #endif
}

private extension DateFormatter {
    
    static var loggingDateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ssssss"
        return dateFormatter
    }
    
}

// MARK: GCD

func after(_ delay: TimeInterval, queue: DispatchQueue = DispatchQueue.main, closure: @escaping ClosureVoid) {
    queue.asyncAfter(deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}

func async_main(_ closure: @escaping ClosureVoid) {
    DispatchQueue.main.async(execute: closure)
}

func async(_ queue: DispatchQueue = DispatchQueue.global(), closure: @escaping ClosureVoid) {
    queue.async(execute: closure)
}

func sync_main(_ closure: @escaping ClosureVoid) {
    if Thread.isMainThread {
        closure()
    } else {
        DispatchQueue.main.sync(execute: closure)
    }
}

func sync(_ queue: DispatchQueue = DispatchQueue.global(), closure: ClosureVoid) {
    queue.sync(execute: closure)
}

// MARK: Info

let DeviceID = UIDevice.current.identifierForVendor?.uuidString

enum BuildType: String {
    case Release
    case Debug
    
    static var current: BuildType {
        #if DEBUG
            return .Debug
        #else
            return .Release
        #endif
    }
}

// MARK: - Utils

class App {
    
    class var realName: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String
    }
    
    class var buildNumber: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
    }
    
    class var shortVersion: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    }
    
}
