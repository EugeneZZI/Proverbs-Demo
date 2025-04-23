//
//  AllProverbsViewController.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 4/11/18.
//  Copyright © 2018 Yevhenii Zozulia. All rights reserved.
//

import UIKit

class AllProverbsViewController: BaseViewController {

    // MARK: - IBOutlets
    
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    
    fileprivate var proverbs        = [String: [Proverb]]()
    fileprivate var sections        = [String]()
    private let proverbsManager     = ProverbsManager.shared
    
    fileprivate var sectionsColors = [UIColor]()
    
    // MARK: - Life Cycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.updateTableViewInsets()
        self.resetContentOffset()
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
        
        self.tableView.sectionHeaderHeight = GlobalUI.NavigationBar.defaultButtonSize.height
        self.tableView.sectionIndexBackgroundColor = .clear
        self.tableView.tableFooterView = UIView()
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = ProverbListTableViewCell.heightForRow
    }
    
    private func updateTableViewInsets() {
        var safeInset = UIEdgeInsets.zero
        if #available(iOS 11.0, *) {
            safeInset = self.view.safeAreaInsets
        }
        
        var inset = self.tableView.contentInset
        inset.top = (self.internalNavigationBar?.frame.maxY ?? 0.0) - safeInset.top - GlobalUI.NavigationBar.defaultButtonSize.height
        self.tableView.contentInset = inset
        
        inset.top += GlobalUI.NavigationBar.defaultButtonSize.height
        self.tableView.scrollIndicatorInsets = inset
    }
    
    private func resetContentOffset() {
        var offseet = -self.tableView.contentInset.top
        if #available(iOS 11.0, *) {
            offseet -= self.view.safeAreaInsets.top
        }
        
        self.tableView.contentOffset = CGPoint(x: 0.0, y: offseet)
    }
    
    fileprivate func createView(forSection section: Int) -> UIView {
        let holderSectionView = UIView()
        holderSectionView.backgroundColor = .clear
        let sectionView = ObliqueView(frame: CGRect(x: ScreenSize.width - GlobalUI.NavigationBar.defaultButtonSize.width,
                                                    y: 0.0,
                                                    width: GlobalUI.NavigationBar.defaultButtonSize.width,
                                                    height: GlobalUI.NavigationBar.defaultButtonSize.height))
        let constructor = ObliqueConstructor(withSide: .left(direction: .right))
        sectionView.constructor = constructor
        let color = self.sectionsColors[section]
        sectionView.backgroundColor = color
        holderSectionView.addSubview(sectionView)
        
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: GlobalUI.Fonts.mainSize, weight: .semibold)
        titleLabel.text = self.sections[section]
        titleLabel.textColor = .white
        titleLabel.sizeToFit()
        
        let x = (sectionView.frame.size.width - titleLabel.frame.size.width) / 2 + GlobalUI.NavigationBar.tableViewSectionTitleOffset
        let y = (sectionView.frame.size.height - titleLabel.frame.size.height) / 2
        titleLabel.frame = CGRect(x: x, y: y, width: titleLabel.frame.size.width, height: titleLabel.frame.size.height)
        sectionView.addSubview(titleLabel)
        
        return holderSectionView
    }
    
    // MARK: Data
    
    private func loadData(withCompletion: ClosureVoid? = nil) {
        let allProverbs = self.proverbsManager.getAll()
        self.sections = self.proverbsManager.getAllSections()
        
        let colorsRandomizer = ColorsRandomizer(colorsCount: self.sections.count)
        
        self.sections.forEach { section in
            var sectionProverbs = allProverbs.filter { $0.section == section  }
            sectionProverbs.sort(by: { $0.text < $1.text })
            self.proverbs[section] = sectionProverbs
            self.sectionsColors.append(colorsRandomizer.nextRandomColor())
        }
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource

extension AllProverbsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.proverbs[self.sections[section]]?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return self.createView(forSection: section)
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return self.sections
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ProverbListTableViewCell.reuseIdentifier, for: indexPath) as? ProverbListTableViewCell else {
            return UITableViewCell()
        }
        
        let section = indexPath.section
        let row     = indexPath.row
        
        if let proverb = self.proverbs[self.sections[section]]?[row] {
            cell.proverbLabel.text = proverb.text
            cell.meaningLabel.text = proverb.meaning
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let section = indexPath.section
        let row     = indexPath.row
        
        if let detailsController = ProverbViewController.create(), let proverb = self.proverbs[self.sections[section]]?[row] {
            let section = tableView.indexPathsForVisibleRows?.first?.section ?? 0
            let color = self.sectionsColors[section]
            
            detailsController.proverb = proverb
            detailsController.backButtonColor = color
            self.navigationController?.pushViewController(detailsController, animated: true)
        }
    }
    
}
