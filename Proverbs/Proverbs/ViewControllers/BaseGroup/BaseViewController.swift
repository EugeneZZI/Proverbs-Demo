//
//  BaseViewController.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 4/11/18.
//  Copyright © 2018 Yevhenii Zozulia. All rights reserved.
//

import UIKit
import Reachability
import NVActivityIndicatorView

class BaseViewController: UIViewController, ViewControllerConstructor, NavigationBarDelegate, NVActivityIndicatorViewable {
    
    static var storyboardType: StoryboardType { return self._storyboardType }
    class var _storyboardType: StoryboardType { return .Main }
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var internalNavigationBar:   NavigationBar?
    @IBOutlet weak var backgroundImageView:     UIImageView?
    
    // MARK: - Properties
    
    fileprivate var shareHelper:    ContentShareHelper?
    
    let notificaionCenter           = NotificationCenter.default
    let reachabilityManager         = ReachabilityManager.shared
    var isKeyboardVisible           = false
    
    var activityIndicator:          NVActivityIndicatorView?
    
    var statusBarStyle: UIStatusBarStyle = .default {
        didSet {
            if oldValue != statusBarStyle {
                self.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
    
    var statusBarHidden = false {
        didSet {
            if oldValue != statusBarHidden {
                self.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
    
    var isVisible: Bool {
        return self.viewIfLoaded?.window != nil
    }
    
    // MARK: - Life cycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupViews()
        self.setupLocalization()
        
        self.addNotificationsObserver()
        self.setNeedsStatusBarAppearanceUpdate()
        
        
        self.internalNavigationBar?.viewController = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setNeedsStatusBarAppearanceUpdate()
        
        self.setupViewsWithReachability(self.reachabilityManager.isReachable)
        self.addKeyboardNotificationsObserver()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.removeKeyboardNotificationsObserver()
    }
    
    deinit {
        self.removeNotificationsObserver()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return self.statusBarStyle
    }
    
    override var prefersStatusBarHidden : Bool {
        return self.statusBarHidden
    }
    
    // MARK: - Notifications Methods
    
    func addNotificationsObserver() {
        self.notificaionCenter.addObserver(self, selector: #selector(BaseViewController.reachabilityChangedNotification(_:)),    name: Notification.Name.reachabilityChanged, object: nil)
    }
    
    func removeNotificationsObserver() {
        self.notificaionCenter.removeObserver(self)
    }
    
    func addKeyboardNotificationsObserver() {
        self.notificaionCenter.addObserver(self, selector: #selector(BaseViewController.keyboardWillShow(_:)),    name: UIResponder.keyboardWillShowNotification, object: nil)
        self.notificaionCenter.addObserver(self, selector: #selector(BaseViewController.keyboardDidShow(_:)),     name: UIResponder.keyboardDidShowNotification, object: nil)
        self.notificaionCenter.addObserver(self, selector: #selector(BaseViewController.keyboardWillHide(_:)),    name: UIResponder.keyboardWillHideNotification, object: nil)
        self.notificaionCenter.addObserver(self, selector: #selector(BaseViewController.keyboardDidHide(_:)),     name: UIResponder.keyboardDidHideNotification, object: nil)
    }
    
    func removeKeyboardNotificationsObserver() {
        self.notificaionCenter.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        self.notificaionCenter.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
        self.notificaionCenter.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        self.notificaionCenter.removeObserver(self, name: UIResponder.keyboardDidHideNotification, object: nil)
    }
    
    // MARK: - Keyboard methods
    
    @objc func hideKeyboard() {
        self.view.endEditing(true)
        self.view.window?.endEditing(true)
    }
    
    @objc func keyboardWillShow(_ notif: Notification) {
        self.isKeyboardVisible = true
    }
    
    @objc func keyboardDidShow(_ notif: Notification) {
        
    }
    
    @objc func keyboardWillHide(_ notif: Notification) {
        self.isKeyboardVisible = false
    }
    
    @objc func keyboardDidHide(_ notif: Notification) {
        
    }
    
    // MARK: - Reachability Methods
    
    func setupViewsWithReachability(_ isReachable: Bool) {
        
    }
    
    @objc func reachabilityChangedNotification(_ notif: Notification) {
        self.setupViewsWithReachability(self.reachabilityManager.isReachable)
    }
    
    func showNetworkErrorNotificationView() {
    }
    
    func checkAndShowOfflineAlert() -> Bool {
        if self.reachabilityManager.isReachable == false {
        }
        
        return !self.reachabilityManager.isReachable
    }
    
    // MARK: - Views Methods
    
    func setupViews() {
        
    }
    
    func setupLocalization() {
    }
    
    func showElementView(_ view: UIView, show: Bool, animated: Bool) {
        let newAlpha: CGFloat = show ? 1.0 : 0.0
        if view.alpha == newAlpha { return }
        
        let showClosure = { view.alpha = newAlpha }
        
        if animated {
            UIView.animate(withDuration: 0.3, animations: showClosure)
        } else {
            showClosure()
        }
    }
    
    func view(block: Bool) {
        self.navigationController?.navigationBar.isUserInteractionEnabled = !block
        self.tabBarController?.tabBar.isUserInteractionEnabled = !block
    }
    
    // MARK: - Activity Indicator Methods
    
    func activityIndicator(show: Bool, blockView: Bool = false) {
        if show && self.activityIndicator == nil {
            self.activityIndicator = self.createActivityIndicatorView()
            self.view.addSubview(self.activityIndicator!)
            self.activityIndicator?.startAnimating()
            self.view.isUserInteractionEnabled = blockView ? false : true
        } else if !show && self.activityIndicator != nil {
            self.activityIndicator?.stopAnimating()
            self.activityIndicator = nil
            self.view.isUserInteractionEnabled = true
        }
    }
    
    func createActivityIndicatorView() -> NVActivityIndicatorView {
        var frame = CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0)
        frame = CGRect.makeCenter(forRect: frame, atView: self.view)
        return NVActivityIndicatorView(frame: frame, type: NVActivityIndicatorType.ballScaleRippleMultiple)
    }
    
    // MARK: - NavigationBarDelegate
    
    func leftbuttonPushed(_ navigationBar: NavigationBar) {
    }
    
    func rightbuttonPushed(_ navigationBar: NavigationBar) {
    }
    
}

// MARK: Share
extension BaseViewController: ContentShareHelperDelegate {
    
    func makeShareActionSheet(withDelegate viewController: ContentShareHelper.Delegate, proverb: Proverb) -> ActionSheetViewController? {
        guard let actionSheet = ActionSheetViewController.make(withTitle: "Share via") else {
            return nil
        }
        
        let share = {
            guard let helper = self.shareHelper else {
                return
            }
            
            helper.share()
        }
        
        let facebookAction = ActionSheetItem(type: .select, title: "Facebook", color: UIColor.appFacebookButton) { _ in
            self.shareHelper = ContentShareHelper.createShareHelper(withServiceType: .facebook, proverb: proverb, delegate: viewController)
            share()
        }
        let twitterAction = ActionSheetItem(type: .select, title: "Twitter", color: UIColor.appTwitterButton) { _ in
            self.shareHelper = ContentShareHelper.createShareHelper(withServiceType: .twitter, proverb: proverb, delegate: viewController)
            share()
        }
        let clipboardAction = ActionSheetItem(type: .select, title: "Copy Link") { _ in
            self.shareHelper = ContentShareHelper.createShareHelper(withServiceType: .clipboard, proverb: proverb, delegate: viewController)
            share()
        }
        let cancelAction = ActionSheetItem(type: .destructive, title: "Cancel")
        
        actionSheet.addItem(facebookAction)
        actionSheet.addItem(twitterAction)
        actionSheet.addItem(clipboardAction)
        actionSheet.addItem(cancelAction)
        
        return actionSheet
    }
    
    func contentShareHelperDidShare(_ helper: ContentShareHelper) {
        defer { self.shareHelper = nil }
        if IAPController.shared.isPurchased { return }
        
        if helper.serviceType == .facebook || helper.serviceType == .twitter {
            ShareToUnlock.shared.checkAndChangeCounter(completion: { (result) in
                if !result { return }
                if ShareToUnlock.shared.isUnlocked { self.showCongratulationAlert() }
                else { self.showLeftDaysAlert() }
            })
        }
    }
    
    func contentShareHelperDidCancelShare(_ helper: ContentShareHelper) {
        self.shareHelper = nil
    }
    
    func contentShareHelperDidFailToShare(_ helper: ContentShareHelper, error: Error?) {
        DLog("Error: \(String(describing: error))")
        self.shareHelper = nil
    }
    
}

// MARK: Share To Unlock Alerts
extension BaseViewController {
    
    func showLeftDaysAlert() {
        let daysLeftToUnlock = ShareToUnlock.shared.daysLeftToUnlock
        var message = "Great! \(daysLeftToUnlock) days left to unlock the list of all Proverbs for free."
        if daysLeftToUnlock == 1 {
            message = "Great! \(daysLeftToUnlock) day left to unlock the list of all Proverbs for free."
        }
        
        after(0.5) { UIAlertController.show(message: message) }
    }
    
    func showCongratulationAlert() {
        after(0.5) { UIAlertController.show(message: "Congratulations! List of all Proverbs has been unlocked!") }
    }
    
}

