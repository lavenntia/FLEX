//
//  WalletData.swift
//  Tokopedia
//
//  Created by Tonito Acen on 11/1/16.
//  Copyright © 2016 TOKOPEDIA. All rights reserved.
//

import UIKit

class WalletData: NSObject {
    var action: WalletAction!
    var balance: String = ""
    var text: String = ""
    var wallet_id: String = ""
    var redirect_url: String = ""
    var link: String = ""
    
    static func mapping() -> RKObjectMapping! {
        let mapping : RKObjectMapping = RKObjectMapping(for: self)
        mapping.addAttributeMappings(from: [
            "balance" : "balance",
            "wallet_id" : "wallet_id",
            "text" : "text",
            "redirect_url" : "redirect_url",
            "link" : "link"
            ])
        
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "action", toKeyPath: "action", with: WalletAction.mapping()))
        
        return mapping
    }

}
