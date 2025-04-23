//
//  ActionSheetViewController.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 4/13/18.
//  Copyright © 2018 Yevhenii Zozulia. All rights reserved.
//

import UIKit

class ActionSheetItem: Equatable {

    typealias ActionClosure = (ActionSheetItem) -> Void
    
    enum Element {
        case select
        case destructive
    }
    
    private(set) var type:      Element
    private(set) var title:     String
    private(set) var color:     UIColor?
    private(set) var action:    ActionClosure?
    
    init(type: Element, title: String, color: UIColor? = nil, action: ActionClosure? = nil) {
        self.type   = type
        self.title  = title
        self.action = action
        if type == .select {
            self.color = color
        }
    }
    
    static func == (lhs: ActionSheetItem, rhs: ActionSheetItem) -> Bool {
        return
            lhs.type == rhs.type &&
            lhs.title == rhs.title
    }
    
}

class ActionSheetViewController: BaseViewController {
    
    private let TitleViewTag = 823
    
    private struct Fonts {
        static let title        = UIFont.systemFont(ofSize: GlobalUI.Fonts.mainSize, weight: .bold)
        static let select       = UIFont.systemFont(ofSize: GlobalUI.Fonts.mainSize, weight: .semibold)
        static let destructive  = UIFont.systemFont(ofSize: GlobalUI.Fonts.mainSize, weight: .bold)
    }
    
    // MARK: - IBOutlets
    
    @IBOutlet private weak var blurEffect:          UIVisualEffectView!
    
    // MARK: - Properties
    
    private var actionItems     = [ActionSheetItem]()
    private var elementsViews   = [UIView]()
    private var sheetTitle:     String?
    
    // MARK: - Life Cycle Methods
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(false)
        
