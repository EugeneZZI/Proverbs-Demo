//
//  ProverbsManager.swift
//  Proverbs
//
//  Created by Eugene Zozulya on 4/11/18.
//  Copyright © 2018 Eugene Zozulya. All rights reserved.
//

import UIKit
//import FirebaseStorage

class ProverbsManager: NSObject {
    
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
    
    private override init() {
        super.init()
    }
    
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
        
        let randomIndex = Int(arc4random_uniform(UInt32(proverbs.count)))
        let retProverb = proverbs[randomIndex]
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
    
    // MARK: - TMP
    /*
    func createHTML() {
        let allProverbs = self.getAll()
        DLog("----> COUNT \(allProverbs.count)")
        for proverb in allProverbs {
            self.loadMetadataAndCreateHTML(proverb: proverb)
        }
    }

    
    private func loadMetadataAndCreateHTML(proverb: Proverb) {
        // allow read, write: if request.auth != null;
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0].appending("/web")
        DLog("----> \(documentsPath)")
        let identifier = proverb.identifier
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let imageRef = storageRef.child("Web/ShareImages/\(identifier).jpg")
        
        imageRef.downloadURL { (url, error) in
            if let error = error {
                DLog("----> Failed to load metadata for \(proverb.identifier) error \(error)")
            } else if let url = url {
                DLog("---> \(url)")
                
                let htmlFile = Bundle.main.path(forResource: "main", ofType: "html")
                if var htmlString = try? String(contentsOfFile: htmlFile!, encoding: String.Encoding.utf8) {
                    let baseURLString = "https://www.saypro.me/share/"
                    let shareURLString = baseURLString + identifier + ".html"
                    
                    htmlString = htmlString.replacingOccurrences(of: "REPLACE_IMAGE", with: url.absoluteString)
                    htmlString = htmlString.replacingOccurrences(of: "REPLACE_PROVERB", with: proverb.text)
                    htmlString = htmlString.replacingOccurrences(of: "REPLACE_MEANING", with: proverb.meaning)
                    htmlString = htmlString.replacingOccurrences(of: "REPLACE_URL", with: shareURLString)
                    
                    let htmlURL = URL(fileURLWithPath: documentsPath).appendingPathComponent("\(identifier).html")
                    do {
                        try (htmlString as NSString).write(to: htmlURL, atomically: true, encoding: String.Encoding.utf8.rawValue)
                    } catch {
                        DLog("---> Failed")
                    }
                }
            } else {
                DLog(" ----> Failed")
            }
        }
    }
    
    func createImages() {
        let allProverbs = self.getAll()
        DLog("----> COUNT \(allProverbs.count)")
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0].appending("/images")
        
        for proverb in allProverbs {
            let view = ShareView(frame: CGRect(x: 0.0, y: 0.0, width: 640, height: 360))
            view.proverbLabel.text = proverb.text
            view.proverbLabel.sizeToFit()
            
            view.meaningLabel.text = proverb.meaning
            view.meaningLabel.sizeToFit()
            
            view.layoutIfNeeded()
            
            guard let image = view.image() else {
                DLog("---> !!! Failed to generate image!!!!")
                continue
            }
            
            guard let imageData = UIImageJPEGRepresentation(image, 0.5) else {
                DLog("---> !!! Failed to generate JPG")
                continue
            }
            
            let path = documentsPath.appending("/\(proverb.identifier).jpg")
            DLog("---> !!! PATH \(path)")
            
            do {
                try imageData.write(to: URL(fileURLWithPath: path), options: .atomic)
            } catch {
                DLog("----> Failed write to disk")
            }
        }
        
    }
    
    private func update() {
        guard let plistPath = Bundle.main.path(forResource: "FinalProverbs", ofType: "plist") else {
            return
        }
        
        var originDict = NSDictionary(contentsOfFile: plistPath) as! ProverbsPlistDictionary
        let sections = originDict.keys
        for section in sections {
            let items = originDict[section]!
            
            for var item in items {
                let proverb = item["text"]!
                let meaning = item["meaning"]!
                
                if proverb.contains("?.") {
                    DLog("---> PROVERB \(proverb)")
                    item["text"] = proverb.replacingOccurrences(of: "?.", with: "?")
                    DLog("---> PROVERB !!!! \(item["text"]!)")
                }
                if meaning.contains("?.") {
                    DLog("---> MEANING \(meaning)")
                    item["meaning"] = proverb.replacingOccurrences(of: "?.", with: "?")
                    DLog("---> MEANING \(item["meaning"]!)")
                }
            }
        }
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let newPath = documentsPath.appending("/FinalProverbs.plist")
        DLog("---> \(newPath)")
        (originDict as NSDictionary).write(toFile: newPath, atomically: true)
    }
    
    private func migrate() {
        guard let plistPath = Bundle.main.path(forResource: "NewList", ofType: "plist") else {
            return
        }
        
        let originDict = NSDictionary(contentsOfFile: plistPath) as! [String: [String: String]]
        var newDict = ProverbsPlistDictionary() // [String: [[String: String]]]
        
        var identifiers = Array(10000...40000)
        
        let randomIdentifier: () -> Int = {
            var retInt = 0
            var index = 0
            
            while retInt == 0 {
                index = Int(arc4random_uniform(UInt32(identifiers.count)))
                retInt = identifiers[index]
                DLog("----> \(retInt)")
            }
            
            DLog("----> FINAL \(retInt)")
            identifiers[index] = 0
            
            return retInt
        }
        
        let sections = originDict.keys
        for section in sections {
            let proverbs = originDict[section]!
            let allProverbs = proverbs.keys
            for proverb in allProverbs {
                var item = [String: String]()
                item["identifier"] = String(randomIdentifier())
                item["meaning"] = proverbs[proverb]
                item["text"] = proverb
                
                
                if var sectionList = newDict[section] {
                    sectionList.append(item)
                    newDict[section] = sectionList
                } else {
                    newDict[section] = [item]
                }
            }
        }
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let newPath = documentsPath.appending("/FinalProverbs.plist")
        DLog("---> \(newPath)")
        (newDict as NSDictionary).write(toFile: newPath, atomically: true)
    }
*/
}
