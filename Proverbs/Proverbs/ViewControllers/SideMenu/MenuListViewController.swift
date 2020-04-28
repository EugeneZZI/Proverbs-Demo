//
//  MenuListViewController.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 4/17/18.
//  Copyright © 2018 Yevhenii Zozulia. All rights reserved.
//

import UIKit
import QuartzCore

class MenuItem: Equatable, Unlockable {
    
    enum ItemType: String {
        case random     = "Random"
        case allList    = "All List"
        case settings   = "Settings"
        case login      = "Sign In"
    }
    
    fileprivate class func itemsList() -> [MenuItem] {
        return [MenuItem(withType: .random), MenuItem(withType: .allList), MenuItem(withType: .settings), MenuItem(withType: .login)]
    }
    
    // ---
    
    private(set) var type: ItemType
    
    var title: String {
        return self.type.rawValue
    }
    var viewController: UIViewController? {
        return self.makeViewController(forType: self.type)
    }
    var color: UIColor {
        return self.getColor(forType: self.type)
    }
    
    var unlockType: UnlockableType {
        switch self.type {
        case .allList:  return .payOrShare
        case .login:    return .pay
        default:        return .free
        }
    }
    
    var canBePerformed: Bool {
        switch self.unlockType {
        case .pay: 	        return IAPController.shared.isPurchased
        case .payOrShare:   return IAPController.shared.isPurchased || ShareToUnlock.shared.isUnlocked
        default:            return true
        }
    }
    
    // ---
    
    init(withType type: ItemType) {
        self.type = type
    }
    
    // ---
    
    private func makeViewController(forType type: ItemType) -> UIViewController? {
        switch type {
        case .random:   return RandomProverbNavigationController.create()
        case .allList:  return AllProverbsNavigationController.create()
        case .settings: return SettingsViewController.create()
        default: return nil
        }
    }
    
    private func getColor(forType type: ItemType) -> UIColor {
        switch type {
        case .random:   return UIColor.appYellow
        case .allList:  return UIColor.appDarkGrayBlue
        case .settings: return UIColor.appBlue
        case .login:    return UIColor.appRed
        }
    }
    
    static func == (lhs: MenuItem, rhs: MenuItem) -> Bool {
        return lhs.type == rhs.type
    }
    
}

protocol MenuListViewControllerDelegate: class {
    func didSelect(button: UIButton, forItem: MenuItem, onListViewController: MenuListViewController)
}

