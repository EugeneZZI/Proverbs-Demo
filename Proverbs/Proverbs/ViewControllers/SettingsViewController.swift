//
//  SettingsViewController.swift
//  Proverbs
//
//  Created by Eugene Zozulya on 4/11/18.
//  Copyright © 2018 Eugene Zozulya. All rights reserved.
//

import UIKit

class SettingsViewController: BaseViewController {

    // MARK: - IBOutlets
    
    @IBOutlet private weak var reminderLabel:           UILabel!
    @IBOutlet private weak var reminderTimeLabel:       UILabel!
    @IBOutlet private weak var reminderTimeValueLabel:  UILabel!
    @IBOutlet private weak var versionLabel:            UILabel!
    @IBOutlet private weak var reminderSwitcher:        UISwitch!
    
    @IBOutlet private weak var purchaseButton:          ObliqueButton!
    @IBOutlet private weak var restoreButton:           ObliqueButton!
    
    @IBOutlet private weak var datePickerHolderView:    UIView!
    @IBOutlet private weak var datePicker:              UIDatePicker!
    @IBOutlet private weak var datePickerHolderViewBottomConstraint: NSLayoutConstraint!
    
    // MARK: - Properties
    
    private let purchaseController  = IAPController.shared
    private let remindersManager    = RemindersManager.shared
    
    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        return dateFormatter
    }()
    private lazy var hideDatePickerGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(SettingsViewController.hideDatePickerGesture(_:)))
        return gesture
    }()
    
    // MARK: - Life Cycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.showDatePicker(false, animated: false)
    }
    
    // MARK: - IBActions
    
    @IBAction func purchaseButtonPushed(_ sender: Any) {
        self.purchaseController.purchase()
    }
    
    @IBAction func restoreButtonPushed(_ sender: Any) {
        self.purchaseController.restore()
    }
    
    @IBAction func reminderSwitcherChanged(_ sender: Any) {
        if self.reminderSwitcher.isOn {
            self.remindersManager.checkNotificationsSettings { (settings) in
                if settings == .denied {
                    self.showDisabledNotificationsAlert()
                    self.reminderSwitcher.isOn = false
                    return
                }
            }
        }
        
        self.remindersManager.enabled = self.reminderSwitcher.isOn
    }
    
    @IBAction func datePickerChangedValue(_ sender: AnyObject) {
        let newTime = self.datePicker.date
        self.remindersManager.reminderTime = newTime
        self.updateRemindersDate()
    }
    
    // MARK: - NavigationBarDelegate
    
    override func leftbuttonPushed(_ navigationBar: NavigationBar) {
        super.leftbuttonPushed(navigationBar)
        MenuViewController.shared.show()
    }
    
    // MARK: - Private Methods
    // MARK: UI
    
    override func setupViews() {
        super.setupViews()
        self.setupButtons()
        self.checkPurchasesAndUpdateUI()
        self.updateRemindersDate()
        self.updateVersionLabel()
        self.setupDatePickerGestures()
        
        self.remindersManager.checkNotificationsSettings { (settings) in
            if settings == .notDetermined {
                self.remindersManager.registerNotifications()
            } else {
                self.updateRemindersSwitcher()
            }
        }
    }
    
    private func setupButtons() {
        let purchaseConstructor = ObliqueConstructor(withSide: .both(leftDirection: .right, rightDirection: .left))
        self.purchaseButton.constructor = purchaseConstructor
        self.purchaseButton.backgroundColor = GlobalUI.Colors.red
        
        let restoreConstructor = ObliqueConstructor(withSide: .both(leftDirection: .left, rightDirection: .right))
        self.restoreButton.constructor = restoreConstructor
        self.restoreButton.backgroundColor = GlobalUI.Colors.grayCancel
    }
    
    private func setupDatePickerGestures() {
        self.reminderTimeLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SettingsViewController.reminderTimeLabelDidTap(_:))))
        self.reminderTimeValueLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SettingsViewController.reminderTimeLabelDidTap(_:))))
    }
    
    private func checkPurchasesAndUpdateUI() {
        if self.purchaseController.isPurchased {
            self.purchaseButton.isHidden    = true
            self.restoreButton.isHidden     = true
        }
    }
    
    private func updateRemindersSwitcher() {
        self.reminderSwitcher.isOn = self.remindersManager.enabled
    }
    
    private func updateRemindersDate() {
        self.reminderTimeValueLabel.text = self.dateFormatter.string(from: self.remindersManager.reminderTime)
    }
    
    private func updateVersionLabel() {
        self.versionLabel.text = "Version: \(App.shortVersion)"
    }
    
    private func showDisabledNotificationsAlert() {
        UIAlertController.showAlert(self,
                                    message: "Enable notification in iOS settings fist.",
                                    confirmButtonTitle: "Settings",
                                    cancelButtonTitle: "Cancel",
                                    confirmBlock: { _ in
                                        UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!)
        },
                                    cancelBlock: nil)
    }
    
    // MARK: Date Picker
    
    @objc private func reminderTimeLabelDidTap(_ gesture: UITapGestureRecognizer) {
        if self.isDatePickerVisible() {
            self.showDatePicker(false, animated: true)
        } else {
            self.showDatePicker(true, animated: true)
        }
    }
    
    private func showDatePicker(_ show: Bool, animated: Bool, completion: ClosureVoid? = nil) {
        let newConstant = show ? 0.0 : self.datePickerHolderView.frame.height
        let options = show ? UIViewAnimationOptions.curveEaseOut : UIViewAnimationOptions.curveEaseIn
        
        self.datePickerHolderViewBottomConstraint.constant = newConstant
        
        if show {
            self.datePicker.setDate(self.remindersManager.reminderTime, animated: false)
            self.internalNavigationBar?.isUserInteractionEnabled = false
            self.reminderSwitcher.isUserInteractionEnabled = false
            self.view.addGestureRecognizer(self.hideDatePickerGesture)
        } else {
            self.internalNavigationBar?.isUserInteractionEnabled = true
            self.reminderSwitcher.isUserInteractionEnabled = true
            self.view.removeGestureRecognizer(self.hideDatePickerGesture)
        }
        
        if animated {
            self.view.isUserInteractionEnabled = false
            UIView.animate(withDuration: 0.25, delay: 0.0,
                           options: options,
                           animations: { () -> Void in
                            self.view.layoutIfNeeded()
            }) { (flag) -> Void in
                self.view.isUserInteractionEnabled = true
                
                if show == false {
                    let newTime = self.datePicker.date
                    self.remindersManager.reminderTime = newTime
                    if !self.remindersManager.enabled {
                        self.showDisabledNotificationsAlert()
                    }
                }
                
                completion?()
            }
        } else {
            self.view.layoutIfNeeded()
            completion?()
        }
    }
    
    @objc private func hideDatePickerGesture(_ sender: UITapGestureRecognizer) {
        self.showDatePicker(false, animated: true, completion: nil)
    }
    
    private func isDatePickerVisible() -> Bool {
        return self.datePickerHolderViewBottomConstraint.constant == 0
    }
    
    // MARK: Notifications Methods
    
    override func addNotificationsObserver() {
        super.addNotificationsObserver()
        
        self.notificaionCenter.addObserver(self,
                                           selector: #selector(SettingsViewController.didUpdatePurchases(_:)),
                                           name: NSNotification.Name(rawValue: IAPController.NotificationName.DidPurchase),
                                           object: nil)
        self.notificaionCenter.addObserver(self,
                                           selector: #selector(SettingsViewController.didUpdateRemindersSettings(_:)),
                                           name: NSNotification.Name(rawValue: RemindersManager.NotificationName.DidUpdateNotifications),
                                           object: nil)

    }

    @objc private func didUpdatePurchases(_ notification: NSNotification) {
        self.checkPurchasesAndUpdateUI()
    }
    
    @objc private func didUpdateRemindersSettings(_ notification: NSNotification) {
        self.updateRemindersSwitcher()
    }

}
