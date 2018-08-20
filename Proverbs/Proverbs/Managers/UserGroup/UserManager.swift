//
//  UserManager.swift
//  Proverbs
//
//  Created by Eugene Zozulya on 4/11/18.
//  Copyright © 2018 Eugene Zozulya. All rights reserved.
//

import UIKit
import Firebase
import FBSDKLoginKit
import TwitterKit
import GoogleSignIn

class UserManager: NSObject, GIDSignInDelegate, GIDSignInUIDelegate {

    struct NotificationName {
        static let DidSignIn    = "UserManager.DidSignIn"
        static let WillSignOut  = "UserManager.WillSignOut"
        static let DidSignOut   = "UserManager.DidSignOut"
    }
    
    struct CompletionClosure {
        typealias Facebook  = ([String: AnyObject]?, Error?) -> Void
        typealias Twitter   = ((String, String)?, Error?) -> Void
        typealias Google    = ClosureBool
    }
    
    enum Login {
        case facebook
        case twitter
        case google
    }
    
    enum Plan {
        case free
        case paid
        case paidRegistered
    }
    
    static let shared = UserManager()
    
    // MARK: - Properties
    
    var isSignedIn: Bool {
        return Auth.auth().currentUser != nil
    }
    var currentUserIdentifier: String? {
        return Auth.auth().currentUser?.uid
    }
    private(set) var currentPlan = Plan.free
    
    // Google Sign In
    private weak var presentingViewController: UIViewController?
    private var googleCompletion: CompletionClosure.Google?
    
    // MARK: - Life Cycle Methods
    
    private override init() {
        super.init()
        self.addNotificationsObserver()
    }
    
    deinit {
        self.removeNotificationsObserver()
    }
    
    // MARK: - Public Methods
    
    func start() {
        self.logoutAtFirstLaunch()
        self.setupGoogleSigIn()
        self.updateCurrentPlan()
    }
    
    func canSignIn() -> Bool {
        return IAPController.shared.isPurchased
    }
    
    func signIn(onViewController viewController: UIViewController, withOption option: Login, completion: @escaping ClosureBool) {
        if !self.canSignIn() {
            completion(false)
            return
        }
        
        var authCredentials: AuthCredential?
        
        NetworkActivityIndicatorManager.networkOperationStarted()
        let internalCompletion = {
            NetworkActivityIndicatorManager.networkOperationFinished()
            
            if let auth = authCredentials {
                self.firebaseAuth(withCredentials: auth, completion: { result in
                    self.updateCurrentPlan()
                    completion(result)
                    if result {
                        self.sendDidSignInNotification()
                    }
                })
            } else {
                self.updateCurrentPlan()
                completion(false)
            }
        }
        
        switch option {
        case .facebook:
            self.facebookSignIn(withViewController: viewController, completion: { (info, error) in
                if let _ = info {
                    authCredentials = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                }
                internalCompletion()
            })
        case .twitter:
            self.twitterSignIn(withViewController: viewController, completion: {(info, error) in
                if let (token, secret) = info {
                    authCredentials = TwitterAuthProvider.credential(withToken: token, secret: secret)
                }
                internalCompletion()
            })
        case .google:
            self.googleSignIn(withViewController: viewController, completion: { result in
                NetworkActivityIndicatorManager.networkOperationFinished()
                
                self.updateCurrentPlan()
                completion(result)
                if result {
                    self.sendDidSignInNotification()
                }
            })
        }
    }
    
    func signOut(withCompletion completion: ClosureBool? = nil) {
        self.sendWillSignOutNotification()
        
        do {
            try Auth.auth().signOut()
        } catch let error {
            DLog("Failed to sign out with error \(error)")
            completion?(false)
            return
        }
        
        self.updateCurrentPlan()
        self.sendDidSignOutNotification()
        completion?(true)
    }
    
