//
//  NavigationBar.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 4/17/18.
//  Copyright © 2018 Yevhenii Zozulia. All rights reserved.
//

import UIKit

protocol NavigationBarDelegate: class {
    func leftbuttonPushed(_ navigationBar: NavigationBar)
    func rightbuttonPushed(_ navigationBar: NavigationBar)
}

class NavigationBar: UIView {
    
    private enum ViewControllerType: String {
        case main       = "RandomProverbViewController"
        case favorites  = "FavoritesProverbsViewController"
        case all        = "AllProverbsViewController"
        case settings   = "SettingsViewController"
        case policy     = "PrivacyPolicyViewController"
        case details    = "ProverbViewController"
        
        init?(viewControllerType: UIViewController.Type) {
            let identifier = String(describing: viewControllerType)
            if let type = ViewControllerType(rawValue: identifier) {
                self = type
            } else {
                return nil
            }
        }
    }
    
    // MARK: - Properties
    
    weak var delegate: NavigationBarDelegate?
    
    var leftButtonColor:            UIColor?
    var rightButtonColor:           UIColor?
    override var backgroundColor: UIColor? {
        set { super.backgroundColor = .clear }
        get { return .clear }
    }
    weak var viewController: (UIViewController & NavigationBarDelegate)? {
        didSet {
            self.delegate = viewController
            self.updateType()
        }
    }
    
    private(set) var leftButton:     UIButton?
    private(set) var rightButton:    UIButton?
    private(set) var title:          UIView?
    
    private var viewcControllerType: ViewControllerType? {
        didSet { self.updateUI() }
    }
    
    // MARK: - Life Cycle Methods
    
    convenience init(forViewController vc: BaseViewController) {
        var y =  CGFloat(20.0)
        if #available(iOS 11.0, *) {
            let window = UIApplication.shared.keyWindow
            y = window?.safeAreaInsets.top ?? y
        }
        
