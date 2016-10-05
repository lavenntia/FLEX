//
//  DeeplinkController.m
//  Tokopedia
//
//  Created by Tonito Acen on 9/10/15.
//  Copyright (c) 2015 TOKOPEDIA. All rights reserved.
//

#import "DeeplinkController.h"
#import "NavigateViewController.h"
#import "WebViewController.h"
#import "RequestUtils.h"
#import "SearchResultViewController.h"
#import "SearchResultShopViewController.h"
#import "TKPDTabNavigationController.h"
#import <GoogleAppIndexing/GoogleAppIndexing.h>
#import "MyWishlistViewController.h"
#import "ProductAddEditViewController.h"
#import "TransactionCartRootViewController.h"
#import "ContactUsWireframe.h"
#import "TPContactUsDependencies.h"
#import "LoginViewController.h"
#import "PhoneVerifViewController.h"
#import "NSURL+Dictionary.h"

#import "string_product.h"

@interface DeeplinkController ()

@property (strong, nonatomic) UIViewController *activeController;
@property (strong, nonatomic) NavigateViewController *navigator;

@end

@implementation DeeplinkController

#pragma mark - Class methods

- (id)init {
    self = [super init];
    if (self) {
        UIViewController *mainController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
        UITabBarController *tabBarController = (UITabBarController *)[mainController presentedViewController];
        UINavigationController *navigationController = tabBarController.selectedViewController;
        self.activeController = [navigationController.viewControllers lastObject];
        
        self.navigator = [NavigateViewController new];

        if ([self topViewController] != [UITabBarController class]) {
            UIViewController *vc = [self topViewController];
            [vc.navigationController dismissViewControllerAnimated:YES completion:nil];
        }
        
    }
    return self;
}

