//
//  FavoritesProverbsViewController.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 4/11/18.
//  Copyright © 2018 Yevhenii Zozulia. All rights reserved.
//

import UIKit
import MGSwipeTableCell

class FavoritesProverbsViewController: BannerViewController {
    
    enum SortOption {
        case alphabet
        case date
    }
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    
    fileprivate var proverbs        = [Proverb]()
    private let proverbsManager     = FavoriteProverbsManager.shared
    private var currentSortOption   = SortOption.alphabet {
        didSet { if oldValue != currentSortOption { self.updateListOrderAndReload() } }
    }
    
    // MARK: - Life Cycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.activityIndicator(show: true)
        self.updateData {
            self.activityIndicator(show: false)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.updateTableViewInsets()
        self.resetContentOffset()
    }
    
    // MARK: - NavigationBarDelegate
    
    override func leftbuttonPushed(_ navigationBar: NavigationBar) {
        super.leftbuttonPushed(navigationBar)
        self.navigationController?.popViewController(animated: true)
    }
    
    override func rightbuttonPushed(_ navigationBar: NavigationBar) {
        super.rightbuttonPushed(navigationBar)
        self.showSortOptionsSheet()
    }
    
    // MARK: - Private Methods
    // MARK: UI
    
    override func setupViews() {
        super.setupViews()
        self.setupTableView()
    }
    
    private func setupTableView() {
        self.tableView.tableFooterView = UIView()
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = ProverbListTableViewCell.heightForRow
        
        let control = UIRefreshControl()
        control.backgroundColor = .clear
        control.tintColor = .clear
        control.addTarget(self, action: #selector(FavoritesProverbsViewController.reload), for: .valueChanged)
        let loader = self.createActivityIndicatorView()
        var frame = CGRect.makeCenter(forView: loader, atRect: control.bounds)
        frame.origin.x = (ScreenSize.width - frame.width) / 2
        loader.frame = frame
        loader.startAnimating()
        control.addSubview(loader)
        self.tableView.refreshControl = control
    }
    
    private func showSortOptionsSheet() {
        if let action = ActionSheetViewController.make(withTitle: "Sort by") {
            let button1 = ActionSheetItem(type: .select, title: "Alphabet") { _ in
                self.currentSortOption = .alphabet
            }
            let button2 = ActionSheetItem(type: .select, title: "Added Date") { _ in
                self.currentSortOption = .date
            }
            let cancel = ActionSheetItem(type: .destructive, title: "Cancel")
            
            action.addItem(button1)
            action.addItem(cancel)
            action.addItem(button2)
            action.present(onViewController: self)
        }
    }
    
    private func updateCurrentSortOptionButtonImage() {
        switch self.currentSortOption {
        case .alphabet: self.internalNavigationBar?.updateImageForFavoritesProverbsSortButton(UIImage(named: "SortAlphabetIcon")!)
        case .date: self.internalNavigationBar?.updateImageForFavoritesProverbsSortButton(UIImage(named: "SortDateIcon")!)
        }
    }
    
    private func updateTableViewInsets() {
        var safeInset = UIEdgeInsets.zero
        if #available(iOS 11.0, *) {
            safeInset = self.view.safeAreaInsets
        }
        
        var inset = self.tableView.contentInset
        inset.top = (self.internalNavigationBar?.frame.maxY ?? 0.0) - safeInset.top
        
        if self.isBannerVisible {
            inset.bottom = ScreenSize.height - self.bannerHolderView.frame.minY - safeInset.bottom
        } else {
            inset.bottom = 0.0
        }
        
        self.tableView.contentInset = inset
    }
    
    private func resetContentOffset() {
        var offseet = -self.tableView.contentInset.top
        if #available(iOS 11.0, *) {
            offseet -= self.view.safeAreaInsets.top
        }
        
