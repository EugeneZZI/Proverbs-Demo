//
//  UserManager.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 4/11/18.
//  Copyright © 2018 Yevhenii Zozulia. All rights reserved.
//


import Firebase
import FBSDKLoginKit
import TwitterKit
import GoogleSignIn

class UserManager: NSObject, GIDSignInDelegate {

    struct NotificationName {
        static let DidSignIn    = "UserManager.DidSignIn"
        static let WillSignOut  = "UserManager.WillSignOut"
        static let DidSignOut   = "UserManager.DidSignOut"
    }
    
    struct Completion {
        typealias Facebook  = (Result<[String: AnyObject], Error>) -> Void
        typealias Twitter   = (Result<(String, String), Error>) -> Void
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
    private var googleCompletion: Completion.Google?
    
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
            self.facebookSignIn(withViewController: viewController, completion: { result in
                switch result {
                case .success(_):
                    if let token = AccessToken.current?.tokenString {
                        authCredentials = FacebookAuthProvider.credential(withAccessToken: token)
                    }
                case .failure(let error):
                    DLog("Error \(error)")
                    break
                }
                internalCompletion()
            })
        case .twitter:
            self.twitterSignIn(withViewController: viewController, completion: { result in
                switch result {
                case .success(let info):
                    let (token, secret) = info
                    authCredentials = TwitterAuthProvider.credential(withToken: token, secret: secret)
                case .failure(let error):
                    DLog("Error \(error)")
                    break
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
        DLog("---> \(String(describing: error))")
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
    
    private func facebookSignIn(withViewController viewController: UIViewController, completion: @escaping UserManager.Completion.Facebook) {
        LoginManager().logIn(permissions: ["public_profile", "email"], from: viewController) { (result, error) in
            if let error = error {
                DLog("Failed to login with facebook. Error \(error)")
                completion(.failure(error))
            } else if let result = result {
                if result.isCancelled {
                    completion(.failure(UndefinedError()))
                } else {
                    let request = GraphRequest(graphPath: "me", parameters: ["fields": "id, email, first_name, last_name"])
                    request.start(completionHandler: { (connection, result, error) in
                        if let error = error {
                            DLog("Failed t fetch facebook data. Error \(error)")
                            completion(.failure(error))
                        } else if let result = result as? [String: AnyObject] {
                            completion(.success(result))
                        } else {
                            completion(.failure(UndefinedError()))
                        }
                    })
                }
            } else {
                completion(.failure(UndefinedError()))
            }
        }

    }
    
    private func twitterSignIn(withViewController viewController: UIViewController, completion: @escaping UserManager.Completion.Twitter) {
        TWTRTwitter.sharedInstance().logIn(with: viewController) { (session, error) in
            if let error = error {
                DLog("Failed to login with twitter. Error \(error)")
                completion(.failure(error))
            } else if let session = session {
                let info = (session.authToken, session.authTokenSecret)
                completion(.success(info))
            } else {
                completion(.failure(UndefinedError()))
            }
        }
    }
    
    private func googleSignIn(withViewController viewController: UIViewController, completion: @escaping Completion.Google) {
        self.googleCompletion = completion
        
        GIDSignIn.sharedInstance()?.presentingViewController = viewController
        GIDSignIn.sharedInstance().signIn()
    }
    
    private func firebaseAuth(withCredentials credentials: AuthCredential, completion: @escaping ClosureBool) {
        Auth.auth().signIn(with: credentials) { (user, error) in
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
