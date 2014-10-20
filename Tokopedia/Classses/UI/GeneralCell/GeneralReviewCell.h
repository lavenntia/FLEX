//
//  GeneralReviewCell.h
//  Tokopedia
//
//  Created by IT Tkpd on 10/9/14.
//  Copyright (c) 2014 TOKOPEDIA. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "StarsRateView.h"

#define kTKPDGENERALREVIEWCELLIDENTIFIER @"GeneralReviewCellIdentifier"

#pragma mark - Hotlist Result  Cell Delegate
@protocol GeneralReviewCellDelegate <NSObject>
@required
-(void)GeneralReviewCell:(UITableViewCell*)cell withindexpath:(NSIndexPath*)indexpath;
@end

#pragma mark - General Review Cell
@interface GeneralReviewCell : UITableViewCell

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= TKPD_MINIMUMIOSVERSION
@property (nonatomic, weak) IBOutlet id<GeneralReviewCellDelegate> delegate;
#else
@property (nonatomic, assign) IBOutlet id<GeneralReviewCellDelegate> delegate;
#endif


@property (weak, nonatomic) IBOutlet UIImageView *thumb;
@property (weak, nonatomic) IBOutlet UILabel *namelabel;
@property (weak, nonatomic) IBOutlet UILabel *timelabel;
@property (weak, nonatomic) IBOutlet UILabel *commentlabel;
@property (weak, nonatomic) IBOutlet StarsRateView *qualityrate;
@property (weak, nonatomic) IBOutlet StarsRateView *speedrate;
@property (weak, nonatomic) IBOutlet StarsRateView *servicerate;
@property (weak, nonatomic) IBOutlet StarsRateView *accuracyrate;
@property (weak, nonatomic) IBOutlet UIButton *commentbutton;

@property (strong,nonatomic) NSDictionary *data;
@property (strong, nonatomic) NSIndexPath *indexpath;

+(id)newcell;

@end
