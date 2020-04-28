//
//  RandomProverbViewController.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 4/11/18.
//  Copyright © 2018 Yevhenii Zozulia. All rights reserved.
//

import UIKit
import GhostTypewriter

class RandomProverbViewController: BannerViewController {

    // MARK: - IBOutlets
    
    @IBOutlet private weak var proverbLabel:    TypewriterLabel!
    @IBOutlet private weak var meaningLabel:    TypewriterLabel!
    
    @IBOutlet private weak var shareButton:     ObliqueButton!
    @IBOutlet private weak var saveButton:      ObliqueButton!
    @IBOutlet private weak var nextButton:      ObliqueButton!
    
    // MARK: - Properties
    
    private let favoritesManager            = FavoriteProverbsManager.shared
    private var currentProverb:             Proverb?
    
    private var disableViews: [UIView] {
        return [self.shareButton, self.saveButton, self.nextButton]
    }
    private var isProverbInProgress         = false {
        didSet {
            self.disableViews.forEach { $0.isUserInteractionEnabled = !isProverbInProgress }
        }
    }
    
    // MARK: - Life Cycle Methods
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.checkAndUpdateAddToFavoritesButton()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initialHiddingProverb()
        self.showNextProverb()
    }
    
    // MARK: - IBActions
    
    @IBAction func shareButtonPushed(_ sender: Any) {
        guard let proverb = self.currentProverb else { return }
        let shareActionSheet = self.makeShareActionSheet(withDelegate: self, proverb: proverb)
        shareActionSheet?.present(onViewController: self)
    }
    
    @IBAction func saveButtonPushed(_ sender: Any) {
        guard let proverb = self.currentProverb else { return }
        self.checkAndSaveOrDeleteFavorite(proverb: proverb)
    }
    
    @IBAction func nextButtonPushed(_ sender: Any) {
        self.showNextProverb()
    }
    
    // MARK: - NavigationBarDelegate
    
    override func leftbuttonPushed(_ navigationBar: NavigationBar) {
        super.leftbuttonPushed(navigationBar)
        
        MenuViewController.shared.show()
    }
    
    override func rightbuttonPushed(_ navigationBar: NavigationBar) {
        super.rightbuttonPushed(navigationBar)
        
        if let favoritesViewController = FavoritesProverbsViewController.create() {
            self.navigationController?.pushViewController(favoritesViewController, animated: true)
        }
    }

    // MARK: - Private Methods
    
    override func setupViews() {
        super.setupViews()
        
        self.setupProverbLabels()
        self.setupButtons()
    }
    
    private func setupProverbLabels() {
        self.proverbLabel.typingTimeInterval = 0.01
        self.meaningLabel.typingTimeInterval = 0.01
    }
    
    private func setupButtons() {
        let shareConstructor = ObliqueConstructor(withSide: .both(leftDirection: .right, rightDirection: .right))
        self.shareButton.constructor = shareConstructor
        self.shareButton.backgroundColor = UIColor.appRed
        
        let saveConstructor = ObliqueConstructor(withSide: .both(leftDirection: .right, rightDirection: .right))
        self.saveButton.constructor = saveConstructor
        self.saveButton.backgroundColor = UIColor.appBlue
        
        let nextconstructor = ObliqueConstructor(withSide: .both(leftDirection: .right, rightDirection: .right))
        self.nextButton.constructor = nextconstructor
        self.nextButton.backgroundColor = UIColor.appYellow
    }
    
    private func checkAndUpdateAddToFavoritesButton() {
        guard let proverb = self.currentProverb else {
            self.updateSaveButton(toFavorite: false)
            return
        }
        
        self.favoritesManager.isFavorite(proverb: proverb, completion: { favorite in
            self.updateSaveButton(toFavorite: favorite)
        })
    }
    
    private func updateSaveButton(toFavorite: Bool) {
        let buttonImage = toFavorite ? UIImage(named: "FavoriteButtonIcon")! : UIImage(named: "UnfavoriteButtonIcon")!
        self.saveButton.setImage(buttonImage, for: .normal)
    }
    
    private func initialHiddingProverb() {
        self.proverbLabel.text = nil
        self.meaningLabel.text = nil
    }
    
    private func showNextProverb() {
        self.currentProverb = ProverbsManager.shared.getNextRandom()
        self.checkAndUpdateAddToFavoritesButton()
        
        self.isProverbInProgress = true
        var blocksCounter = 2
        let checkCompletion = {
            blocksCounter -= 1
            if blocksCounter == 0 {
                self.isProverbInProgress = false
            }
        }
        
        self.proverbLabel.text = self.currentProverb?.text
        self.proverbLabel.restartTypewritingAnimation(completion: checkCompletion)
        
        self.meaningLabel.text = self.currentProverb?.meaning
        self.meaningLabel.restartTypewritingAnimation(completion: checkCompletion)
    }
    
    private func checkAndSaveOrDeleteFavorite(proverb: Proverb) {
        let progressClosure = { (inProgress: Bool) in
            self.saveButton.inProgress(show: inProgress, animated: true) {
                self.isProverbInProgress = inProgress
            }
        }
        
        progressClosure(true)
        self.favoritesManager.isFavorite(proverb: proverb) { result in
            if result {
                self.favoritesManager.delete(proverb: proverb, completion: { (error) in
                    progressClosure(false)
                    if let error = error {
                        DLog("Failed to delete from favorites. \(error)")
                        self.checkFavoriteManagerError(error)
                        self.updateSaveButton(toFavorite: true)
                    }
                    self.checkAndUpdateAddToFavoritesButton()
                })
            } else {
                self.favoritesManager.save(proverb: proverb, completion: { result in
                    progressClosure(false)
                    switch result {
                    case .failure(let error):
                        DLog("Failed to save proverb to favorites \(error)")
                        self.checkFavoriteManagerError(error)
                        self.updateSaveButton(toFavorite: false)
                    default: break
                    }
                    self.checkAndUpdateAddToFavoritesButton()
                })
            }
        }
    }
    
    private func checkFavoriteManagerError(_ error: Error) {
        guard let managerError = error as? FavoriteProverbsManagerError else {
            UIAlertController.show(withTitle: "Error", message: "Failed to save proverb to favorites")
            return
        }
        
        switch managerError {
        case .maxLimit(_):
            self.showPurchaseAlert()
        default:
            UIAlertController.show(withTitle: "Error", message: "Failed to save proverb to favorites")
        }
    }
    
    private func showPurchaseAlert() {
        let alert = UIAlertController(title: title, message: "Maximum \(FavoriteProverbsManager.freeMaxCount) favorite proverbs allowed in free version. You can purchase Full Access to unlock all features and remove Ads. Or remove old from the list to add new one.", preferredStyle: .alert)
        
        let purchaseAction = UIAlertAction(title: "Purchase", style: .default, handler: { (action) in
            self.makePurchase()
        })
        
        let restoreAction = UIAlertAction(title: "Restore Purchases", style: .default, handler: { (action) in
            self.restorePurchases()
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
        })
        
        alert.addAction(purchaseAction)
        alert.addAction(restoreAction)
        alert.addAction(cancelAction)
        alert.preferredAction = purchaseAction
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func makePurchase() {
        self.activityIndicator(show: true, blockView: true)
        IAPController.shared.purchase { _ in
            self.activityIndicator(show: false)
        }
    }
    
    private func restorePurchases() {
        self.activityIndicator(show: true, blockView: true)
        IAPController.shared.restore { _ in
            self.activityIndicator(show: false)
        }
    }
    
    // MARK: Notifications
    
    override func addNotificationsObserver() {
        super.addNotificationsObserver()
        
        self.notificaionCenter.addObserver(self,
                                           selector: #selector(RandomProverbViewController.didSaveNewFavoriteProverbNotification(_:)),
                                           name: NSNotification.Name(rawValue: FavoriteProverbsManager.NotificationName.DidSave),
                                           object: nil)
        self.notificaionCenter.addObserver(self,
                                           selector: #selector(RandomProverbViewController.didDeleteFavoriteProverbNotification(_:)),
                                           name: NSNotification.Name(rawValue: FavoriteProverbsManager.NotificationName.DidDelete),
                                           object: nil)
    }
    
    @objc private func didSaveNewFavoriteProverbNotification(_ notif: Notification) {
        guard let info = notif.userInfo,
            let originIdentifier = info[FavoriteProverbsManager.NotificationKey.OriginProverbIdentifier] as? String,
            let currentIdentifier = self.currentProverb?.identifier else {
            return
        }
        
        if originIdentifier == currentIdentifier {
            self.updateSaveButton(toFavorite: true)
        }
    }
    
    @objc private func didDeleteFavoriteProverbNotification(_ notif: Notification) {
        guard let info = notif.userInfo,
            let originIdentifier = info[FavoriteProverbsManager.NotificationKey.OriginProverbIdentifier] as? String,
            let currentIdentifier = self.currentProverb?.identifier else {
            return
        }

        if originIdentifier == currentIdentifier {
            self.updateSaveButton(toFavorite: false)
        }
    }
    
}
