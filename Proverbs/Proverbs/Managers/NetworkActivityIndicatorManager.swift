//
//  NetworkActivityIndicatorManager.swift
//  Proverbs
//
//  Created by Eugene Zozulya on 4/26/18.
//  Copyright © 2018 Eugene Zozulya. All rights reserved.
//

import UIKit

class NetworkActivityIndicatorManager {

    private static var loadingCount = 0
    
    class func networkOperationStarted() {
        if loadingCount == 0 {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        loadingCount += 1
    }
    
    class func networkOperationFinished() {
        if loadingCount > 0 {
            loadingCount -= 1
        }
        if loadingCount == 0 {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
    
}
