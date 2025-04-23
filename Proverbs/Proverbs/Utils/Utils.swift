//
//  Utils.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 4/11/18.
//  Copyright © 2018 Yevhenii Zozulia. All rights reserved.
//

import UIKit

let BundleID = Bundle.main.bundleIdentifier

typealias ClosureVoid   = () -> ()
typealias ClosureText   = (String?) -> ()
typealias ClosureBool   = (Bool) -> Void
typealias ClosureError  = (Error?) -> Void

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

// MARK: Logging

private let logDateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "HH:mm:ss.SSSS"
    return dateFormatter
}()

func DLog(_ message: String, function: String = #function, line: Int = #line) {
    let timeString = logDateFormatter.string(from: Date())
    print("\(timeString) \(function):\(line) --- \(message)")
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

class UndefinedError: LocalizedError {
    var errorDescription: String? = "Undefined Error"
}
