//
//  WebViewSignInViewController.swift
//  Tokopedia
//
//  Created by Samuel Edwin on 6/29/16.
//  Copyright © 2016 TOKOPEDIA. All rights reserved.
//

import UIKit

@objc(WebViewSignInViewController)
class WebViewSignInViewController: UIViewController, UIWebViewDelegate, NJKWebViewProgressDelegate {

    var onReceiveToken: (String -> Void)?

    @IBOutlet var progressView: NJKWebViewProgressView!

    @IBOutlet private var webView: UIWebView! {
        didSet {
            webView.delegate = progress
        }
    }

    lazy var progress: NJKWebViewProgress! = {
        let progress = NJKWebViewProgress()
        progress.webViewProxyDelegate = self
        progress.progressDelegate = self
        return progress
    }()


    override func viewDidLoad() {
        super.viewDidLoad()

        let request = NSMutableURLRequest()
        request.setValue("Mozilla/5.0 (iPod; U; CPU iPhone OS 4_3_3 like Mac OS X; ja-jp) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8J2 Safari/6533.18.5", forHTTPHeaderField: "User-Agent")
        request.URL = NSURL(string: "\(NSString.accountsUrl())/wv/yahoo-login")

        webView.loadRequest(request)
    }

    func webViewProgress(webViewProgress: NJKWebViewProgress, updateProgress progress: Float) {
        progressView.setProgress(progress, animated: true)
    }

    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        let path = request.mainDocumentURL!.path
        let url = request.mainDocumentURL!
        self.navigationItem.title = path

        if (path == "/mappauth/code") {
            let code = url.parameters()["code"] as! String
            self.onReceiveToken?(code)
            return false
        }

        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