- (UIViewController *)topViewController{
    return [self topViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

- (UIViewController *)topViewController:(UIViewController *)rootViewController
{
    if (rootViewController.presentedViewController == nil) {
        return rootViewController;
    }
    
    if ([rootViewController.presentedViewController isMemberOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)rootViewController.presentedViewController;
        UIViewController *lastViewController = [[navigationController viewControllers] lastObject];
        return [self topViewController:lastViewController];
    }
    
    UIViewController *presentedViewController = (UIViewController *)rootViewController.presentedViewController;
    return [self topViewController:presentedViewController];
}

+ (BOOL)shouldOpenWebViewURL:(NSURL *)url {
    BOOL shouldOpen = NO;
    
    [TPAnalytics trackUserId];
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    TAGContainer *gtmContainer = appDelegate.container;
    
    NSString *excludedUrlsString = [gtmContainer stringForKey:@"excluded-url"];
    NSArray *excludedUrls = [excludedUrlsString componentsSeparatedByString:@","];
    if([excludedUrls containsObject:[url path]]) {
        shouldOpen = YES;
    }
    
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern: @"/tokopedia.com/"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    NSRange textRange = NSMakeRange(0, [url host].length);
    NSRange matchRange = [regex rangeOfFirstMatchInString:[url host]
                                                  options:NSMatchingReportProgress
                                                    range:textRange];
    
    if (matchRange.location != NSNotFound) {
        shouldOpen = YES;
    }
    return shouldOpen;
}

- (void)redirectToViewControllerWithURL:(NSURL *)url {
    
    [TPAnalytics trackCampaign:url];
    
    NSArray *explodedPathUrl = [[url path] componentsSeparatedByString:@"/"];
    
    if ([[url absoluteString] rangeOfString:@"/home"].location != NSNotFound) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kTKPD_REDIRECT_TO_HOME object:nil];
    }
    else if ([[url absoluteString] rangeOfString:@"pulsa"].location != NSNotFound) {
        [self activeController:self.activeController showWebViewURL:url];
    }
    else if(explodedPathUrl.count > 1 && [explodedPathUrl[1] isEqualToString:@"p"]) {
        //directory
        [self redirectToDirectory:explodedPathUrl];
    }
    else if ([[url absoluteString] rangeOfString:@"search"].location != NSNotFound) {
        if ([url.parameters objectForKey:@"q"]) {
            //search
            [self redirectToSearchResult:url];
        } else {
            [self redirectToSearchPage];
        }
    }
    else if(explodedPathUrl.count > 1 && [explodedPathUrl[1] isEqualToString:@"hot"]) {
        //hot
        NSDictionary *data = @{@"key":explodedPathUrl[2]};
        [self.navigator navigateToHotlistResultFromViewController:self.activeController
                                                         withData:data];
    }
    else if(explodedPathUrl.count > 1 && [explodedPathUrl[1] isEqualToString:@"catalog"]) {
        //catalog
        [self.navigator navigateToCatalogFromViewController:self.activeController
                                              withCatalogID:explodedPathUrl[2]
                                              andCatalogKey:@""];
    }
    else if ([[url absoluteString] rangeOfString:@"tx.pl"].location != NSNotFound) {
        //cart
        [self redirectToCart];
    }
    else if ([[url absoluteString] rangeOfString:@"tab=wishlist"].location != NSNotFound) {
        //wishlist
        [self redirectToWishlist];
    }
    else if ([[url absoluteString] rangeOfString:@"create-shop"].location != NSNotFound) {
        //create shops
        [self redirectToCreateShop];
    }
    else if ([[url absoluteString] rangeOfString:@"product-add.pl"].location != NSNotFound) {
        [self redirectToAddProduct];
    }
    else if ([[url absoluteString] rangeOfString:@"contact-us-faq.pl"].location != NSNotFound) {
        [self redirectToContactUs];
    }
    else if ([[url absoluteString] rangeOfString:@"tab=shipping"].location != NSNotFound) {
        [self redirectToShipmentSetting];
    }
    else if ([[url absoluteString] rangeOfString:@"msisdn-verification.pl"].location != NSNotFound) {
        [self redirectToPhoneVerification];
    }
    else if ([[url absoluteString] rangeOfString:@"login.pl"].location != NSNotFound) {
        [self redirectToLogin];
    }
    else if ([[url absoluteString] rangeOfString:@"contact-shop"].location != NSNotFound){
        NSRange range = [url.absoluteString rangeOfString:@"shop-id"];
        NSString *parameterString = [url.absoluteString substringFromIndex:range.length + range.location+ 1];
        NSRange andRange = [parameterString rangeOfString:@"&"];
        NSString *shopId = [parameterString substringToIndex:andRange.location];
        self.activeController.hidesBottomBarWhenPushed = YES;
        [self.navigator navigateToShopFromViewController:self.activeController withShopID:shopId];
        self.activeController.hidesBottomBarWhenPushed = NO;
    } else if ([[url absoluteString] rangeOfString:@"contact-us"].location != NSNotFound) {
        [self redirectToContactUs];
    }
    else if(explodedPathUrl.count == 2) {
        //shop
        if([self isUrlContainPerlPostfix:explodedPathUrl[1]]) {
            [self activeController:self.activeController showWebViewURL:url];
        } else {
            [self redirectToShop:explodedPathUrl];
        }
    }
    else if(explodedPathUrl.count == 3) {
        //product
        NSDictionary *data = @{
            @"product_key"   : explodedPathUrl[2],
            @"shop_domain"   : explodedPathUrl[1]
        };
        
        if([self isUrlContainPerlPostfix:explodedPathUrl[2]]) {
            [self activeController:self.activeController showWebViewURL:url];
        } else {
            [self.navigator navigateToProductFromViewController:self.activeController
                                                       withData:data];
        }

    }
}

- (BOOL)isUrlContainPerlPostfix:(NSString*)url {
    if([url rangeOfString:@".pl"].location != NSNotFound) {
        return YES;
    }
    
    return NO;
}

#pragma mark - Redirect to Web View

