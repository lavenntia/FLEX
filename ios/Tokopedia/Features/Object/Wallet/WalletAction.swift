//
//  UWalletAction.swift
//  Tokopedia
//
//  Created by Ronald Budianto on 4/28/17.
//  Copyright © 2017 TOKOPEDIA. All rights reserved.
//

import Foundation
import Unbox

final class WalletAction: NSObject, Unboxable {
    let text: String
    let redirectUrl: String
    let applinks: String
    let visibility: String?
    
    init(text: String = "", redirectUrl: String = "", applinks: String = "", visibility: String? = "0") {
        self.text = text
        self.redirectUrl = redirectUrl
        self.applinks = applinks
        self.visibility = visibility
    }
    
    convenience init(unboxer: Unboxer) throws {
        let text = try unboxer.unbox(keyPath: "text") as String
        let redirectUrl = try unboxer.unbox(keyPath: "redirect_url") as String
        let applinks = try unboxer.unbox(keyPath: "applinks") as String
        let visibility = unboxer.unbox(keyPath: "visibility") as String?
        
        self.init(text: text, redirectUrl: redirectUrl, applinks: applinks, visibility: visibility)
    }
}
