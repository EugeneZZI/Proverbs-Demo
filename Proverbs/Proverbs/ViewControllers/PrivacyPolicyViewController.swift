//
//  PrivacyPolicyViewController.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 9/5/18.
//  Copyright © 2018 Yevhenii Zozulia. All rights reserved.
//

import UIKit

class PrivacyPolicyViewController: BaseViewController {

    private lazy var __once: () = {
        self.updateOffset()
    }()
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var textView: UITextView!
    
    // MARK: - Life Cycle Methods
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        _ = self.__once
    }
    
    // MARK: - Private Methods

    override func setupViews() {
        super.setupViews()
        
        if let rtfURL = Bundle.main.url(forResource: "PrivacyPolicy", withExtension: "rtf") {
            var attributedString: NSAttributedString?
            do {
                try attributedString = NSAttributedString(url: rtfURL, options: [.documentType : NSAttributedString.DocumentType.rtf], documentAttributes: nil)
            } catch {
                DLog("Failed to load Policy RTF file.")
            }
            
            self.textView.attributedText = attributedString
        }
        
        var contentInset = self.textView.contentInset
        if #available(iOS 11.0, *) {
            contentInset.top    += (self.internalNavigationBar?.bounds.height ?? 0.0) + 10.0
        } else {
            contentInset.top    += (self.internalNavigationBar?.bounds.height ?? 0.0) + 30.0
        }
        self.textView.contentInset = contentInset
        self.textView.textContainerInset = UIEdgeInsets.init(top: 0.0, left: 20.0, bottom: 0.0, right: 20.0)
        self.updateOffset()
    }
    
    private func updateOffset() {
        var offset = CGPoint.zero
        if #available(iOS 11.0, *) {
            offset.y = -(self.textView.contentInset.top + self.textView.safeAreaInsets.top)
        } else {
            offset.y = -self.textView.contentInset.top
        }
        self.textView.setContentOffset(offset, animated: false)
    }
    
    // MARK: - NavigationBarDelegate
    
    override func leftbuttonPushed(_ navigationBar: NavigationBar) {
        super.leftbuttonPushed(navigationBar)
        self.dismiss(animated: true, completion: nil)
    }
    
}

extension PrivacyPolicyViewController: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return true
    }

}
