//
//  HomePageCategoryLayoutRow.swift
//  Tokopedia
//
//  Created by Billion Goenawan on 10/3/16.
//  Copyright © 2016 TOKOPEDIA. All rights reserved.
//

import Foundation

class HomePageCategoryLayoutRow: NSObject {
    var id: String!
    var name: String!
    var url: String!
    var image_url: String!
    var type: String!
    var additional_info: String!
    var category_id: String!
    
    class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: HomePageCategoryLayoutRow.self)
        mapping.addAttributeMappingsFromArray(["id", "name", "url", "image_url", "type", "additional_info", "category_id"])
        
        return mapping
    }
    
}