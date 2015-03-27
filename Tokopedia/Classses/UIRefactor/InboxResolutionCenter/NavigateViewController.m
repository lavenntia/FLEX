//
//  NavigateViewController.m
//  Tokopedia
//
//  Created by IT Tkpd on 3/16/15.
//  Copyright (c) 2015 TOKOPEDIA. All rights reserved.
//

#import "NavigateViewController.h"

#import "UserAuthentificationManager.h"

#import "WebViewInvoiceViewController.h"
#import "ShopContainerViewController.h"
#import "string_more.h"
#import "ProfileBiodataViewController.h"
#import "ProfileContactViewController.h"
#import "ProfileFavoriteShopViewController.h"
#import "TKPDTabProfileNavigationController.h"
#import "DetailProductViewController.h"

@implementation NavigateViewController
-(void)navigateToInvoiceFromViewController:(UIViewController *)viewController withInvoiceURL:(NSString *)invoiceURL
{
    UserAuthentificationManager *auth = [UserAuthentificationManager new];
    WebViewInvoiceViewController *VC = [WebViewInvoiceViewController new];
    NSDictionary *invoiceURLDictionary = [NSDictionary dictionaryFromURLString:invoiceURL];
    NSString *invoicePDF = [invoiceURLDictionary objectForKey:@"pdf"];
    NSString *invoiceID = [invoiceURLDictionary objectForKey:@"id"];
    NSString *userID = [auth getUserId];
    NSString *invoiceURLforWS = [NSString stringWithFormat:@"%@/invoice.pl?invoice_pdf=%@&id=%@&user_id=%@",kTkpdBaseURLString,invoicePDF,invoiceID,userID];
    VC.urlAddress = invoiceURLforWS?:@"";
    [viewController.navigationController pushViewController:VC animated:YES];
}

-(void)navigateToShopFromViewController:(UIViewController *)viewController withShopID:(NSString *)shopID
{
    ShopContainerViewController *container = [[ShopContainerViewController alloc] init];
    container.data = @{MORE_SHOP_ID : shopID};
    [viewController.navigationController pushViewController:container animated:YES];
}

-(void)navigateToProfileFromViewController:(UIViewController *)viewController withUserID:(NSString *)userID
{
    NSMutableArray *viewControllers = [NSMutableArray new];
    
    ProfileBiodataViewController *biodataController = [ProfileBiodataViewController new];
    [viewControllers addObject:biodataController];
    
    ProfileFavoriteShopViewController *favoriteController = [ProfileFavoriteShopViewController new];
    favoriteController.data = @{MORE_USER_ID:(userID)?:@""};
    [viewControllers addObject:favoriteController];
    
    ProfileContactViewController *contactController = [ProfileContactViewController new];
    [viewControllers addObject:contactController];
    
    TKPDTabProfileNavigationController *profileController = [TKPDTabProfileNavigationController new];
    profileController.data = @{MORE_USER_ID:(userID)?:@""};
    [profileController setViewControllers:viewControllers animated:YES];
    [profileController setSelectedIndex:0];
    
    [viewController.navigationController pushViewController:profileController animated:YES];
}

-(void)navigateToShowImageFromViewController:(UIViewController *)viewController withImageURLStrings:(NSArray*)imageURLStrings
{
     //TODO::
}

-(void)navigateToProductFromViewController:(UIViewController *)viewController withProductID:(NSString *)productID
{
    DetailProductViewController *vc = [DetailProductViewController new];
    vc.data = @{@"product_id" : productID};
    [viewController.navigationController pushViewController:vc animated:YES];
}

@end