- (void)activeController:(UIViewController *)viewController showWebViewURL:(NSURL *)url {
    NSArray *explodedPathUrl = [[url path] componentsSeparatedByString:@"/"];
    WebViewController *webController = [[WebViewController alloc] init];
    webController.strTitle = explodedPathUrl[1];
    webController.strURL = [url absoluteString];
    webController.hidesBottomBarWhenPushed = YES;
    [viewController.navigationController pushViewController:webController animated:YES];
}

#pragma mark - Redirect to VCs

- (void)redirectToDirectory:(NSArray *)explodedPathUrl {
    NSString *firstDepartment = [explodedPathUrl count] >= 3 ? explodedPathUrl[2] : @"";
    NSString *secondDepartment = [explodedPathUrl count] >= 4 ? explodedPathUrl[3] : @"";
    NSString *thirdDepartment = [explodedPathUrl count] >= 5 ? explodedPathUrl[4] : @"";
    NSString *scIdentifier = [explodedPathUrl componentsJoinedByString:@"_"];
    scIdentifier = [scIdentifier stringByReplacingOccurrencesOfString:@"_p_" withString:@""];
    
    NSDictionary *departments = @{
        @"department_1" : firstDepartment,
        @"department_2" : secondDepartment,
        @"department_3" : thirdDepartment,
        @"st"           : @"product",
        @"sc_identifier" : scIdentifier
    };
    [self.navigator navigateToSearchFromViewController:self.activeController withData:departments];
}

- (void)redirectToSearchPage {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"redirectToSearch" object:self];
}

- (void)redirectToSearchResult:(NSURL *)url {
    NSString *urlString = [[url absoluteString] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSMutableDictionary *data = [[urlString URLQueryParametersWithOptions:URLQueryOptionDefault] mutableCopy];
    [data setObject:url.parameters[@"q"] forKey:@"search"];
    
    SearchResultViewController *searchProductController = [[SearchResultViewController alloc] init];
    [data setObject:@"search_product" forKey:@"type"];
    searchProductController.data = [data copy];

    SearchResultViewController *searchCatalogController = [[SearchResultViewController alloc] init];
    [data setObject:@"search_catalog" forKey:@"type"];
    searchCatalogController.data = [data copy];
    
    SearchResultShopViewController *searchShopController = [[SearchResultShopViewController alloc] init];
    [data setObject:@"search_shop" forKey:@"type"];
    searchShopController.data = [data copy];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        NSArray *viewControllers = @[searchProductController, searchCatalogController, searchShopController];
        
        TKPDTabNavigationController *tabController = [[TKPDTabNavigationController alloc] init];
        [tabController setNavigationTitle:[data objectForKey:@"q"]];
        [tabController setViewControllers:viewControllers];
        
        if ([[data objectForKey:@"st"] isEqualToString:@"catalog"]) {

            [tabController setSelectedIndex:1];
            [tabController setSelectedViewController:searchProductController animated:YES];
            
            NSDictionary *userInfo = @{@"count": @(3), @"selectedIndex": @(1)};
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setsegmentcontrol" object:nil userInfo:userInfo];

        } else if ([[data objectForKey:@"st"] isEqualToString:@"shop"]) {
            
            [tabController setSelectedIndex:2];
            [tabController setSelectedViewController:searchCatalogController animated:YES];

            NSDictionary *userInfo = @{@"count": @(2),  @"selectedIndex": @(1), @"hasCatalog": @(NO)};
            [[NSNotificationCenter defaultCenter] postNotificationName:@"setsegmentcontrol" object:nil userInfo:userInfo];
        }

        tabController.hidesBottomBarWhenPushed = YES;
        [self.activeController.navigationController pushViewController:tabController animated:YES];
    });
}

