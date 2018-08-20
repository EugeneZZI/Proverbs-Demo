//
//  ProverbListTableViewCell.swift
//  Proverbs
//
//  Created by Eugene Zozulya on 4/23/18.
//  Copyright © 2018 Eugene Zozulya. All rights reserved.
//

import UIKit
import MGSwipeTableCell

class BaseTableViewCell: MGSwipeTableCell {

    class var nibName: String { return String(describing: self) }
    class var reuseIdentifier: String { return String(describing: self) }
    class var heightForRow: CGFloat { return 99.0 }
        
}
