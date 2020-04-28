//
//  ProverbListTableViewCell.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 4/23/18.
//  Copyright © 2018 Yevhenii Zozulia. All rights reserved.
//


import MGSwipeTableCell

class BaseTableViewCell: MGSwipeTableCell {

    class var nibName: String { return String(describing: self) }
    class var reuseIdentifier: String { return String(describing: self) }
    class var heightForRow: CGFloat { return 99.0 }
    
    // MARK: - Life Cycle Methods
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.commonInit()
    }

    // Private Methods
    
    func commonInit() {
        
    }
    
}
