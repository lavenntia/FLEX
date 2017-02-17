//
//  RequestSales.swift
//  Tokopedia
//
//  Created by Renny Runiawati on 12/17/16.
//  Copyright © 2016 TOKOPEDIA. All rights reserved.
//

import UIKit

class RequestSales: NSObject {
    
    class func fetchAcceptOrderPartial(_ products: [OrderProduct], productQuantities: [[String : String]], orderID: String, shippingLeft:String, reason: String, onSuccess: @escaping (() -> Void), onFailure:@escaping (()->Void)) {
        
        var productIDs = ""
        products.forEach { (product) in
            productIDs = "\(product.product_id)~\(productIDs)"
        }
        
        var productQuantitiesString = ""
        productQuantities.forEach { (quantity) in
            productQuantitiesString = "\(quantity["order_detail_id"]!)~\(quantity["product_quantity"]!)*~*\(productQuantitiesString)"
        }
        
        let parameters = [
            "action_type": "partial",
            "est_shipping": shippingLeft,
            "list_product_id": productIDs,
            "qty_accept": productQuantitiesString,
            "reason": reason,
            "order_id": orderID
        ]
        
        let networkManager : TokopediaNetworkManager = TokopediaNetworkManager()
        networkManager.isUsingHmac = true
        networkManager.request(withBaseUrl: NSString.v4Url(),
                                          path:"/v4/action/myshop-order/proceed_order.pl",
                                          method: .POST,
                                          parameter: parameters,
                                          mapping: ActionOrder.mapping(),
                                          onSuccess: { (mappingResult, operation) in
                                            
                                            let result : Dictionary = mappingResult.dictionary() as Dictionary
                                            let response : ActionOrder = result[""] as! ActionOrder
                                            
                                            if ((response.message_error?.count)! > 0) {
                                                StickyAlertView.showErrorMessage(response.message_error)
                                            }
                                            
                                            if ((response.message_status?.count)! > 0) {
                                                StickyAlertView.showSuccessMessage(response.message_status)
                                            }
                                            
                                            guard (response.result.is_success == "1") else {
                                                onFailure()
                                                return
                                            }
                                    
                                            onSuccess()
                                            
        }, onFailure: { (error) in
            onFailure()
        })
    }
    
    class func fetchAcceptOrder( _ orderID: String, shippingLeft:String, onSuccess: @escaping (() -> Void), onFailure:@escaping (()->Void)) {
        
        let parameters = [
            "action_type": "accept",
            "est_shipping": shippingLeft,
            "order_id" : orderID
        ]
        
        let networkManager : TokopediaNetworkManager = TokopediaNetworkManager()
        networkManager.isUsingHmac = true
        networkManager.request(withBaseUrl: NSString.v4Url(),
                                          path:"/v4/action/myshop-order/proceed_order.pl",
                                          method: .POST,
                                          parameter: parameters,
                                          mapping: ActionOrder.mapping(),
                                          onSuccess: { (mappingResult, operation) in
                                            
                                            let result : Dictionary = mappingResult.dictionary() as Dictionary
                                            let response : ActionOrder = result[""] as! ActionOrder
                                            
                                            if ((response.message_error?.count)! > 0) {
                                                StickyAlertView.showErrorMessage(response.message_error)
                                            }
                                            
                                            if ((response.message_status?.count)! > 0) {
                                                StickyAlertView.showSuccessMessage(response.message_status)
                                            }
                                            
                                            guard (response.result.is_success == "1") else {
                                                onFailure()
                                                return
                                            }
                                            
                                            onSuccess()
                                            
        }, onFailure: { (error) in
            onFailure()
        })
    }
    
    class func fetchAcceptExpiredOrder( _ orderID: String, shippingLeft:String, onSuccess: @escaping (() -> Void), onFailure:@escaping (()->Void)) {
        
        let parameters = [
            "action_type": "reject",
            "est_shipping": shippingLeft,
            "reason"    : "Order expired",
            "order_id" : orderID
        ]
        
        let networkManager : TokopediaNetworkManager = TokopediaNetworkManager()
        networkManager.isUsingHmac = true
        networkManager.request(withBaseUrl: NSString.v4Url(),
                                          path:"/v4/action/myshop-order/proceed_order.pl",
                                          method: .POST,
                                          parameter: parameters,
                                          mapping: ActionOrder.mapping(),
                                          onSuccess: { (mappingResult, operation) in
                                            
                                            let result : Dictionary = mappingResult.dictionary() as Dictionary
                                            let response : ActionOrder = result[""] as! ActionOrder
                                            
                                            if ((response.message_error?.count)! > 0) {
                                                StickyAlertView.showErrorMessage(response.message_error)
                                            }
                                            
                                            if ((response.message_status?.count)! > 0) {
                                                StickyAlertView.showSuccessMessage(response.message_status)
                                            }
                                            
                                            guard (response.result.is_success == "1") else {
                                                onFailure()
                                                return
                                            }
                                            
                                            onSuccess()
                                            
            }, onFailure: { (error) in
                onFailure()
        })
    }
        
}
