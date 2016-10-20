//
//  ShopHomeViewController.swift
//  Tokopedia
//
//  Created by Samuel Edwin on 10/19/16.
//  Copyright © 2016 TOKOPEDIA. All rights reserved.
//

import UIKit
import Masonry
import WebKit
import JLRoutes

class ShopHomeViewController: UIViewController {

    let router: JLRoutes = {
        let router = JLRoutes()
        router.addRoute("m.tokopedia.com/ramayana/etalase/:etalaseId") { dictionary in
            print("hahaha")
            return true
        }
        return router
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let webView = WKWebView()
        
        self.view.addSubview(webView)
        
        webView.mas_makeConstraints { make in
            make.edges.equalTo()(self.view)
        }
        
        webView.loadRequest(NSURLRequest(URL: NSURL(string: "http://ecs7.tokopedia.net/brand-store/ramayana/_apps/top.html")!))
        
        webView.navigationDelegate = self
        
    }

}

extension ShopHomeViewController: WKNavigationDelegate {
    func webView(webView: WKWebView,
                 decidePolicyForNavigationAction navigationAction: WKNavigationAction,
                 decisionHandler: (WKNavigationActionPolicy) -> Void) {
        if router.routeURL(navigationAction.request.URL!) {
            decisionHandler(.Cancel)
        }
        else {
            decisionHandler(.Allow)
        }
    }
}
