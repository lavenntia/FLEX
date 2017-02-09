//
//  TPRoutes.swift
//  Tokopedia
//
//  Created by Tonito Acen on 10/5/16.
//  Copyright © 2016 TOKOPEDIA. All rights reserved.
//

import UIKit
import JLRoutes

class TPRoutes: NSObject {
    
    static func configureRoutes() {
        let navigator = NavigateViewController()
        
        JLRoutes.globalRoutes().unmatchedURLHandler = { (route, url, dictionary) in
            self.openWebView(url!)
        }
        
        //create shop
        JLRoutes.globalRoutes().addRoute("/buka-toko-online-gratis") { (params: [String : AnyObject]!) -> Bool in
            let userManager = UserAuthentificationManager()
            if(userManager.isLogin && userManager.getShopId() == "0") {
                let controller = OpenShopViewController(nibName: "OpenShopViewController", bundle: nil)
                UIApplication.topViewController()?.navigationController!.pushViewController(controller, animated: true)
            }
            
            return true
        }
        
        //contact us
        JLRoutes.globalRoutes().addRoute("/contact-us.pl") { (params: [String : AnyObject]!) -> Bool in
            redirectContactUs()

            return true
        }
        
        JLRoutes.globalRoutes().addRoute("/contact-us") { (params: [String : AnyObject]!) -> Bool in
            redirectContactUs()
            
            return true
        }
        
        //promo
        JLRoutes.globalRoutes().addRoute("/promo") { (params: [String : AnyObject]!) -> Bool in
            let utmString = getUTMString(params)
            let urlString = "https://www.tokopedia.com/promo" + utmString
            openWebView(NSURL(string: urlString)!)
            
            return true
        }
        
        //gold merchant
        JLRoutes.globalRoutes().addRoute("/gold") { (params: [String : AnyObject]!) -> Bool in
            let utmString = getUTMString(params)
            let urlString = "https://gold.tokopedia.com" + utmString
            openWebView(NSURL(string: urlString)!)
            return true
        }
        
        //events
        JLRoutes.globalRoutes().addRoute("/events") { (params: [String : AnyObject]!) -> Bool in
            let utmString = getUTMString(params)
            let urlString = "https://events.tokopedia.com" + utmString
            openWebView(NSURL(string: urlString)!)
            return true
        }
        
        //halaman kota
        JLRoutes.globalRoutes().addRoute("/kota") { (params: [String : AnyObject]!) -> Bool in
            let utmString = getUTMString(params)
            let urlString = "https://kota.tokopedia.com" + utmString
            openWebView(NSURL(string: urlString)!)
            return true
        }
        
        //tech
        JLRoutes.globalRoutes().addRoute("/tech") { (params: [String : AnyObject]!) -> Bool in
            let utmString = getUTMString(params)
            let urlString = "http://tech.tokopedia.com" + utmString
            openWebView(NSURL(string: urlString)!)
            return true
        }
        
        //seller
        JLRoutes.globalRoutes().addRoute("/seller-center") { (params: [String : AnyObject]!) -> Bool in
            let utmString = getUTMString(params)
            let urlString = "https://seller.tokopedia.com" + utmString
            openWebView(NSURL(string: urlString)!)
            return true
        }
        
        //promo category
        JLRoutes.globalRoutes().addRoute("/promo/category/:categoryName") { (params: [String : AnyObject]!) -> Bool in
            let categoryName = params["categoryName"] as! String
            let utmString = getUTMString(params)
            let urlString = "https://www.tokopedia.com/promo/category/" + categoryName + utmString
            openWebView(NSURL(string: urlString)!)
            
            return true
        }
        
        //hotlist
        JLRoutes.globalRoutes().addRoute("/hot") { (params: [String : AnyObject]!) -> Bool in
            NSNotificationCenter.defaultCenter().postNotificationName("redirectToHotlist", object: nil, userInfo: nil)
            
            return true
        }
        
        //blog marketplace
        JLRoutes.globalRoutes().addRoute("/blog") { (params: [String : AnyObject]!) -> Bool in
            let utmString = getUTMString(params)
            let urlString = "https://blog.tokopedia.com" + utmString
            openWebView(NSURL(string: urlString)!)
            return true
        }
        
        //blog marketplace category
        JLRoutes.globalRoutes().addRoute("/blog/category/:categoryName") { (params: [String : AnyObject]!) -> Bool in
            let categoryName = params["categoryName"] as! String
            let utmString = getUTMString(params)
            let urlString = "https://blog.tokopedia.com/category/" + categoryName + utmString
            openWebView(NSURL(string: urlString)!)
            
            return true
        }
        
        //blog marketplace article
        JLRoutes.globalRoutes().addRoute("/blog/:year/:month/:title") { (params: [String : AnyObject]!) -> Bool in
            let year = params["year"] as! String
            let month = params["month"] as! String
            let title = params["title"] as! String
            let utmString = getUTMString(params)
            let urlString = "https://blog.tokopedia.com/" + year + "/" + month + "/" + title + utmString
            openWebView(NSURL(string: urlString)!)
            
            return true
        }
        
        //bantuan
        JLRoutes.globalRoutes().addRoute("/bantuan/*") { (params: [String : AnyObject]!) -> Bool in
            let url = params[kJLRouteURLKey] as! NSURL
            openWebView(url)
            
            return true
        }
        
        //Tokopedia Tiket
        JLRoutes.globalRoutes().addRoutes(["/kereta-api", "/tiket/kereta-api"]) { (params: [String : AnyObject]!) -> Bool in
            let utmString = getUTMString(params)
            let urlString = "https://tiket.tokopedia.com/kereta-api" + utmString
            openWebView(NSURL(string: urlString)!)
            
            return true
        }

        //Tokopedia
        JLRoutes.globalRoutes().addRoute("/tiket/travel") { (params: [String : AnyObject]!) -> Bool in
            let utmString = getUTMString(params)
            let urlString = "https://tiket.tokopedia.com/travel" + utmString
            openWebView(NSURL(string: urlString)!)
            
            return true
        }
        
        //tiket KAI - blog article
        JLRoutes.globalRoutes().addRoute("/tiket/travel/:articleName") { (params: [String : AnyObject]!) -> Bool in
            let articleName = params["articleName"] as! String
            let utmString = getUTMString(params)
            let urlString = "https://tiket.tokopedia.com/travel/" + articleName + utmString
            openWebView(NSURL(string: urlString)!)
            
            return true
        }
        
        //pulsa
        JLRoutes.globalRoutes().addRoute("/pulsa") { (params: [String : AnyObject]!) -> Bool in
            let utmString = getUTMString(params)
            let urlString = "https://pulsa.tokopedia.com" + utmString
            openWebView(NSURL(string: urlString)!)
            
            return true
        }
        
        //pulsa blog
        JLRoutes.globalRoutes().addRoute("/pulsa/blog") { (params: [String : AnyObject]!) -> Bool in
            let utmString = getUTMString(params)
            let urlString = "https://pulsa.tokopedia.com/blog" + utmString
            openWebView(NSURL(string: urlString)!)
            
            return true
        }
        
        //pulsa blog article
        JLRoutes.globalRoutes().addRoute("/pulsa/blog/:articleName") { (params: [String : AnyObject]!) -> Bool in
            let articleName = params["articleName"] as! String
            let utmString = getUTMString(params)
            let urlString = "https://pulsa.tokopedia.com/blog/" + articleName + utmString
            openWebView(NSURL(string: urlString)!)
            
            return true
        }
        
        //pulsa to specific page
        JLRoutes.globalRoutes().addRoute("/pulsa/:pulsaProduct") { (params: [String : AnyObject]!) -> Bool in
            let pulsaProduct = params["pulsaProduct"] as! String
            let utmString = getUTMString(params)
            let urlString = "https://pulsa.tokopedia.com/" + pulsaProduct + utmString
            openWebView(NSURL(string: urlString)!)
            
            return true
        }
        
        //hot page
        JLRoutes.globalRoutes().addRoute("/hot/:hotName") { (params: [String : AnyObject]!) -> Bool in
            navigator.navigateToHotlistResultFromViewController(UIApplication.topViewController(), withData: ["key" : params["hotName"] as! String])
            return true
        }
        
        //directory
        JLRoutes.globalRoutes().addRoute("/p/*") { (params: [String : AnyObject]) -> Bool in
            let pathComponent = params[kJLRouteWildcardComponentsKey] as! [String]
            if(pathComponent.count > 0) {
                let departments = [
                    "department_1" : pathComponent[0],
                    "department_2" : pathComponent.count > 1 ? pathComponent[1] : "",
                    "department_3" : pathComponent.count > 2 ? pathComponent[2] : "",
                    "st" : "product",
                    "sc_identifier" : pathComponent.joinWithSeparator("_")
                ]
                
                navigator.navigateToSearchFromViewController(UIApplication.topViewController(), withData: departments)
            }
 
            return true
        }
        
        //search
        JLRoutes.globalRoutes().addRoute("/search/*") { (params: [String : AnyObject]!) -> Bool in
            navigator.navigateToSearchFromViewController(UIApplication.topViewController(), withURL: params[kJLRouteURLKey] as! NSURL)
            return true
        }
        
        //catalog detail
        JLRoutes.globalRoutes().addRoute("/catalog/:catalogId/:catalogKey") { (params: [String : AnyObject]!) -> Bool in
            navigator.navigateToCatalogFromViewController(UIApplication.topViewController(), withCatalogID: params["catalogId"] as! String, andCatalogKey: params["catalogKey"] as! String)
            return true
        }
        
        //shop page
        JLRoutes.globalRoutes().addRoute("/:shopName") { (params: [String : AnyObject]!) -> Bool in
            let url = params[kJLRouteURLKey] as! NSURL
            let shopName = params["shopName"] as! String
            isShopExists(shopName, shopExists: { (isExists) in
                if isExists {
                    navigator.navigateToShopFromViewController(UIApplication.topViewController(), withShopName: shopName)
                } else {
                    openWebView(url)
                }
            })
            
            
            return true
        }
        
        //product detail page
        JLRoutes.globalRoutes().addRoute("/:shopName/:productName") { (params: [String : AnyObject]!) -> Bool in
            let url = params[kJLRouteURLKey] as! NSURL
            let productName = params["productName"] as! String
            let shopName = params["shopName"] as! String
            
            isShopExists(shopName, shopExists: { (isExists) in
                if isExists {
                    let data = [
                        "product_key" : productName,
                        "shop_domain" : shopName
                    ]
                    navigator.navigateToProductFromViewController(UIApplication.topViewController(), withData: data)
                } else {
                    openWebView(url)
                }
            })
            
            return true
        }
        
    }
    