    // MARK: - GIDSignInDelegate
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            DLog("Failed signin with google with error \(error)")
            self.googleCompletion?(false)
        } else if let authentication = user.authentication {
            let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
            assert(self.googleCompletion != nil)
            firebaseAuth(withCredentials: credential, completion: self.googleCompletion!)
        } else {
            DLog("Failed signin with google")
            self.googleCompletion?(false)
        }
        
        self.googleCompletion = nil
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        DLog("---> \(error)")
    }
    
    // MARK: - GIDSignInUIDelegate
    
    func sign(inWillDispatch signIn: GIDSignIn!, error: Error!) {
        DLog("---> \(error)")
    }
    
    func sign(_ signIn: GIDSignIn!, present viewController: UIViewController!) {
        self.presentingViewController?.present(viewController, animated: true, completion: nil)
    }
    
    func sign(_ signIn: GIDSignIn!, dismiss viewController: UIViewController!) {
        viewController.dismiss(animated: true, completion: nil)
        self.presentingViewController = nil
    }
    
    // MARK: - Private Methods
    
    private func setupGoogleSigIn() {
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
    }
    
    fileprivate func updateCurrentPlan() {
        if self.isSignedIn && IAPController.shared.isPurchased {
            self.currentPlan = .paidRegistered
        } else if IAPController.shared.isPurchased {
            self.currentPlan = .paid
        } else {
           self.currentPlan = .free
        }
    }
    
    private func logoutAtFirstLaunch() {
        let flag = "_UserManager.firstLauch.flag"
        let userDefaults = UserDefaults.standard
        
        if !userDefaults.bool(forKey: flag) {
            self.signOut()
            userDefaults.set(true, forKey: flag)
            userDefaults.synchronize()
        }
    }
    
    // MARK: SignIn Methods
    
    private func facebookSignIn(withViewController viewController: UIViewController, completion: @escaping UserManager.CompletionClosure.Facebook) {
        FBSDKLoginManager().logIn(withReadPermissions: ["public_profile", "email"], from: viewController) { (result, error) in
            if let error = error {
                DLog("Failed to login with facebook. Error \(error)")
                completion(nil, error)
            } else if let result = result {
                if result.isCancelled {
                    completion(nil, nil)
                } else {
                    guard let request = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, email, first_name, last_name"]) else {
                        completion(nil, nil)
                        return
                    }
                    
                    request.start(completionHandler: { (connection, result, error) in
                        if let error = error {
                            DLog("Failed t fetch facebook data. Error \(error)")
                            completion(nil, error)
                        } else if let result = result as? [String: AnyObject] {
                            completion(result, nil)
                        } else { completion(nil, nil) }
                    })
                }
            } else {
                completion(nil, nil)
            }
        }

    }
    
    private func twitterSignIn(withViewController viewController: UIViewController, completion: @escaping UserManager.CompletionClosure.Twitter) {
        TWTRTwitter.sharedInstance().logIn(with: viewController) { (session, error) in
            if let error = error {
                DLog("Failed to login with twitter. Error \(error)")
                completion(nil, error)
            } else if let session = session {
                let authToken       = session.authToken
                let authTokenSecret = session.authTokenSecret
                completion((authToken, authTokenSecret), nil)
            } else {
                completion(nil, nil)
            }
        }
    }
    
    private func googleSignIn(withViewController viewController: UIViewController, completion: @escaping CompletionClosure.Google) {
        self.presentingViewController = viewController
        self.googleCompletion = completion
        
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().signIn()
    }
    
    private func firebaseAuth(withCredentials credentials: AuthCredential, completion: @escaping ClosureBool) {
        Auth.auth().signInAndRetrieveData(with: credentials) { (user, error) in
            if let error = error {
                DLog("Failed to auth with Farebase \(error)")
                completion(false)
            } else if let user = user {
                DLog("Did auth with Firebase. User: \(user)")
                completion(true)
            } else {
                DLog("Failed to auth with Firebase wihtout error")
                completion(false)
            }
        }
    }
    
    // MARK: Notifications Methods
    
    private func sendDidSignInNotification() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: UserManager.NotificationName.DidSignIn), object: nil, userInfo: nil)
    }

    private func sendWillSignOutNotification() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: UserManager.NotificationName.WillSignOut), object: nil, userInfo: nil)
    }
    
    private func sendDidSignOutNotification() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: UserManager.NotificationName.DidSignOut), object: nil, userInfo: nil)
    }
    
}

// MARK: - NotificationsObserver

extension UserManager: NotificationsObserver {
    
    func notificationsInfo() -> [NotificationInfo] {
        return [(name: IAPController.NotificationName.DidPurchase, selector: #selector(UserManager.userDidPurchase(_:)))]
    }
    
    @objc func userDidPurchase(_ notif: Notification) {
        self.updateCurrentPlan()
    }
    
}