        self.sortItems()
        self.createViews()
        self.disableAllButtons(true)
        self.startAppearanceAnimation()
    }
    
    // MARK: - Public Methods
    
    class func make(withTitle title: String? = nil) -> ActionSheetViewController? {
        let retActionSheet = ActionSheetViewController.create()
        retActionSheet?.sheetTitle = title
        return retActionSheet
    }
    
    func present(onViewController: UIViewController, completion: ClosureVoid? = nil) {
        self.modalPresentationStyle = .overCurrentContext
        onViewController.present(self, animated: false, completion: completion)
        self.blurEffect.alpha = 0.0
    }
        
    func addItem(_ item: ActionSheetItem) {
        if self.isViewLoaded { return }
        self.actionItems.append(item)
    }
    
    // MARK: - Private Methods
    // MARK: Construct
    
    private func createViews() {
        let titleViewWidth: CGFloat     = ScreenSize.width - GlobalUI.Offsets.side * 2
        let buttonViewWidth: CGFloat    = ScreenSize.width - GlobalUI.Offsets.side
        let viewHeight: CGFloat         = GlobalUI.Sizes.elementHeight

        var subviewsCount = self.actionItems.count
        if self.sheetTitle != nil { subviewsCount += 1 }
        
        let vcViewHeight = self.view.frame.size.height
        var safeAreaBottomInset: CGFloat = 0.0
        if #available(iOS 11.0, *) {
            safeAreaBottomInset = self.view.safeAreaInsets.bottom
        }
        let viewBlockHeight = CGFloat(subviewsCount) * (GlobalUI.Sizes.elementHeight + GlobalUI.Offsets.verticalSpacing)
        var currentY: CGFloat = vcViewHeight - safeAreaBottomInset - viewBlockHeight
        var currentX: CGFloat = 0.0
        
        if let title = self.sheetTitle {
            currentX = GlobalUI.Offsets.side
            let frame = CGRect(x: currentX, y: currentY, width: titleViewWidth, height: viewHeight)
            
            self.elementsViews.append(self.createTitleView(withText: title, frame: frame))
            
            currentY += GlobalUI.Sizes.elementHeight + GlobalUI.Offsets.verticalSpacing
        }
        
        for (index, item) in self.actionItems.enumerated() {
            currentX = item.type == .select ? GlobalUI.Offsets.side : 0.0
            let frame = CGRect(x: currentX, y: currentY, width: buttonViewWidth, height: viewHeight)
            self.elementsViews.append(self.createButton(forItem: item, tag: index, frame: frame))
            
            currentY += GlobalUI.Sizes.elementHeight + GlobalUI.Offsets.verticalSpacing
        }
        
        self.setupColorsForElementsViews()
    }
    
    private func createTitleView(withText text: String, frame: CGRect) -> UIView {
        let titleView = ObliqueView(frame: frame)
        titleView.tag = TitleViewTag
        
        let constructor = ObliqueConstructor(withSide: .both(leftDirection: .right, rightDirection: .right))
        titleView.constructor = constructor
        
        let label = UILabel()
        label.text = text
        label.font = Fonts.title
        label.textColor = UIColor.appMainFont
        label.sizeToFit()
        titleView.addSubview(label)
        var center = titleView.center
        center.x -= GlobalUI.Offsets.side
        label.center = CGPoint(x: frame.size.width/2, y: frame.size.height/2)
        
        return titleView
    }
    
    private func createButton(forItem item: ActionSheetItem, tag: Int, frame: CGRect) -> UIButton {
        let retButton = ObliqueButton(type: .custom)
        retButton.frame = frame
        retButton.tag = tag
        retButton.setTitle(item.title, for: .normal)
        retButton.setTitleColor(UIColor.appMainFont, for: .normal)
        retButton.addTarget(self, action: #selector(ActionSheetViewController.buttonPushed(_:)), for: .touchUpInside)
        var constructor: ObliqueConstructor!
        
        var inset = retButton.titleEdgeInsets
        if item.type == .select {
            retButton.titleLabel?.font = Fonts.select
            inset.left -= GlobalUI.Offsets.side
            constructor = ObliqueConstructor(withSide: .left(direction: .right))
        } else {
            retButton.titleLabel?.font = Fonts.destructive
            inset.left += GlobalUI.Offsets.side
            constructor = ObliqueConstructor(withSide: .right(direction: .right))
        }
        retButton.titleEdgeInsets = inset
        retButton.constructor = constructor
        
        return retButton
    }
    
    private func setupColorsForElementsViews() {
        let colorsRandomizer = ColorsRandomizer(colorsCount: self.elementsViews.count)
        
        for view in self.elementsViews {
            if let button = view as? UIButton, let item = self.getItem(forButton: button) {
                if item.type == .destructive {
                    button.backgroundColor = UIColor.appGrayCancel
                } else {
                    button.backgroundColor = item.color ?? colorsRandomizer.nextRandomColor()
                }
            } else {
                view.backgroundColor = colorsRandomizer.nextRandomColor()
            }
        }
    }
    
    private func disableAllButtons(_ disable: Bool) {
        self.elementsViews.forEach {
            $0.isUserInteractionEnabled = !disable
        }
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
        let screenWidth = ScreenSize.width
        var originalFrames = [Int: CGRect]()
        
        self.elementsViews.forEach {
            self.view.addSubview($0)
            
            var frame = $0.frame
            originalFrames[$0.tag] = frame
            
            if let button = $0 as? UIButton, let item = self.getItem(forButton: button) {
                if item.type == .destructive { // cancel button
                    frame.origin.x = -frame.size.width
                } else { // other button
                    frame.origin.x = screenWidth
                }
            } else { // title view
                frame.origin.x = -frame.size.width
            }
            
            $0.frame = frame
        }
        
        let startTimes = Array(stride(from: 0.0, to: 0.8, by: 0.1))
        UIView.animateKeyframes(withDuration: 0.5, delay: 0.0, options: .calculationModeCubic, animations: {
            self.elementsViews.forEach { view in
                let startTime = startTimes.randomElement()!
                UIView.addKeyframe(withRelativeStartTime: startTime, relativeDuration: 1.0 - startTime, animations: {
                    view.frame = originalFrames[view.tag] ?? CGRect.zero
                })
            }
        }) { (_) in
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
        let screenWidth = ScreenSize.width
        let startTimes = Array(stride(from: 0.0, to: 0.8, by: 0.1))
        UIView.animateKeyframes(withDuration: 0.5, delay: 0.0, options: .calculationModeCubic, animations: {
            self.elementsViews.forEach { view in
                var frame = view.frame
                
                if let button = view as? UIButton, let item = self.getItem(forButton: button) {
                    if item.type == .destructive { // cancel button
                        frame.origin.x = -frame.size.width
                    } else { // other button
                        frame.origin.x = screenWidth
                    }
                } else { // title view
                    frame.origin.x = -frame.size.width
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

    
    // MARK: Helpers
    
    private func sortItems() {
        let select      = self.actionItems.filter { $0.type == .select }
        let destructive = self.actionItems.filter { $0.type == .destructive }
        
        self.actionItems = select + destructive
    }
    
    private func getItem(forButton button: UIButton) -> ActionSheetItem? {
        let tag = button.tag
        if tag < self.actionItems.count {
            return self.actionItems[tag]
        }
        
        return nil
    }
    
    private func getButton(forItem item: ActionSheetItem) -> UIButton? {
        if let index = self.actionItems.firstIndex(of: item) {
            return self.elementsViews.filter({ $0.tag == index }).first as? UIButton
        }
        
        return nil
    }
    
    @objc private func buttonPushed(_ button: UIButton) {
        guard let item = self.getItem(forButton: button) else {
            return
        }
        
        self.startDisappearanceAnimation(withCompletion: {
            self.dismiss(animated: false, completion: nil)
            item.action?(item)
        })
    }
}
