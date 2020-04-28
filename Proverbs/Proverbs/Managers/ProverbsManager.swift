//
//  ProverbsManager.swift
//  Proverbs
//
//  Created by Yevhenii Zozulia on 4/11/18.
//  Copyright © 2018 Yevhenii Zozulia. All rights reserved.
//

import UIKit

class ProverbsManager {
    
    static let shared = ProverbsManager()
    
    private typealias ProverbsPlistDictionary = [String: [[String: String]]]
    private static let InitialPopulationKey = "_InitialPopulationKey"
    
    class func sortByAddedDate(proverbs: [Proverb]) -> [Proverb] {
        return proverbs.sorted { $0.createdAt > $1.createdAt }
    }
    
    class func sortAlphabetically(proverbs: [Proverb]) -> [Proverb] {
        var retProverbs = [Proverb]()
        
        var sections = [String: [Proverb]]()
        for proverb in proverbs {
            let section = proverb.section
            if var sectionList = sections[section] {
                sectionList.append(proverb)
                sections[section] = sectionList
            } else {
                sections[section] = [proverb]
            }
        }
        
        let sortedSctionKeys = sections.keys.sorted { $0 < $1 }
        
        for sectionKey in sortedSctionKeys {
            if let sectionProverbs = sections[sectionKey] {
                var origins = [String: Proverb]()
                sectionProverbs.forEach {
                    let text = $0.text
                    if text.contains(")") {
                        if let sortKey = text.split(separator: ")").last {
                            origins[String(sortKey)] = $0
                        }
                    } else {
                        origins[text] = $0
                    }
                }
                
                let sortedOriginsKeys = origins.keys.sorted { $0 < $1 }
                
                sortedOriginsKeys.forEach {
                    retProverbs.append(origins[$0]!)
                }
            }
        }
        
        return retProverbs
    }
    
    // MARK: - Properties
    
    private var isInitialPopulated: Bool {
        get {
            return UserDefaults.standard.bool(forKey: ProverbsManager.InitialPopulationKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: ProverbsManager.InitialPopulationKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    private let proverbsStorage              = ProverbsStorage()
    
    // MARK: - Life Cycle Methods
    
    private init() {}
    
    // MARK: - Public Methods
    
    func checkAndPopulateProverbs() {
        if !self.isInitialPopulated {
            self.populateLocalStorageWithProverbs()
            self.isInitialPopulated = true
        }
    }
    
    func getNextRandom() -> Proverb {
        var proverbs = self.proverbsStorage.getAllUnviewed()
        if proverbs.count < 10 {
            self.proverbsStorage.markAllAsUnviewed()
            proverbs = self.proverbsStorage.getAllUnviewed()
        }
        
        let retProverb = proverbs.randomElement()!
        self.proverbsStorage.markAsViewed(proverb: retProverb)
        
        return retProverb
    }
    
    func getAllSections() -> [String] {
        let allProverbs = self.getAll()
        var sectionsList = allProverbs.map { $0.section }
        sectionsList = Array(Set(sectionsList))
        sectionsList.sort(by: { $0 < $1 })
        
        return sectionsList
    }
    
    func getAll() -> [Proverb] {
        return ProverbsManager.sortAlphabetically(proverbs: self.proverbsStorage.getAll())
    }
    
    // MARK: - Private Methods
    
    private func populateLocalStorageWithProverbs() {
        guard let proverbsDictionary = self.readProverbdsFromPlist() else {
            return
        }
        
        var realmProverbsList = Array<RProverb>()
        var counter = 0
        
        proverbsDictionary.keys.forEach { (section: String) in
            if let sectionProverbsList = proverbsDictionary[section] {
                sectionProverbsList.forEach { (proverbInfo) in
                    let modelDictionary = ["_identifier":    proverbInfo["identifier"] ?? "",
                                           "_createdAt":     Date(),
                                           "_text":          proverbInfo["text"] ?? "",
                                           "_meaning":       proverbInfo["meaning"] ?? "",
                                           "_section":       section] as [String : Any]
                    
                    let proverbModel = RProverb(value: modelDictionary)
                    
                    counter += 1
                    realmProverbsList.append(proverbModel)
                }
            }
        }
        
        let result = self.proverbsStorage.saveUpdate(withModelsList: realmProverbsList)
        DLog("Initial roverbs population with result \(result)")
    }
    
    private func readProverbdsFromPlist() -> ProverbsPlistDictionary? {
        guard let plistPath = Bundle.main.path(forResource: "FinalProverbs", ofType: "plist") else {
            return nil
        }
        
        return NSDictionary(contentsOfFile: plistPath) as? ProverbsPlistDictionary
    }

}
