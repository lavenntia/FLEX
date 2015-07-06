//
//  TransactionCartViewController.h
//  Tokopedia
//
//  Created by IT Tkpd on 1/9/15.
//  Copyright (c) 2015 TOKOPEDIA. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TransactionCartViewController;

#pragma mark - Transaction Cart Cell Delegate
@protocol TransactionCartViewControllerDelegate <NSObject>

@required
- (void)didFinishRequestCheckoutData:(NSDictionary*)data;
- (void)didFinishRequestBuyData:(NSDictionary*)data;
- (void)isNodata:(BOOL)isNodata;

- (void)pushVC:(TransactionCartViewController*)vc toMandiriClickPayVCwithData:(NSDictionary*)data;

@optional
- (void)shouldBackToFirstPage;

@end

@interface TransactionCartViewController : UIViewController


@property (nonatomic, weak) IBOutlet id<TransactionCartViewControllerDelegate> delegate;


@property (nonatomic) NSInteger indexPage;
@property BOOL shouldRefresh;
@property (strong,nonatomic,setter=setData:) NSDictionary *data;
@property BOOL firstInit;
@property NSArray *listSummary;

-(void)doClearAllData;

@end
