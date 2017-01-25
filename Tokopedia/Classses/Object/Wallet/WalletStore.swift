//
//  WalletStore.swift
//  Tokopedia
//
//  Created by Tonito Acen on 11/1/16.
//  Copyright © 2016 TOKOPEDIA. All rights reserved.
//

import UIKit

class WalletStore: NSObject {
    var code: String = ""
    var message: String = ""
    var error: String = ""
    var data: WalletData?
    
    static func mapping() -> RKObjectMapping! {
        let mapping : RKObjectMapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "code" : "code",
            "message" : "message",
            "error" : "error"
            ])
        
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "data", toKeyPath: "data", withMapping: WalletData.mapping()))
        
        return mapping
    }
    
    func isExpired() -> Bool {
        return self.error == "invalid_request"
    }
    
    func shouldShowWallet() -> Bool {
        return data?.link == "1" && self.error == ""
        
    }
    
    func shouldShowActivation() -> Bool {
        return data?.action != nil
    }
    
    func walletFullUrl() -> String {
        if let data = self.data {
            return "\(data.redirect_url)?flag_app=1"
        }
        
        return ""
    }

}
