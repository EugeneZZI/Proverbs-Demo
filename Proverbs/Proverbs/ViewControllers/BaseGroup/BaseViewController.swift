//
//  BaseViewController.swift
//  Proverbs
//
//  Created by Eugene Zozulya on 4/11/18.
//  Copyright © 2018 Eugene Zozulya. All rights reserved.
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
    
    let notificaionCenter   = NotificationCenter.default
    let reachabilityManager = ReachabilityManager.shared
    var isKeyboardVisible   = false
    
    var activityIndicator:  NVActivityIndicatorView?
    
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
        self.notificaionCenter.addObserver(self, selector: #selector(BaseViewController.keyboardWillShow(_:)),    name: Notification.Name.UIKeyboardWillShow, object: nil)
        self.notificaionCenter.addObserver(self, selector: #selector(BaseViewController.keyboardDidShow(_:)),     name: Notification.Name.UIKeyboardDidShow, object: nil)
        self.notificaionCenter.addObserver(self, selector: #selector(BaseViewController.keyboardWillHide(_:)),    name: Notification.Name.UIKeyboardWillHide, object: nil)
        self.notificaionCenter.addObserver(self, selector: #selector(BaseViewController.keyboardDidHide(_:)),     name: Notification.Name.UIKeyboardDidHide, object: nil)
    }
    
    func removeKeyboardNotificationsObserver() {
        self.notificaionCenter.removeObserver(self, name: Notification.Name.UIKeyboardWillShow, object: nil)
        self.notificaionCenter.removeObserver(self, name: Notification.Name.UIKeyboardDidShow, object: nil)
        self.notificaionCenter.removeObserver(self, name: Notification.Name.UIKeyboardWillHide, object: nil)
        self.notificaionCenter.removeObserver(self, name: Notification.Name.UIKeyboardDidHide, object: nil)
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