    static func getUTMString(params: [String : AnyObject]) -> String {
        if params["utm_source"] != nil && params["utm_medium"] != nil && params["utm_campaign"] != nil {
            let utmSource = params["utm_source"] as! String
            let utmMedium = params["utm_medium"] as! String
            let utmCampaign = params["utm_campaign"] as! String
            let utmContent = params["utm_content"] as? String ?? ""
            let utmTerm = params["utm_term"] as? String ?? ""
            
            let utmString = "/?utm_source=" + utmSource + "&utm_medium=" + utmMedium + "&utm_campaign=" + utmCampaign
            
            return utmString + "&utm_content=" + utmContent + "&utm_term=" + utmTerm
        } else {
            return ""
        }
    }
    
    static func openWebView(url: NSURL) {
        let controller = WebViewController()
        let userManager = UserAuthentificationManager()
        
        var urlString = url.absoluteString
        
        controller.strURL = userManager.webViewUrlFromUrl(urlString)
        controller.shouldAuthorizeRequest = true
        
        let visibleController = UIApplication.topViewController()
        visibleController?.navigationController?.pushViewController(controller, animated: true)
    }
    
    static func redirectContactUs() {
        let userManager = UserAuthentificationManager()
        if(userManager.isLogin) {
            NavigateViewController.navigateToContactUsFromViewController(UIApplication.topViewController())
        }
    }
    
