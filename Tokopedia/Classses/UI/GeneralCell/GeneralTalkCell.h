//
//  GeneralTalkCell.h
//  Tokopedia
//
//  Created by IT Tkpd on 9/29/14.
//  Copyright (c) 2014 TOKOPEDIA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "string_home.h"

#define kTKPDGENERALTALKCELL_IDENTIFIER @"GeneralTalkCellIdentifier"


#pragma mark - General Talk Cell Delegate
@protocol GeneralTalkCellDelegate <NSObject>
@required
- (void)GeneralTalkCell:(UITableViewCell*)cell withindexpath:(NSIndexPath*)indexpath;

@optional
- (void)reportTalk:(UITableViewCell *)cell withindexpath:(NSIndexPath *)indexpath;
- (void)unfollowTalk:(UITableViewCell *)cell withindexpath:(NSIndexPath *)indexpath withButton:(UIButton *)buttonUnfollow;
- (void)deleteTalk:(UITableViewCell *)cell withindexpath:(NSIndexPath *)indexpath;

//harus include ini kalo mau click user / product
- (id)navigationController:(UITableViewCell *)cell withindexpath:(NSIndexPath *)indexpath;

@end

#pragma mark - General Talk Cell
@interface GeneralTalkCell : UITableViewCell

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= TKPD_MINIMUMIOSVERSION
@property (nonatomic, weak) IBOutlet id<GeneralTalkCellDelegate> delegate;
#else
@property (nonatomic, assign) IBOutlet id<GeneralTalkCellDelegate> delegate;
#endif

@property (strong, nonatomic) IBOutlet UIView *subContentView;

@property (weak, nonatomic) IBOutlet UIImageView *thumb;
@property (weak, nonatomic) IBOutlet UILabel *namelabel;
@property (weak, nonatomic) IBOutlet UILabel *timelabel;
@property (weak, nonatomic) IBOutlet UILabel *commentlabel;
@property (weak, nonatomic) IBOutlet UIButton *commentbutton;
@property (weak, nonatomic) IBOutlet UIImageView *productImageView;
@property (weak, nonatomic) IBOutlet UIView *middleView;
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (strong, nonatomic) IBOutlet UIView *buttonsView;

@property (weak, nonatomic) IBOutlet UIButton *unfollowButton;
@property (weak, nonatomic) IBOutlet UIButton *userButton;
@property (weak, nonatomic) IBOutlet UIButton *productButton;
@property (weak, nonatomic) IBOutlet UIButton *moreActionButton;

@property (strong,nonatomic) NSDictionary *data;
@property (strong, nonatomic) NSIndexPath *indexpath;

@property (nonatomic) BOOL talkFollowStatus;
@property (nonatomic) BOOL productViewIsHidden;

@property (weak, nonatomic) IBOutlet UIView *buttonsDividers;

+ (id)newcell;


@end
