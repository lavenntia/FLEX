//
//  DetailProductInfoCell.h
//  Tokopedia
//
//  Created by IT Tkpd on 9/23/14.
//  Copyright (c) 2014 TOKOPEDIA. All rights reserved.
//

#import <UIKit/UIKit.h>
@class TTTAttributedLabel;

#define CPaddingTopDescToko 10
#define kTKPDDETAILPRODUCTINFOCELLIDENTIFIER @"DetailProductInfoCellIdentifier"
#define kTKPDDETAILPRODUCTVIDEOCELLIDENTIFIER @"DetailProductVideoCellIdentifier"

#pragma mark - Detail Product Info Cell Delegate
@protocol DetailProductInfoCellDelegate <NSObject>
@required
-(void)DetailProductInfoCell:(UITableViewCell*)cell withbuttonindex:(NSInteger)index;

@end

#pragma mark - Detail Product Info Cell
@interface DetailProductInfoCell : UITableViewCell
{
    IBOutlet NSLayoutConstraint *constraintHeightPreorderView;
    IBOutlet UIView *preorderView;
    IBOutlet NSLayoutConstraint *constraintHeightViewRetur;
    IBOutlet NSLayoutConstraint *constraintWidthViewRetur;
    IBOutlet NSLayoutConstraint *returImageHeightConstraint;
    IBOutlet TTTAttributedLabel *lblMessageRetur;
    IBOutlet UIView *viewRetur;
    IBOutlet UIImageView *imgRetur;
}

@property (nonatomic, weak) IBOutlet id<DetailProductInfoCellDelegate> delegate;


@property (weak, nonatomic) IBOutlet UIView *productInformationView;
@property (weak, nonatomic) IBOutlet UILabel *minorderlabel;
@property (weak, nonatomic) IBOutlet UILabel *weightlabel;
@property (weak, nonatomic) IBOutlet UILabel *insurancelabel;
@property (weak, nonatomic) IBOutlet UILabel *conditionlabel;
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *categorybuttons;
@property (weak, nonatomic) IBOutlet UIButton *etalasebutton;
@property (weak, nonatomic) IBOutlet UILabel *preorderPeriodLabel;

@property(copy) void(^didTapReturnableInfo)(NSURL* url);

+(id)newcell;
- (void)setLblDescriptionToko:(NSString *)strText;
- (void)setLblDescriptionToko:(NSString *)strText withImageURL:(NSString*)url withBGColor:(UIColor*)color withReturnableId:(NSString*)returnableID;
- (void)hiddenViewRetur;
- (TTTAttributedLabel *)getLblRetur;
- (float)getHeightReturView;
- (void)setTextPreorderPeriodLabel:(NSString*)strPreorderPeriodText;
- (void)hidePreorderView;
- (void)showPreorderView;
@end