class MenuListViewController: BaseViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet private weak var blurEffect:          UIVisualEffectView!
    
    // MARK: - Properties
    
    var menuViewController: (MenuViewController & MenuListViewControllerDelegate)?
    
    private var elementsViews = [UIView]()
    private var menuItems: [MenuItem]!
    private var originalFrames = [Int: CGRect]()
    
    private lazy var _showOnce: () = {
        self.createViews()
        self.disableAllButtons(true)
        self.startAppearanceAnimation()
    }()
    
    // MARK: - Life Cycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.menuItems = MenuItem.itemsList()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(false)
        _ = _showOnce
    }
    
    // MARK: - Public Methods
    
    func dismiss(withCompletion completion: ClosureVoid? = nil) {
        self.startDisappearanceAnimation {
            self.dismiss(animated: false, completion: {
                completion?()
            })
        }
    }
    
    func checkAndUpdateLoginButtonTitle() {
        guard let signInButton = self.getButton(forItemType: .login) else {
            return
        }
        
        if UserManager.shared.isSignedIn {
            signInButton.setTitle("Sign Out", for: .normal)
        } else {
            signInButton.setTitle("Sign In", for: .normal)
        }
    }
    
    // MARK: - Private Methods
    // MARK: Construct
    
    override func setupViews() {
        super.setupViews()
        
        self.blurEffect.alpha = 0.0
        self.addHideGesture()
    }
    
    private func createViews() {
        let navigationBarViewWidth: CGFloat = ScreenSize.width - GlobalUI.Offsets.side
        let buttonWidth: CGFloat            = ScreenSize.width / 2
        
        var safeAreaTopInset: CGFloat = 20.0
        if #available(iOS 11.0, *) {
            safeAreaTopInset = self.view.safeAreaInsets.top
        }
        var currentY: CGFloat = safeAreaTopInset + 4.0
        
        var frame = CGRect(x: 0.0, y: currentY, width: navigationBarViewWidth, height: GlobalUI.Sizes.elementHeight)
        let navigationBarView = self.createNavigationBarView(withFrame: frame, color: UIColor.appGrayBlue)
        navigationBarView.tag = 681
        self.view.addSubview(navigationBarView)
        self.elementsViews.append(navigationBarView)
        self.originalFrames[navigationBarView.tag] = frame
        frame.origin.x = -(navigationBarView.frame.size.width - GlobalUI.NavigationBar.defaultButtonSize.width)
        navigationBarView.frame = frame
        
        for (index, item) in self.menuItems.enumerated() {
            currentY += GlobalUI.Offsets.verticalSpacing + GlobalUI.Sizes.elementHeight
            frame = CGRect(x: 0.0, y: currentY, width: buttonWidth, height: GlobalUI.Sizes.elementHeight)
            let button = self.createButton(forItem: item, tag: index, frame: frame)
            self.elementsViews.append(button)
        }
        
        self.checkAndUpdateLoginButtonTitle()
    }
    
    private func createNavigationBarView(withFrame frame: CGRect, color: UIColor) -> UIView {
        let navigationBarView = ObliqueView(frame: frame)
        navigationBarView.backgroundColor = color
        let constructor = ObliqueConstructor(withSide: .right(direction: .right))
        navigationBarView.constructor = constructor
        
        if let menuImage = UIImage(named: "MenuIcon") {
            let menuImageView =  UIImageView(image: menuImage)
            let x: CGFloat = navigationBarView.frame.size.width - menuImage.size.width - 5.0
            let y: CGFloat = navigationBarView.frame.size.height / 2
            let centerPoint = CGPoint(x: x, y: y)
            menuImageView.center = centerPoint
            navigationBarView.addSubview(menuImageView)
        }
        
        return navigationBarView
    }
    
    private func createButton(forItem item: MenuItem, tag: Int, frame: CGRect) -> UIButton {
        let retButton = ObliqueButton(type: .custom)
        retButton.frame = frame
        retButton.tag = tag
        retButton.setTitle(item.title, for: .normal)
        retButton.setTitleColor(UIColor.appMainFont, for: .normal)
        retButton.backgroundColor = item.color
        retButton.addTarget(self, action: #selector(MenuListViewController.buttonPushed(_:)), for: .touchUpInside)
        let constructor = ObliqueConstructor(withSide: .right(direction: .right))
        retButton.constructor = constructor
        
        return retButton
    }
    
    private func disableAllButtons(_ disable: Bool) {
        self.elementsViews.forEach {
            $0.isUserInteractionEnabled = !disable
        }
    }
    
    private func addHideGesture() {
        let hideGesture = UITapGestureRecognizer(target: self, action: #selector(MenuListViewController.hideTapGesture(_:)))
        hideGesture.numberOfTapsRequired = 1
        self.blurEffect.addGestureRecognizer(hideGesture)
    }
    
    // MARK: Appearance
    
    private func startAppearanceAnimation(withCompletion completion: ClosureVoid? = nil) {
        self.startBlurAppearance { }
        self.startViewsAppearance {
            self.disableAllButtons(false)
            completion?()
        }
    }
    
    private func startDisappearanceAnimation(withCompletion completion: ClosureVoid? = nil) {
        self.disableAllButtons(true)
        self.startBlurDisappearance { }
        self.startViewsDisappearance {
            completion?()
        }
    }
    
    private func startBlurAppearance(completion: @escaping ClosureVoid) {
        UIView.animate(withDuration: 0.3, animations: {
            self.blurEffect.alpha = 1.0
        }, completion: { _ in
            completion()
        })
    }
    
    private func startViewsAppearance(completion: @escaping ClosureVoid) {
        self.elementsViews.forEach {
            if let _ = $0 as? UIButton {
                var frame = $0.frame
                self.originalFrames[$0.tag] = frame
                frame.origin.x = -frame.size.width
                $0.frame = frame
                self.view.addSubview($0)
            }
        }
        
        let startTimes = Array(stride(from: 0.0, to: 0.8, by: 0.1))
        UIView.animateKeyframes(withDuration: 0.5, delay: 0.0, options: .calculationModeCubic, animations: {
            self.elementsViews.forEach { view in
                let startTime = startTimes.randomElement()!
                UIView.addKeyframe(withRelativeStartTime: startTime, relativeDuration: 1.0 - startTime, animations: {
                    view.frame = self.originalFrames[view.tag] ?? CGRect.zero
                })
            }
        }) { (_) in
            self.originalFrames.removeAll()
            completion()
        }
    }
    
    private func startBlurDisappearance(completion: @escaping ClosureVoid) {
        UIView.animate(withDuration: 0.5, animations: {
            self.blurEffect.alpha = 0.0
        }, completion: { _ in
            completion()
        })
    }
    
    private func startViewsDisappearance(completion: @escaping ClosureVoid) {
        let startTimes = Array(stride(from: 0.0, to: 0.8, by: 0.1))
        UIView.animateKeyframes(withDuration: 0.5, delay: 0.0, options: .calculationModeCubic, animations: {
            self.elementsViews.forEach { view in
                var frame = view.frame
                
                if view is UIButton {
                    frame.origin.x = -frame.size.width
                } else { // navigation bar view
                    frame.origin.x = -(view.frame.size.width - GlobalUI.NavigationBar.defaultButtonSize.width)
                }
                
                let startTime = startTimes.randomElement()!
                UIView.addKeyframe(withRelativeStartTime: startTime, relativeDuration: 1.0 - startTime, animations: {
                    view.frame = frame
                })
            }
        }) { (_) in
            completion()
        }
    }
    
    // MARK: Accessing
    
    private func getButton(forItemType itemType: MenuItem.ItemType) -> UIButton? {
        guard let item = self.menuItems.filter({ $0.type == itemType }).first,
            let index = self.menuItems.firstIndex(of: item) else {
                return nil
        }
        
        guard let button = self.elementsViews.filter({ $0.tag == index }).first as? UIButton else {
            return nil
        }
        
        return button
    }
    
    // MARK: Actions
    
    @objc private func buttonPushed(_ button: UIButton) {
        var menuItem: MenuItem?
        
        if button.tag < self.menuItems.count {
            menuItem = self.menuItems[button.tag]
        }
        
        guard let item = menuItem else { return }
        self.menuViewController?.didSelect(button: button, forItem: item, onListViewController: self)
    }
    
    @objc private func hideTapGesture(_ gesture: UITapGestureRecognizer) {
        self.menuViewController?.hide()
    }
}

