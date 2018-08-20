//
//  ProverbViewController.swift
//  Proverbs
//
//  Created by Eugene Zozulya on 4/17/18.
//  Copyright © 2018 Eugene Zozulya. All rights reserved.
//

import UIKit

class ProverbViewController: BannerViewController {

    // MARK: - IBOutlets
    
    @IBOutlet private weak var proverbLabel:        UILabel!
    @IBOutlet private weak var meaningLabel:        UILabel!
    
    @IBOutlet private weak var shareButton:         ObliqueButton!
    @IBOutlet private weak var saveDeleteButton:    ObliqueButton!
    
    // MARK: - Properties
    
    var proverb:                            Proverb!
    var backButtonColor:                    UIColor?
    
    private let favoritesManager            = FavoriteProverbsManager.shared
    
    // MARK: - IBActions
    
    @IBAction func shareButtonPushed(_ sender: Any) {
        let shareActionSheet = ActionSheetViewController.makeShareActionSheet(withDelegate: self, proverb: self.proverb)
        shareActionSheet?.present(onViewController: self)
    }
    
    @IBAction func saveDeleteButtonPushed(_ sender: Any) {
        self.checkAndSaveOrDeleteFavorite(proverb: proverb)
    }
    
    // MARK: - NavigationBarDelegate
    
    override func leftbuttonPushed(_ navigationBar: NavigationBar) {
        super.leftbuttonPushed(navigationBar)
        self.navigationController?.popViewController(animated: true)
    }
        
    // MARK: - Private Methods

    override func setupViews() {
        super.setupViews()
        
        self.internalNavigationBar?.leftButtonColor = self.backButtonColor
        
        self.populateScreen()
        self.setupButtons()
        self.checkAndUpdateAddToFavoritesButton()
    }
    
    private func populateScreen() {
        self.proverbLabel.text = self.proverb.text
        self.meaningLabel.text = self.proverb.meaning
    }
    
    private func setupButtons() {
        let shareConstructor = ObliqueConstructor(withSide: .both(leftDirection: .right, rightDirection: .left))
        self.shareButton.constructor = shareConstructor
        self.shareButton.backgroundColor = GlobalUI.Colors.blue
        
        let saveConstructor = ObliqueConstructor(withSide: .both(leftDirection: .left, rightDirection: .right))
        self.saveDeleteButton.constructor = saveConstructor
        self.saveDeleteButton.backgroundColor = GlobalUI.Colors.red
    }

    private func checkAndUpdateAddToFavoritesButton() {
        if self.proverb is FavoriteProverb {
            self.updateSaveButton(toFavorite: true)
        } else {
            self.favoritesManager.isFavorite(proverb: proverb, completion: { favorite in
                self.updateSaveButton(toFavorite: favorite)
            })
        }
    }
    
    private func updateSaveButton(toFavorite: Bool) {
        let buttonImage = toFavorite ? UIImage(named: "FavoriteButtonIcon")! : UIImage(named: "UnfavoriteButtonIcon")!
        self.saveDeleteButton.setImage(buttonImage, for: .normal)
    }

    private func checkAndSaveOrDeleteFavorite(proverb: Proverb) {
        let progressClosure = { (inProgress: Bool) in
            self.saveDeleteButton.inProgress(show: inProgress, animated: true)
        }
        
        progressClosure(true)
        self.favoritesManager.isFavorite(proverb: proverb) { result in
            if result {
                self.favoritesManager.delete(proverb: proverb, completion: { (error) in
                    progressClosure(false)
                    if let error = error {
                        DLog("Failed to delete from favorites. \(error)")
                        self.checkFavoriteManagerError(error)
                    }
                })
            } else {
                self.favoritesManager.save(proverb: proverb, completion: { (retProverb, error) in
                    progressClosure(false)
                    if let error = error {
                        DLog("Failed to delete from favorites. \(error)")
                        self.checkFavoriteManagerError(error)
                    } else if retProverb == nil {
                        DLog("Failed to save to favorites.")
                        UIAlertController.showAlert(withTitle: "Error", message: "Failed to save proverb to favorites")
                    }
                })
            }
        }
    }
    
    private func checkFavoriteManagerError(_ error: Error) {
        let error = error as NSError
        switch error.code {
        case FavoriteProverbsManager.ErrorInfo.Code.Internal:
            UIAlertController.showAlert(withTitle: "Error", message: "Failed to save proverb to favorites")
        case FavoriteProverbsManager.ErrorInfo.Code.MaxLimit:
            UIAlertController.showAlert(withTitle: "Error", message: "You reached maximum limit. Unlock all features or delete some old favorite proverbs first.")
        default: break
        }
    }
    
    // MARK: Notifications
    
    override func addNotificationsObserver() {
        super.addNotificationsObserver()
        
        self.notificaionCenter.addObserver(self,
                                           selector: #selector(ProverbViewController.didSaveNewFavoriteProverbNotification(_:)),
                                           name: NSNotification.Name(rawValue: FavoriteProverbsManager.NotificationName.DidSave),
                                           object: nil)
        self.notificaionCenter.addObserver(self,
                                           selector: #selector(ProverbViewController.didDeleteFavoriteProverbNotification(_:)),
                                           name: NSNotification.Name(rawValue: FavoriteProverbsManager.NotificationName.DidDelete),
                                           object: nil)
    }
    
    @objc private func didSaveNewFavoriteProverbNotification(_ notif: Notification) {
        guard let info = notif.userInfo,
            let originIdentifier = info[FavoriteProverbsManager.NotificationKey.OriginProverbIdentifier] as? String,
            let currentIdentifier = self.proverb?.identifier else {
                return
        }
        
        if originIdentifier == currentIdentifier {
            self.updateSaveButton(toFavorite: true)
        }
    }
    
    @objc private func didDeleteFavoriteProverbNotification(_ notif: Notification) {
        if self.proverb is FavoriteProverb {
            self.navigationController?.popViewController(animated: true)
            return
        }
        
        guard let info = notif.userInfo,
            let originIdentifier = info[FavoriteProverbsManager.NotificationKey.OriginProverbIdentifier] as? String,
            let currentIdentifier = self.proverb?.identifier else {
                return
        }
        
        if originIdentifier == currentIdentifier {
            self.updateSaveButton(toFavorite: false)
        }
    }
    
}

extension ProverbViewController: ContentShareHelperDelegate {
    
    func contentShareHelperDidShare(_ helper: ContentShareHelper) {
        
    }
    
    func contentShareHelperDidCancelShare(_ helper: ContentShareHelper) {
        
    }
    
    func contentShareHelperDidFailToShare(_ helper: ContentShareHelper, error: Error?) {
        
    }
    
}