- (void)redirectToCart {
    UserAuthentificationManager *auth = [UserAuthentificationManager new];
    if (auth.getUserId) {
        TransactionCartRootViewController *controller = [TransactionCartRootViewController new];
        self.activeController.hidesBottomBarWhenPushed = YES;
        [self.activeController.navigationController pushViewController:controller animated:YES];
        self.activeController.hidesBottomBarWhenPushed = NO;
    }
}

- (void)redirectToWishlist {
    UserAuthentificationManager *auth = [UserAuthentificationManager new];
    if (auth.getUserId) {
        MyWishlistViewController *controller = [MyWishlistViewController new];
        
        self.activeController.hidesBottomBarWhenPushed = YES;
        [self.activeController.navigationController pushViewController:controller animated:YES];
        self.activeController.hidesBottomBarWhenPushed = NO;
    }
}

- (void)redirectToCreateShop {
    UserAuthentificationManager *auth = [UserAuthentificationManager new];
    if (auth.getUserId && [auth.getShopId isEqualToString:@""]) {
        OpenShopViewController *controller = [OpenShopViewController new];
        self.activeController.hidesBottomBarWhenPushed = YES;
        [self.activeController.navigationController pushViewController:controller animated:YES];
        self.activeController.hidesBottomBarWhenPushed = NO;
    }
}

- (void)redirectToAddProduct {
    UserAuthentificationManager *auth = [UserAuthentificationManager new];
    if (auth.getUserId && auth.getShopId) {
        //add product
        ProductAddEditViewController *controller = [ProductAddEditViewController new];
        controller.type = TYPE_ADD_EDIT_PRODUCT_ADD;
        self.activeController.hidesBottomBarWhenPushed = YES;
        [self.activeController.navigationController pushViewController:controller animated:YES];
        self.activeController.hidesBottomBarWhenPushed = NO;
    }
}

- (void)redirectToShop:(NSArray *)explodedPathUrl {
    self.activeController.hidesBottomBarWhenPushed = YES;
    [self.navigator navigateToShopFromViewController:self.activeController withShopName:explodedPathUrl[1]];
    self.activeController.hidesBottomBarWhenPushed = NO;
}

- (void)redirectToContactUs {
    TPContactUsDependencies *dependencies = [TPContactUsDependencies new];
    [dependencies pushContactUsViewControllerFromNavigation:self.activeController.navigationController];
}

- (void)redirectToShipmentSetting {
    OpenShopViewController *controller = [OpenShopViewController new];
    [self.activeController.navigationController pushViewController:controller animated:YES];
}

- (void)redirectToPhoneVerification {
    UserAuthentificationManager *auth = [UserAuthentificationManager new];
    if (auth.isLogin) {
        PhoneVerifViewController *controller = [PhoneVerifViewController new];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
        navigationController.navigationBar.translucent = NO;
        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self.activeController.navigationController presentViewController:navigationController animated:YES completion:NULL];
    } else {
        [self redirectToLogin];
    }
}

- (void)redirectToLogin {
    LoginViewController *controller = [LoginViewController new];
    controller.triggerPhoneVerification = YES;
    controller.isPresentedViewController = YES;
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:controller];
    navigation.navigationBar.translucent = NO;
    [self.activeController.navigationController presentViewController:navigation animated:YES completion:NULL];
}

#pragma mark - Static method

+ (BOOL)handleURL:(NSURL *)deeplinkURL {
    BOOL canOpenURL = NO;
    if ([[deeplinkURL scheme] isEqualToString:@"gsd-tokopedia"] ||
        [[deeplinkURL host] rangeOfString:@"tokopedia.com"].location != NSNotFound) {
        canOpenURL = YES;
        
        DeeplinkController *deeplinkController = [DeeplinkController new];
        NSURL *url = [GSDDeepLink handleDeepLink:deeplinkURL];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            if ([DeeplinkController shouldOpenWebViewURL:url]) {
                [deeplinkController activeController:deeplinkController.activeController showWebViewURL:url];
            } else {
                [deeplinkController redirectToViewControllerWithURL:url];
            }
        });
    }
    return canOpenURL;
}

@end
