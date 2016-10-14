//
//  MyWishlistWholesalePrice.swift
//  Tokopedia
//
//  Created by Billion Goenawan on 10/14/16.
//  Copyright © 2016 TOKOPEDIA. All rights reserved.
//

import Foundation

@objc(MyWishlistWholesalePrice)
class MyWishlistWholesalePrice: NSObject {
    
    var minimum: NSNumber!
    var maximum: NSNumber!
    var price: NSNumber!
    
    class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: MyWishlistWholesalePrice.self)
        mapping.addAttributeMappingsFromArray(["minimum", "maximum", "price"])
        
        return mapping
    }
}