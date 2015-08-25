//
//  NavigateViewController.h
//  Tokopedia
//
//  Created by IT Tkpd on 3/16/15.
//  Copyright (c) 2015 TOKOPEDIA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NavigateViewController : NSObject

-(void)navigateToProfileFromViewController:(UIViewController*)viewController withUserID:(NSString *)userID;
-(void)navigateToShopFromViewController:(UIViewController*)viewController withShopID:(NSString *)shopID;
-(void)navigateToInvoiceFromViewController:(UIViewController*)viewController withInvoiceURL:(NSString *)invoiceURL;
-(void)navigateToShowImageFromViewController:(UIViewController *)viewController withImageURLStrings:(NSArray*)imageURLStrings indexImage:(NSInteger)index;
//-(void)navigateToProductFromViewController:(UIViewController *)viewController withProductID:(NSString*)productID;
- (void)navigateToProductFromViewController:(UIViewController *)viewController withName:(NSString*)name withPrice:(NSString*)price withId:(NSString*)productId withImageurl:(NSString*)url withShopName:(NSString*)shopName;
- (void)navigateToCatalogFromViewController:(UIViewController *)viewController withCatalogID:(NSString *)catalogID;

#pragma mark - Inbox
-(void)navigateToInboxMessageFromViewController:(UIViewController *)viewController;
-(void)navigateToInboxTalkFromViewController:(UIViewController *)viewController;
-(void)navigateToInboxReviewFromViewController:(UIViewController *)viewController;
- (void)navigateToInboxReviewFromViewController:(UIViewController *)viewController withGetDataFromMasterDB:(BOOL)getDataFromMaster;
-(void)navigateToInboxResolutionFromViewController:(UIViewController *)viewController;

@end
