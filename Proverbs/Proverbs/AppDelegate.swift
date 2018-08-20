//
//  AppDelegate.swift
//  Proverbs
//
//  Created by Eugene Zozulya on 4/10/18.
//  Copyright © 2018 Eugene Zozulya. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import Fabric
import Crashlytics
import Firebase
import TwitterKit
import GoogleSignIn
import GoogleMobileAds

// TODO: Add keys for all SDKs before launch

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        TWTRTwitter.sharedInstance().start(withConsumerKey:"", consumerSecret:"")
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        Fabric.with([Crashlytics.self])
        FirebaseApp.configure()
        GADMobileAds.configure(withApplicationID: "")
        ProverbsManager.shared.checkAndPopulateProverbs()
        
        UserManager.shared.start()
        IAPController.shared.start()
        FavoriteProverbsManager.shared.start()
        RemindersManager.shared.start()
        
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        RemindersManager.shared.checkIfUserChangedSettings()
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        let fb = FBSDKApplicationDelegate.sharedInstance().application(app, open: url, options: options)
        let tw = TWTRTwitter.sharedInstance().application(app, open:url, options: options)
        let gl = GIDSignIn.sharedInstance().handle(url, sourceApplication:options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String, annotation: [:])
        return fb || tw || gl
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }

}

