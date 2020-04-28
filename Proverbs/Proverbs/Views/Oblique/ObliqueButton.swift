//
//  ObliqueButton.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 4/13/18.
//  Copyright © 2018 Yevhenii Zozulia. All rights reserved.
//

import UIKit

class ObliqueButton: UIButton, ObliqueShape {
    
    // MARK: - Properties
    
    var constructor: ObliqueConstructor?
    var isShadow = true {
        didSet {
            self.addShadow(isShadow)
        }
    }
    
    override var backgroundColor: UIColor? {
        set {
            self.obliqueColor = newValue ?? .white
        }
        get {
            return self.obliqueColor
        }
    }
    
    private var obliqueColor: UIColor = .white {
        didSet { self.setNeedsDisplay() }
    }
    
    private var progressView            = false
    private var activityIndicator:      UIActivityIndicatorView?
    private var savedImage:             UIImage?
    
    // MARK: - Life Cycle Methods
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        super.backgroundColor = UIColor.clear
        self.isShadow = true
        self.addShadow(self.isShadow)
        self.addEventsListeneer()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        super.backgroundColor = UIColor.clear
        self.isShadow = true
        self.addShadow(self.isShadow)
        self.addEventsListeneer()
    }
    
    // MARK: - Public Methods
    
    func inProgress(show: Bool, animated: Bool, completion: ClosureVoid? = nil) {
        if show == self.progressView { return }
        self.progressView = show
        
        var perform: ClosureVoid
        var intCompletion: ClosureVoid?
        
        if show {
            self.activityIndicator = UIActivityIndicatorView(style: .white)
            self.activityIndicator?.frame = CGRect.makeCenter(forView: self.activityIndicator!, atView: self)
            self.activityIndicator?.alpha = 0.0
            self.activityIndicator?.startAnimating()
            self.addSubview(self.activityIndicator!)
            
            perform = {
                self.titleLabel?.alpha  = 0.0
                self.savedImage = self.image(for: .normal)
                self.setImage(nil, for: .normal)
                self.activityIndicator?.alpha = 1.0
            }
        } else {
            perform = {
                self.titleLabel?.alpha  = 1.0
                self.setImage(self.savedImage, for: .normal)
                self.savedImage = nil
                self.activityIndicator?.alpha = 0.0
            }
            intCompletion = {
                self.activityIndicator?.removeFromSuperview()
                self.activityIndicator = nil
            }
        }
        
        if animated {
            UIView.animate(withDuration: 0.25, animations: perform, completion: { _ in
                intCompletion?()
                completion?()
            })
        } else {
            perform()
            intCompletion?()
            completion?()
        }
    }
    
    // MARK: - Private Methods
    
    private func addShadow(_ add: Bool) {
        self.layer.shadowColor      = add ? UIColor.appShadow.withAlphaComponent(0.5).cgColor : nil
        self.layer.shadowOffset     = add ? CGSize(width: 2, height: 2) : CGSize(width: 0, height: 0)
        self.layer.shadowOpacity    = add ? 1.0 : 0.0
        self.layer.masksToBounds    = false
    }
    
    private func addEventsListeneer() {
        self.addTarget(self, action: #selector(ObliqueButton.down), for: .touchDown)
        self.addTarget(self, action: #selector(ObliqueButton.down), for: .touchDragInside)
        self.addTarget(self, action: #selector(ObliqueButton.up), for: .touchUpInside)
        self.addTarget(self, action: #selector(ObliqueButton.up), for: .touchUpOutside)
        self.addTarget(self, action: #selector(ObliqueButton.up), for: .touchDragOutside)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let constructor = self.constructor else { return }
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        
        constructor.addPathToContext(ctx, withRect: rect)
        
        ctx.setFillColor(self.obliqueColor.cgColor)
        ctx.fillPath()
    }
    
    @objc private func down() {
        UIView.animate(withDuration: 0.2) {
            self.alpha = 0.75
        }
    }
    
    @objc private func up() {
        UIView.animate(withDuration: 0.2) {
            self.alpha = 1.0
        }
    }
    
}