        self.init(frame: CGRect(x: 0.0, y: y, width: ScreenSize.width, height: 44.0))
        self.viewController = vc
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.updateFrames()
    }
    
    // MARK: - Public Methods
    
    func updateImageForFavoritesProverbsSortButton(_ image: UIImage) {
        self.rightButton?.setImage(image, for: .normal)
    }
    
    // MARK: - Private Methods
    // MARK: Update for Controllers
    
    @objc private func updateForRandomProverbViewController() {
        self.createAndAddMenuButton()
        
        let favoritesButton = self.makeRightButton()
        favoritesButton.backgroundColor = self.rightButtonColor ?? UIColor.appBlue
        favoritesButton.setImage(UIImage(named: "FavoritesIcon")!, for: .normal)
        var inset = favoritesButton.imageEdgeInsets
        inset.left += GlobalUI.NavigationBar.menuIconSideOffset
        favoritesButton.imageEdgeInsets = inset
        
        self.rightButton = favoritesButton
        self.addSubview(favoritesButton)
    }
    
    @objc private func updateForFavoritesProverbsViewController() {
        let titleView = self.makeTitleView(withText: "Favorites")
        self.title = titleView
        self.addSubview(titleView)
        
        self.createAndAddBackButton()
        
        let sortButton = self.makeRightButton()
        sortButton.backgroundColor = self.rightButtonColor ?? UIColor.appDarkGrayBlue
        sortButton.setImage(UIImage(named: "SortAlphabetIcon")!, for: .normal)
        var inset = sortButton.imageEdgeInsets
        inset.left += GlobalUI.NavigationBar.menuIconSideOffset
        sortButton.imageEdgeInsets = inset

        self.rightButton = sortButton
        self.addSubview(sortButton)
    }
    
    @objc private func updateForAllProverbsViewController() {
        self.createAndAddMenuButton()
    }
    
    @objc private func updateForSettingsViewController() {
        self.createAndAddMenuButton()
    }
    
    @objc private func updateForPrivacyPolicyViewController() {
        let titleView = self.makeTitleView(withText: "Privacy Policy", color: UIColor.appGrayBlue)
        self.title = titleView
        self.addSubview(titleView)
        self.createAndAddBackButton()
    }
    
    @objc private func updateForProverbViewController() {
        let backButton = self.makeLeftButton()
        backButton.backgroundColor = self.leftButtonColor ?? UIColor.appGrayBlue
        backButton.setImage(UIImage(named: "BackIcon")!, for: .normal)
        var inset = backButton.imageEdgeInsets
        inset.left -= GlobalUI.NavigationBar.backIconSideOffset
        backButton.imageEdgeInsets = inset
        
        self.leftButton = backButton
        self.addSubview(backButton)
    }
    
    // MARK: Construct UI
    
    private func updateType() {
        if let vc = self.viewController {
            self.viewcControllerType = ViewControllerType(viewControllerType: type(of: vc))
        } else {
            self.viewcControllerType = nil
        }
    }
    
    private func updateUI() {
        guard let type = self.viewcControllerType else {
            self.cleanUI()
            return
        }
        
        let selectorString = "updateFor" + type.rawValue
        let selector = Selector(selectorString)
        perform(selector)
    }
    
    private func cleanUI() {
        self.leftButton?.removeFromSuperview()
        self.rightButton?.removeFromSuperview()
        self.title?.removeFromSuperview()
    }
    
    private func updateFrames() {
        if self.leftButton is ObliqueButton {
            self.leftButton?.frame = self.makeLeftButtonFrame()
        }
        if self.rightButton is ObliqueButton {
            self.rightButton?.frame = self.makeRightButtonFrame()
        }
    }

    private func createAndAddMenuButton() {
        let menuButton = self.makeLeftButton()
        menuButton.backgroundColor = self.leftButtonColor ?? UIColor.appGrayBlue
        menuButton.setImage(UIImage(named: "MenuIcon")!, for: .normal)
        var inset = menuButton.imageEdgeInsets
        inset.left -= GlobalUI.NavigationBar.menuIconSideOffset
        menuButton.imageEdgeInsets = inset
        
        self.leftButton = menuButton
        self.addSubview(menuButton)
    }
    
    private func createAndAddBackButton() {
        let backButton = UIButton(type: .custom)
        backButton.backgroundColor = .clear
        backButton.addTarget(self, action: #selector(NavigationBar.leftButtonPushed(_:)), for: .touchUpInside)
        backButton.setImage(UIImage(named: "BackIcon")!, for: .normal)
        var frame = self.makeLeftButtonFrame()
        frame.size.width = frame.size.height
        backButton.frame = frame
        
        self.leftButton = backButton
        self.addSubview(backButton)
    }
    
    private func makeLeftButton() -> ObliqueButton {
        let leftButton = ObliqueButton(type: .custom)
        leftButton.frame = self.makeLeftButtonFrame()
        let constructor = ObliqueConstructor(withSide: .right(direction: .right))
        leftButton.constructor = constructor
        leftButton.addTarget(self, action: #selector(NavigationBar.leftButtonPushed(_:)), for: .touchUpInside)
        
        return leftButton
    }
    
    private func makeRightButton() -> ObliqueButton {
        let rightButton = ObliqueButton(type: .custom)
        rightButton.frame = self.makeRightButtonFrame()
        let constructor = ObliqueConstructor(withSide: .left(direction: .right))
        rightButton.constructor = constructor
        rightButton.addTarget(self, action: #selector(NavigationBar.rightButtonPushed(_:)), for: .touchUpInside)
        
        return rightButton
    }
    
    private func makeTitleView(withText text: String, color: UIColor = UIColor.appBlue) -> UIView {
        var frame = self.makeLeftButtonFrame()
        frame.size.width = ScreenSize.width - self.makeRightButtonFrame().width - GlobalUI.Offsets.buttonsSide
        let view = ObliqueView(frame: frame)
        let constructor = ObliqueConstructor(withSide: .right(direction: .right))
        view.constructor = constructor
        view.backgroundColor = color
        
        let title = UILabel()
        title.font = UIFont.systemFont(ofSize: GlobalUI.Fonts.mainSize, weight: .medium)
        title.textColor = UIColor.appMainFont
        title.text = text
        title.sizeToFit()
        frame = title.frame
        frame.origin.x = (ScreenSize.width - frame.width) / 2
        frame.origin.y = (GlobalUI.NavigationBar.defaultButtonSize.height - frame.height) / 2
        title.frame = frame
        view.addSubview(title)
        
        return view
    }
    
    private func makeLeftButtonFrame() -> CGRect {
        let frame = CGRect(x: 0.0,
                           y: self.frame.size.height - GlobalUI.NavigationBar.defaultButtonSize.height,
                           width: GlobalUI.NavigationBar.defaultButtonSize.width,
                           height: GlobalUI.NavigationBar.defaultButtonSize.height)
        return frame
    }
    
    private func makeRightButtonFrame() -> CGRect {
        let frame = CGRect(x: self.frame.size.width - GlobalUI.NavigationBar.defaultButtonSize.width,
                           y: self.frame.size.height - GlobalUI.NavigationBar.defaultButtonSize.height,
                           width: GlobalUI.NavigationBar.defaultButtonSize.width,
                           height: GlobalUI.NavigationBar.defaultButtonSize.height)
        return frame
    }
    
    // MARK: Actions
    
    @objc private func leftButtonPushed(_ buton: UIButton) {
        self.delegate?.leftbuttonPushed(self)
    }

    @objc private func rightButtonPushed(_ buton: UIButton) {
        self.delegate?.rightbuttonPushed(self)
    }
    
}
