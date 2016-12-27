//
//  WebViewController.m
//  Tokopedia
//
//  Created by Tokopedia on 5/4/15.
//  Copyright (c) 2015 TOKOPEDIA. All rights reserved.
//

#import "NJKWebViewProgressView.h"
#import "WebViewController.h"
#import "TkpdHMAC.h"
#import "NSURL+Dictionary.h"

@interface WebViewController ()
@property (strong, nonatomic) IBOutlet UIWebView *webView;
@end

@implementation WebViewController
{
    NJKWebViewProgress *progressProxy;
    NJKWebViewProgressView *progressView;
}
@synthesize strURL, strTitle, strContentHTML;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = strTitle;
    
    if(strContentHTML != nil) {
        [_webView loadHTMLString:strContentHTML baseURL:nil];
    }
    else {
        //SetUp URL
        progressProxy = [[NJKWebViewProgress alloc] init];
        _webView.delegate = progressProxy;
        progressProxy.webViewProxyDelegate = self;
        progressProxy.progressDelegate = self;
        
        
        //SetUp Progress View
        CGFloat progressBarHeight = 2.f;
        CGRect navigaitonBarBounds = self.navigationController.navigationBar.bounds;
        CGRect barFrame = CGRectMake(0,     navigaitonBarBounds.size.height - progressBarHeight, navigaitonBarBounds.size.width, progressBarHeight);
        progressView = [[NJKWebViewProgressView alloc] initWithFrame:barFrame];
        [self.navigationController.navigationBar addSubview:progressView];
        
        NSURL* url = [NSURL URLWithString:strURL];
        [_webView loadRequest:[self requestForUrl:url]];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [progressView removeFromSuperview];
}


#pragma mark - UIWebView Delegate
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
}


- (void)webViewDidStartLoad:(UIWebView *)webView
{
}

-(BOOL) webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType {
    if ( inType == UIWebViewNavigationTypeLinkClicked && _isLPWebView) {
        [[UIApplication sharedApplication] openURL:[inRequest URL]];
        
        return NO;
    }
    
    if(self.onTapLinkWithUrl) {
        self.onTapLinkWithUrl([inRequest URL]);
    }
    
    return YES;
}


#pragma mark - NJKWebViewProgressDelegate
- (void)webViewProgress:(NJKWebViewProgress *)webViewProgress updateProgress:(float)progress
{
    [progressView setProgress:progress animated:YES];
}

- (NSMutableURLRequest*)requestForUrl:(NSURL*)url {
    NSMutableURLRequest* request;
    if(_shouldAuthorizeRequest) {
        request = [NSMutableURLRequest requestWithAuthorizedHeader:url];
    } else {
        request = [[NSMutableURLRequest alloc] init];
        [request setValue:@"Mozilla/5.0 (iPod; U; CPU iPhone OS 4_3_3 like Mac OS X; ja-jp) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8J2 Safari/6533.18.5" forHTTPHeaderField:@"User-Agent"];
        [request setURL:url];
    }
    
    return request;
}
@end