    static func isContainPerlPostFix(urlPath: String) -> Bool {
        return (urlPath.rangeOfString(".pl") != nil)
    }
    
    static func routeURL(url: NSURL) -> Bool {
        AnalyticsManager.trackCampaign(url)
        return JLRoutes.routeURL(url)
    }
    
    static func isShopExists(domain: String, shopExists: ((Bool) -> Void)) {
        let networkManager = TokopediaNetworkManager()
        networkManager.isUsingHmac = true
        
        networkManager.requestWithBaseUrl(NSString.v4Url(),
                                          path: "/v4/shop/get_shop_info.pl",
                                          method: .GET,
                                          parameter: ["shop_domain" : domain],
                                          mapping: Shop.mapping(),
                                          onSuccess: { (mappingResult, operation) in
                                            let result : Dictionary = mappingResult.dictionary() as Dictionary
                                            let response = result[""] as! Shop
                                            
                                            if response.result.info == nil {
                                                shopExists(false)
                                            } else {
                                                shopExists(true)
                                            }
            }) { (error) in
                shopExists(false)
        }
    }
    
}

extension UIApplication {
    class func topViewController(base: UIViewController? = UIApplication.sharedApplication().keyWindow?.rootViewController) -> UIViewController? {
        if let search = base as? UISearchController {
            return search.presentingViewController
        }
        if let nav = base as? UINavigationController {
            return topViewController(nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(selected)
            }
        }
        if let presented = base?.presentedViewController {
            return topViewController(presented)
        }
        return base
    }
}
