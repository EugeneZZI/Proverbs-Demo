//
//  AppDelegate.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 4/10/18.
//  Copyright © 2018 Yevhenii Zozulia. All rights reserved.
//


import FBSDKCoreKit
import Firebase
import TwitterKit
import GoogleSignIn
import GoogleMobileAds


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        TWTRTwitter.sharedInstance().start(withConsumerKey:"XXXX", consumerSecret:"XXXX")
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        FirebaseApp.configure()
        GADMobileAds.sharedInstance().start { _ in }
        ProverbsManager.shared.checkAndPopulateProverbs()
        
        UserManager.shared.start()
        IAPController.shared.start()
        FavoriteProverbsManager.shared.start()
        RemindersManager.shared.start()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        RemindersManager.shared.checkIfUserChangedSettings()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        let fb = ApplicationDelegate.shared.application(app, open: url, options: options)
        let tw = TWTRTwitter.sharedInstance().application(app, open:url, options: options)
        let gl = GIDSignIn.sharedInstance()?.handle(url) ?? false
        return fb || tw || gl
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return ApplicationDelegate.shared.application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }


}

