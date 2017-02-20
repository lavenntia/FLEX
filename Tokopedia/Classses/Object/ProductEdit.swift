//
//  ProductEdit.swift
//  Tokopedia
//
//  Created by Tonito Acen on 7/19/16.
//  Copyright © 2016 TOKOPEDIA. All rights reserved.
//

import UIKit

class ProductEdit: NSObject {
    var message_error: [String] = []
    var status: String = ""
    var data: ProductEditResult!
    
    static func mapping() -> RKObjectMapping! {
        let mapping : RKObjectMapping = RKObjectMapping(for: self)
        mapping.addAttributeMappings(from:[
            "status" : "status",
            "message_error" : "message_error"
            ])

        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "data", toKeyPath: "data", with: ProductEditResult.mapping()))
        
        return mapping
    }
}
