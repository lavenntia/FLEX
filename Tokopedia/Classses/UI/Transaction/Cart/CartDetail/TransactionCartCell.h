//
//  TransactionCartCell.h
//  Tokopedia
//
//  Created by IT Tkpd on 1/9/15.
//  Copyright (c) 2015 TOKOPEDIA. All rights reserved.
//

#import <UIKit/UIKit.h>

#define TRANSACTION_CART_CELL_IDENTIFIER @"TransactionCartCellIdentifier"

#pragma mark - Transaction Cart Cell Delegate
@protocol TransactionCartCellDelegate <NSObject>
@required
- (void)tapMoreButtonActionAtIndexPath:(NSIndexPath*)indexPath;

@end

@interface TransactionCartCell : UITableViewCell

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= TKPD_MINIMUMIOSVERSION
@property (nonatomic, weak) IBOutlet id<TransactionCartCellDelegate> delegate;
#else
@property (nonatomic, assign) IBOutlet id<TransactionCartCellDelegate> delegate;
#endif

@property (weak, nonatomic) IBOutlet UIImageView *productThumbImageView;
@property (weak, nonatomic) IBOutlet UILabel *productNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *productPriceLabel;
@property (weak, nonatomic) IBOutlet UILabel *quantityLabel;
@property (weak, nonatomic) IBOutlet UITextView *remarkTextView;
@property (strong, nonatomic) NSIndexPath *indexPath;
@property (weak, nonatomic) IBOutlet UIButton *editButton;

+(id)newcell;

@end