        self.tableView.contentOffset = CGPoint(x: 0.0, y: offseet)
    }
    
    // MARK: Data
    
    @objc func reload() {
        self.updateData {
            after(2) {
            self.tableView.refreshControl?.endRefreshing()
            }
        }
    }
    
    private func updateData(withCompletion completion: ClosureVoid? = nil) {
        self.proverbsManager.getAll {
            switch $0 {
            case .success(let proverbs):
                self.proverbs = proverbs
            case .failure(let error):
                DLog("Error \(error)")
                break
            }

            self.updateListOrderAndReload()
            completion?()
        }
    }
    
    private func updateListOrderAndReload() {
        switch self.currentSortOption {
        case .alphabet:
            self.sortListAlphabetically()
        case .date:
            self.sortListByAddedDate()
        }
        
        self.updateCurrentSortOptionButtonImage()
        self.tableView.reloadData()
    }
    
    private func sortListAlphabetically() {
        self.proverbs = ProverbsManager.sortAlphabetically(proverbs: self.proverbs)
    }
    
    private func sortListByAddedDate() {
        self.proverbs = ProverbsManager.sortByAddedDate(proverbs: self.proverbs)
    }
    
    fileprivate func deleteFromFavorites(proverb: Proverb, completion: @escaping ClosureBool) {
        var deleteIndex = -1
        for (index, value) in self.proverbs.enumerated() {
            if value.identifier == proverb.identifier {
                deleteIndex = index
                break
            }
        }
        
        let internalCompletion = { (result: Bool) in
            if result && deleteIndex >= 0 {
                self.proverbs.remove(at: deleteIndex)
            }
            
            completion(result)
        }
        
        FavoriteProverbsManager.shared.delete(proverb: proverb) { (error) in
            if let error = error {
                let result = self.checkFavoriteManagerError(error)
                internalCompletion(result)
            } else {
                internalCompletion(true)
            }
        }
    }
    
    private func checkFavoriteManagerError(_ error: Error) -> Bool {
        guard let managerError = error as? FavoriteProverbsManagerError else {
            return true
        }
        
        switch managerError {
        case .undefined:
            UIAlertController.show(withTitle: "Error", message: "Failed to delete proverb from favorites")
            return false
        default:
            return true
        }
    }
    
    // MARK: Notifications
    
    override func addNotificationsObserver() {
        super.addNotificationsObserver()
        
        self.notificaionCenter.addObserver(self,
                                           selector: #selector(FavoritesProverbsViewController.didDeleteFavoriteProverbNotification(_:)),
                                           name: NSNotification.Name(rawValue: FavoriteProverbsManager.NotificationName.DidDelete),
                                           object: nil)
    }
    
    @objc private func didDeleteFavoriteProverbNotification(_ notif: Notification) {
        if !self.isVisible {
            guard let info = notif.userInfo,
                let originIdentifier = info[FavoriteProverbsManager.NotificationKey.OriginProverbIdentifier] as? String else {
                    self.updateData()
                    return
            }
            
            guard let favoriteProverbs = self.proverbs as? [FavoriteProverb] else {
                self.updateData()
                return
            }
            
            if favoriteProverbs.first?.isRealm == true {
                self.updateData()
                return
            }
            
            var indexPath: IndexPath?
            
            for (index, proverb) in favoriteProverbs.enumerated() {
                if proverb.originIdentifier == originIdentifier {
                    indexPath = IndexPath(item: index, section: 0)
                    break
                }
            }

            if let indexPath = indexPath {
                self.proverbs.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .fade)
            } else {
                self.updateData()
            }
        }
    }
    
}

// MARK: - UITableViewDelegate & UITableViewDataSource

extension FavoritesProverbsViewController: UITableViewDelegate, UITableViewDataSource, MGSwipeTableCellDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.proverbs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ProverbListTableViewCell.reuseIdentifier, for: indexPath) as? ProverbListTableViewCell  else {
            return UITableViewCell()
        }
        
        let proverb = self.proverbs[indexPath.row]
        cell.proverbLabel.text = proverb.text
        cell.meaningLabel.text = proverb.meaning
        cell.delegate = self
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let detailsController = ProverbViewController.create() {
            detailsController.proverb = self.proverbs[indexPath.row]
            detailsController.backButtonColor = UIColor.appDarkGrayBlue
            self.navigationController?.pushViewController(detailsController, animated: true)
        }
    }
    
    func swipeTableCell(_ cell: MGSwipeTableCell, canSwipe direction: MGSwipeDirection) -> Bool {
        return direction == .rightToLeft
    }
    
    
    func swipeTableCell(_ cell: MGSwipeTableCell, swipeButtonsFor direction: MGSwipeDirection, swipeSettings: MGSwipeSettings, expansionSettings: MGSwipeExpansionSettings) -> [UIView]? {
        guard let indexPath = self.tableView.indexPath(for: cell) else {
            return nil
        }
        
        let proverb = self.proverbs[indexPath.row]

        if direction == MGSwipeDirection.rightToLeft {
            return [
                MGSwipeButton(title: "", icon: UIImage(named: "DeleteIcon"), backgroundColor: .clear, padding: 20, callback: { (cell) -> Bool in
                    self.deleteFromFavorites(proverb: proverb) { deleted in
                        if deleted {
                            self.tableView.deleteRows(at: [indexPath], with: .fade)
                        }
                    }
                    return true;
                })
            ]
        }
        
        return nil
    }
    
}

