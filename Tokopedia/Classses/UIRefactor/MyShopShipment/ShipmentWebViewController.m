
//
//  ShipmentWebViewController.m
//  Tokopedia
//
//  Created by Tokopedia on 3/29/16.
//  Copyright © 2016 TOKOPEDIA. All rights reserved.
//

#import "ShipmentWebViewController.h"
#import "NSDictionaryCategory.h"
#import "NSString+MD5.h"
#import "TkpdHMAC.h"
#import "NSURL+Dictionary.h"

@interface ShipmentWebViewController () <UIWebViewDelegate>

@property (strong, nonatomic) UIWebView *webView;
@property BOOL formSubmitted;

@end

@implementation ShipmentWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Pengaturan Tambahan";
    self.navigationItem.rightBarButtonItem = self.doneButton;

    self.view.backgroundColor = [UIColor colorWithRed:231.0/255.0 green:231.0/255.0 blue:231.0/255.0 alpha:1];
    
    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    self.webView.delegate = self;
    self.webView.hidden = YES;
    [self.webView loadRequest:[self requestWithURL:[self URLWithAdditionalParameters]]];
    [self.view addSubview:_webView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.webView.hidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.webView.hidden = YES;
}

- (NSURL *)URLWithAdditionalParameters {
    UserAuthentificationManager *auth = [UserAuthentificationManager new];
    NSString *hash = [[NSString stringWithFormat:@"%@~%@", auth.getUserId, auth.getMyDeviceToken] encryptWithMD5];
    NSString *additionalParameters = [NSString stringWithFormat:@"&shop_id=%@&user_id=%@&device_time=%f&device_id=%@&hash=%@&os_type=2", auth.getShopId, auth.getUserId, [[NSDate new] timeIntervalSince1970], auth.getMyDeviceToken, hash];

    if ([self.courier hasActiveServices]) {
        additionalParameters = [additionalParameters stringByAppendingString:[NSString stringWithFormat:@"&service_id=%@", [self.courier activeServiceIds]]];
    } else {
        additionalParameters = [additionalParameters stringByAppendingString:@"&service_id=0"];
    }
    
    NSString *URLString = [NSString stringWithFormat:@"%@%@", _courier.URLAdditionalOption, additionalParameters];
    return [NSURL URLWithString:URLString];
}

- (NSURLRequest *)requestWithURL:(NSURL *)URL {
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithAuthorizedHeader:URL];
    
    return request;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    self.webView.hidden = NO;
    self.navigationItem.rightBarButtonItem.enabled = YES;
    if (self.formSubmitted) {
        if ([self.delegate respondsToSelector:@selector(didUpdateCourierAdditionalURL:)]) {
            [self.delegate didUpdateCourierAdditionalURL:webView.request.URL];
        }
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    return YES;
}

- (UIBarButtonItem *)doneButton {
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:@"Selesai" style:UIBarButtonItemStyleDone target:self action:@selector(didTapDoneButton:)];
    button.enabled = NO;
    return button;
}

- (void)didTapDoneButton:(UIBarButtonItem *)button {
    NSString *script = @"document.getElementsByName('submit-webview')[0].click()";
    [self.webView stringByEvaluatingJavaScriptFromString:script];
    self.formSubmitted = YES;
}

@end
