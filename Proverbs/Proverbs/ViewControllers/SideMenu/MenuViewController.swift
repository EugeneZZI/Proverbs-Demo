//
//  MenuViewController.swift
//  Proverbs
//
//  Created by Eugene Zozulya on 4/17/18.
//  Copyright © 2018 Eugene Zozulya. All rights reserved.
//

import UIKit

class MenuViewController: BaseViewController, MenuListViewControllerDelegate {
    
    class var shared: MenuViewController {
        if let menu = UIApplication.shared.keyWindow?.rootViewController as? MenuViewController {
            return menu
        } else {
            return MenuViewController.create()!
        }
    }
    
    // MARK: - IBOutlets
    
    @IBOutlet private weak var container: UIView!
    
    // MARK: - Properties
    
    var isMenuVisible: Bool = false
    var currentEmbeddedViewController: UIViewController? {
        return self.childViewControllers.first
    }
    
    private var sideViewController: MenuListViewController?
    
    // MARK: - Public Methods
    
    func show() {
        if self.isMenuVisible { return }
        guard let menu = MenuListViewController.create() else { return }
        menu.menuViewController = self
        self.sideViewController = menu
        
        menu.modalPresentationStyle = .overCurrentContext
        self.present(menu, animated: false, completion: {
            self.isMenuVisible = true
        })
    }
    
    func hide() {
        if !self.isMenuVisible { return }
        guard let menu = self.sideViewController else { return }
        menu.dismiss {
            self.isMenuVisible = false
            self.sideViewController = nil
        }
    }
    
    func embed(viewController: UIViewController) {
        guard let oldViewControlelr = self.currentEmbeddedViewController else {
            return
        }
        
        oldViewControlelr.willMove(toParentViewController: nil)
        oldViewControlelr.view.removeFromSuperview()
        oldViewControlelr.removeFromParentViewController()
        
        self.addChildViewController(viewController)
        viewController.view.frame = oldViewControlelr.view.frame
        self.container.addSubview(viewController.view)
        viewController.didMove(toParentViewController: self)
    }
    
    // MARK: - MenuListViewControllerDelegate
    
    func didSelect(button: UIButton, forItem item: MenuItem, onListViewController: MenuListViewController) {
        if !item.payedAndCanBePerformed {
            self.showPurchaseAlert()
            return
        }
        
        if item.type == .login {
            self.checkAndSignInUser()
            return
        }
        
        guard let newViewController = item.viewController else {
            return
        }
        
        if isSame(viewController: newViewController) {
            self.hide()
            return
        }
        
        self.embed(viewController: newViewController)
        
        self.sideViewController?.dismiss(withCompletion: {
            self.isMenuVisible = false
            self.sideViewController = nil
        })
    }
    
    // MARK: - Private Methods
    
    private func isSame(viewController: UIViewController) -> Bool {
        guard let currentViewController = currentEmbeddedViewController else {
            return false
        }
        
        let currentType = type(of: currentViewController)
        let newType = type(of: viewController)
        
        return newType == currentType
    }
    
    private func checkAndSignInUser() {
        if UserManager.shared.isSignedIn {
            self.signOut()
        } else {
            self.signInUser()
        }
    }
    
    private func signInUser() {
        guard let menuViewController = self.sideViewController else {
            return
        }
        
        let signInCompletion = { (result: Bool) in
            menuViewController.checkAndUpdateLoginButtonTitle()
        }
        
        let actionSheet = ActionSheetViewController.makeWithTitle("Sign In with")
        let facebookAction = ActionSheetItem(type: .select, title: "Facebook", color: GlobalUI.Colors.facbookButton) { _ in
            UserManager.shared.signIn(onViewController: menuViewController, withOption: .facebook, completion: signInCompletion)
        }
        let twitterAction = ActionSheetItem(type: .select, title: "Twitter", color: GlobalUI.Colors.twitterButton) { _ in
            UserManager.shared.signIn(onViewController: menuViewController, withOption: .twitter, completion: signInCompletion)
        }
        let googleAction = ActionSheetItem(type: .select, title: "Google", color: GlobalUI.Colors.googleButton) { _ in
            UserManager.shared.signIn(onViewController: menuViewController, withOption: .google, completion: signInCompletion)
        }
        let cancelAction = ActionSheetItem(type: .destructive, title: "Cancel")
        
        actionSheet?.addItem(facebookAction)
        actionSheet?.addItem(twitterAction)
        actionSheet?.addItem(googleAction)
        actionSheet?.addItem(cancelAction)
        
        actionSheet?.present(onViewController: menuViewController)
    }
    
    private func showPurchaseAlert() {
        guard let listViewController = self.sideViewController else {
            return
        }
        
        UIAlertController.showAlert(listViewController,
                                    message: "You can purchase Full Access to enable all features and remove Ads.",
                                    confirmButtonTitle: "Purchase",
                                    cancelButtonTitle: "Cancel",
                                    confirmBlock: { _ in self.makePurchase() },
                                    cancelBlock: nil)
    }
    
    private func makePurchase() {
        guard let listViewController = self.sideViewController else {
            return
        }
        
        listViewController.activityIndicator(show: true, blockView: true)
        IAPController.shared.purchase { _ in
            listViewController.activityIndicator(show: false)
        }
    }
    
    private func signOut() {
        UserManager.shared.signOut(withCompletion: { _ in
            self.sideViewController?.checkAndUpdateLoginButtonTitle()
        })
    }
}

