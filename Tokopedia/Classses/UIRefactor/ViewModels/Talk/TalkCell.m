//
//  TalkCell.m
//  Tokopedia
//
//  Created by Tonito Acen on 7/22/15.
//  Copyright (c) 2015 TOKOPEDIA. All rights reserved.
//

#import "TalkCell.h"
#import "TalkModelView.h"
#import "ViewLabelUser.h"
#import "NavigateViewController.h"
#import "ReputationDetail.h"
#import "CMPopTipView.h"
#import "TalkList.h"
#import "ProductTalkDetailViewController.h"
#import "TKPDTabViewController.h"
#import "GeneralAction.h"
#import "ReportViewController.h"
#import "SmileyAndMedal.h"

#import "stringrestkit.h"
#import "detail.h"
#import "string_inbox_talk.h"

typedef NS_ENUM(NSInteger, TalkRequestType) {
    RequestList,
    RequestFollowTalk,
    RequestDeleteTalk,
    RequestReportTalk
};

@implementation TalkCell

#pragma mark - Initialization
- (void)awakeFromNib {
    // Initialization code
    _userManager = [UserAuthentificationManager new];
    _myShopID = [NSString stringWithFormat:@"%@", [_userManager getShopId]];
    _myUserID = [NSString stringWithFormat:@"%@", [_userManager getUserId]];
    _navigateController = [NavigateViewController new];
    
    UITapGestureRecognizer *productGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToProduct)];
    [self.productImageView addGestureRecognizer:productGesture];
    [self.productImageView setUserInteractionEnabled:YES];
    
    UITapGestureRecognizer *userGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToUser)];
    [self.userImageView addGestureRecognizer:userGesture];
    [self.userImageView setUserInteractionEnabled:YES];
    
    CGFloat borderWidth = 0.5f;
    
    self.view.frame = CGRectInset(self.frame, -borderWidth, -borderWidth);
    self.view.layer.borderColor = [UIColor colorWithRed:(231.0/255) green:(231.0/255) blue:(231.0/255) alpha:1.0].CGColor;
    self.view.layer.borderWidth = borderWidth;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)setTalkViewModel:(TalkModelView *)modelView {
    [self.messageLabel setText:modelView.talkMessage];
    [self.createTimeLabel setText:modelView.createTime];
    [self.totalCommentButton setTitle:[NSString stringWithFormat:@"%@ Komentar", modelView.totalComment] forState:UIControlStateNormal];
    
    if(![modelView.talkOwnerStatus isEqualToString:@"1"] && [_userManager isLogin]) {
        [self.unfollowButton setHidden:NO];
        
        CGRect newFrame = self.totalCommentButton.frame;
        newFrame.origin.x = 0;
        self.totalCommentButton.frame = newFrame;
        self.divider.hidden = NO;
    } else {
        [self.unfollowButton setHidden:YES];
        
        CGRect newFrame = self.totalCommentButton.frame;
        newFrame.origin.x = [UIScreen mainScreen].bounds.size.width/320 * 75;
        self.totalCommentButton.frame = newFrame;
        self.divider.hidden = YES;
        self.totalCommentButton.translatesAutoresizingMaskIntoConstraints = YES;
    }
    
    [self setTalkFollowStatus:[modelView.followStatus isEqualToString:@"1"] ? YES : NO];
    
    NSURLRequest *userImageRequest = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:modelView.userImage] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:kTKPDREQUEST_TIMEOUTINTERVAL];
    self.userImageView.image = nil;
    [self.userImageView setImageWithURLRequest:userImageRequest placeholderImage:[UIImage imageNamed:@"default-boy.png"] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        [self.userImageView setImage:image];
        self.userImageView.layer.cornerRadius = self.userImageView.frame.size.width/2;
    } failure:nil];
    
    NSURLRequest *productImageRequest = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:modelView.productImage] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:kTKPDREQUEST_TIMEOUTINTERVAL];
    self.productImageView.image = nil;
    [self.productImageView setImageWithURLRequest:productImageRequest placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        [self.productImageView setImage:image];
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        [self.productImageView setImage:[UIImage imageNamed:@"icon_toped_loading_grey-02.png"]];
        [self.productImageView setContentMode:UIViewContentModeCenter];
    }];
    
    [self.productButton setTitle:modelView.productName forState:UIControlStateNormal];
    [self.userButton setLabelBackground:modelView.userLabel];
    [self.userButton setText:modelView.userName];
    [self.unreadImageView setHidden:[modelView.readStatus isEqualToString:@"1"] ? NO : YES];
    
    if(modelView.userReputation.no_reputation!=nil && [modelView.userReputation.no_reputation isEqualToString:@"1"]) {
        [self.reputationButton setTitle:@"" forState:UIControlStateNormal];
        [self.reputationButton setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon_neutral_smile_small" ofType:@"png"]] forState:UIControlStateNormal];
    }
    else {
        [self.reputationButton setTitle:[NSString stringWithFormat:@"%@%%", modelView.userReputation.positive_percentage==nil? @"0":modelView.userReputation.positive_percentage] forState:UIControlStateNormal];
        [self.reputationButton setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon_smile_small" ofType:@"png"]] forState:UIControlStateNormal];
    }
                                                                                           
    [self.reputationButton setTitle:[ NSString stringWithFormat:@"%@%%", modelView.userReputation.positive_percentage == nil ? @"0" : modelView.userReputation.positive_percentage] forState:UIControlStateNormal];

}

- (void)setTalkFollowStatus:(BOOL)talkFollowStatus {
    _talkFollowStatus = talkFollowStatus;
    if (talkFollowStatus) {
        [_unfollowButton setTitle:@"Berhenti Ikuti" forState:UIControlStateNormal];
        [_unfollowButton setImage:[UIImage imageNamed:@"icon_diskusi_unfollow_grey"] forState:UIControlStateNormal];
        
    } else {
        [_unfollowButton setTitle:@"Ikuti" forState:UIControlStateNormal];
        [_unfollowButton setImage:[UIImage imageNamed:@"icon_check_grey"] forState:UIControlStateNormal];
    }
}

#pragma mark - Tap Button
- (IBAction)tapToDetailTalk:(id)sender {
    NSIndexPath *indexPath = [[_delegate getTable] indexPathForCell:self];
    
    NSInteger row = indexPath.row;
    NSMutableArray *talkList = [_delegate getTalkList];
    TalkList *list = talkList[row];
    
    NSDictionary *data = @{
                           TKPD_TALK_MESSAGE:list.talk_message?:@0,
                           TKPD_TALK_USER_IMG:list.talk_user_image?:@0,
                           TKPD_TALK_CREATE_TIME:list.talk_create_time?:@0,
                           TKPD_TALK_USER_NAME:list.talk_user_name?:@0,
                           TKPD_TALK_ID:list.talk_id?:@0,
                           TKPD_TALK_USER_ID:[NSString stringWithFormat:@"%zd", list.talk_user_id]?:@0,
                           TKPD_TALK_TOTAL_COMMENT : list.talk_total_comment?:@0,
                           kTKPDDETAILPRODUCT_APIPRODUCTIDKEY : list.talk_product_id?:@0,
                           TKPD_TALK_SHOP_ID:list.talk_shop_id?:@0,
                           TKPD_TALK_PRODUCT_IMAGE:list.talk_product_image?:@"",
                           kTKPDDETAIL_DATAINDEXKEY : @(row)?:@0,
                           TKPD_TALK_PRODUCT_NAME:list.talk_product_name?:@0,
                           TKPD_TALK_PRODUCT_STATUS:list.talk_product_status?:@0,
                           TKPD_TALK_USER_LABEL:list.talk_user_label?:@0,
                           TKPD_TALK_REPUTATION_PERCENTAGE:list.talk_user_reputation?:@0
                           };
    
    NSDictionary *userinfo;
    userinfo = @{kTKPDDETAIL_DATAINDEXKEY:@(row)};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateUnreadTalk" object:nil userInfo:userinfo];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        if (![data isEqualToDictionary:_detailViewController.data]) {
            [_detailViewController replaceDataSelected:data];
        }
    }
    else {
        ProductTalkDetailViewController *vc = [ProductTalkDetailViewController new];
        vc.data = data;
        
        UIViewController *controller = [_delegate getNavigationController:self];
        [controller.navigationController pushViewController:vc animated:YES];
    }
}

- (IBAction)tapToFollowTalk:(id)sender {
    _unfollowIndexPath = [[_delegate getTable] indexPathForCell:self];
    
    NSInteger row = _unfollowIndexPath.row;
    NSMutableArray *talkList = [_delegate getTalkList];
    _unfollowTalk = talkList[row];
    
    [self followAnimateZoomOut:self.unfollowButton];
    
    _unfollowNetworkManager = [TokopediaNetworkManager new];
    _unfollowNetworkManager.delegate = self;
    _unfollowNetworkManager.tagRequest = RequestFollowTalk;
    
    [_unfollowNetworkManager doRequest];
}

- (IBAction)tapToMoreMenu:(id)sender {
    NSMutableArray *titles = [[NSMutableArray alloc] init];
    if([_myShopID isEqualToString:_selectedTalkShopID] || [_myUserID isEqualToString:_selectedTalkUserID]) {
        [titles addObject:@"Hapus"];
    } else {
        [titles addObject:@"Lapor"];
    }
    
    NSString *joinTitles = [titles componentsJoinedByString:@","];
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Batal"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:joinTitles, nil];
    [actionSheet showInView:self.contentView];
}

- (void)tapToProduct {
    UINavigationController *controller = [_delegate getNavigationController:self];
//    [_navigateController navigateToProductFromViewController:controller withProductID:_selectedTalkProductID];
    
}

- (void)tapToUser {
    UINavigationController *controller = [_delegate getNavigationController:self];
    [_navigateController navigateToProfileFromViewController:controller withUserID:_selectedTalkUserID];
}

- (void)tapToReport {
    _reportIndexPath = [[_delegate getTable] indexPathForCell:self];
    ReportViewController *_reportController = [ReportViewController new];
    _reportController.delegate = self;
    NSMutableArray *talkList = [_delegate getTalkList];
    
    _reportTalk = talkList[_reportIndexPath.row];
    _reportController.strProductID = _reportTalk.talk_product_id;
    _reportController.strShopID = _reportTalk.talk_shop_id;
    
    TKPDTabViewController *controller = [_delegate getNavigationController:self];
    [controller.navigationController pushViewController:_reportController animated:YES];
}

- (void)tapToDelete {
    
}

#pragma mark - Action Delegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSInteger cancelButtonIndex = actionSheet.cancelButtonIndex;
    
    if (buttonIndex == 0) {
        if([_myShopID isEqualToString:_selectedTalkShopID] || [_myUserID isEqualToString:_selectedTalkUserID]) {
            _deleteIndexPath = [[_delegate getTable] indexPathForCell:self];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:PROMPT_DELETE_TALK message:PROMPT_DELETE_TALK_MESSAGE delegate:self cancelButtonTitle:BUTTON_CANCEL otherButtonTitles:nil];
            
            [alert addButtonWithTitle:BUTTON_OK];
            [alert show];
        } else {
            [self tapToReport];
        }
    }

    else if (buttonIndex != cancelButtonIndex) {
        [self tapToReport];
    }
}

#pragma mark - Smiley Delegate
- (IBAction)tapToViewSmile:sender {
    int paddingRightLeftContent = 10;
    
    UIView *viewContentPopUp = [[UIView alloc] initWithFrame:CGRectMake(0, 0, (CWidthItemPopUp*3)+paddingRightLeftContent, CHeightItemPopUp)];

    SmileyAndMedal *tempSmileyAndMedal = [SmileyAndMedal new];
    [tempSmileyAndMedal showPopUpSmiley:viewContentPopUp andPadding:paddingRightLeftContent withReputationNetral:_selectedTalkReputation.neutral withRepSmile:_selectedTalkReputation.positive withRepSad:_selectedTalkReputation.negative withDelegate:self];
    
    _popTipView = [[CMPopTipView alloc] initWithCustomView:viewContentPopUp];
    _popTipView.delegate = self;
    _popTipView.backgroundColor = [UIColor whiteColor];
    _popTipView.animation = CMPopTipAnimationSlide;
    _popTipView.dismissTapAnywhere = YES;
    _popTipView.leftPopUp = YES;
    
    UIButton *button = (UIButton *)sender;
    [_popTipView presentPointingAtView:button inView:self.view animated:YES];
}

- (void)actionVote:(id)sender {
    [self dismissAllPopTipViews];
}

- (void)dismissAllPopTipViews {
    [_popTipView dismissAnimated:YES];
    _popTipView = nil;
}

- (void)popTipViewWasDismissedByUser:(CMPopTipView *)popTipView {
    [self dismissAllPopTipViews];
}

#pragma mark - Unfollow In Action
- (NSDictionary *)getParameter:(int)tag {
    if (tag == RequestFollowTalk) {
        NSDictionary* param = @{
                                kTKPDDETAIL_ACTIONKEY : TKPD_FOLLOW_TALK_ACTION,
                                kTKPDDETAILPRODUCT_APIPRODUCTIDKEY : _unfollowTalk.talk_product_id,
                                TKPD_TALK_ID:_unfollowTalk.talk_id?:@0,
                                @"shop_id":_unfollowTalk.talk_shop_id
                                };
        
        return param;
    } else if (tag == RequestDeleteTalk) {
        NSDictionary* param = @{
                                kTKPDDETAIL_ACTIONKEY : TKPD_DELETE_TALK_ACTION,
                                kTKPDDETAILPRODUCT_APIPRODUCTIDKEY : _deleteTalk.talk_product_id,
                                TKPD_TALK_ID:_deleteTalk.talk_id?:@0,
                                kTKPDDETAILSHOP_APISHOPID : _deleteTalk.talk_shop_id
                                };
        return param;
    }
    
    return nil;
}

- (NSString *)getPath:(int)tag {
    if (tag == RequestFollowTalk || tag == RequestDeleteTalk) {
        return @"action/talk.pl";
    }
    
    return nil;
}

- (id)getObjectManager:(int)tag {
    if(tag == RequestFollowTalk || tag == RequestDeleteTalk) {
        _objectUnfollowmanager =  [RKObjectManager sharedClient];
        
        RKObjectMapping *statusMapping = [RKObjectMapping mappingForClass:[GeneralAction class]];
        [statusMapping addAttributeMappingsFromDictionary:@{kTKPD_APISTATUSKEY:kTKPD_APISTATUSKEY,
                                                            kTKPD_APIERRORMESSAGEKEY:kTKPD_APIERRORMESSAGEKEY,
                                                            kTKPD_APISERVERPROCESSTIMEKEY:kTKPD_APISERVERPROCESSTIMEKEY}];
        
        RKObjectMapping *resultMapping = [RKObjectMapping mappingForClass:[GeneralActionResult class]];
        [resultMapping addAttributeMappingsFromDictionary:@{kTKPD_APIISSUCCESSKEY:kTKPD_APIISSUCCESSKEY}];
        
        //relation
        RKRelationshipMapping *resulRel = [RKRelationshipMapping relationshipMappingFromKeyPath:kTKPD_APIRESULTKEY toKeyPath:kTKPD_APIRESULTKEY withMapping:resultMapping];
        [statusMapping addPropertyMapping:resulRel];
        
        
        //register mappings with the provider using a response descriptor
        RKResponseDescriptor *responseDescriptorStatus = [RKResponseDescriptor responseDescriptorWithMapping:statusMapping method:RKRequestMethodPOST
                                                                                                 pathPattern:@"action/talk.pl" keyPath:@"" statusCodes:kTkpdIndexSetStatusCodeOK];
        
        [_objectUnfollowmanager addResponseDescriptor:responseDescriptorStatus];
        
        return _objectUnfollowmanager;
    }
    
    return nil;
}

- (NSString *)getRequestStatus:(RKMappingResult *)mappingResult withTag:(int)tag {
    if(tag == RequestFollowTalk || tag == RequestDeleteTalk) {
        GeneralAction *action = [mappingResult.dictionary objectForKey:@""];
        return action.status;
    }
    
    return nil;
}

- (void)actionBeforeRequest:(int)tag {
    
}

- (void)actionAfterRequest:(RKMappingResult *)mappingResult withOperation:(RKObjectRequestOperation *)operation withTag:(int)tag {
    if(tag == RequestFollowTalk || tag == RequestDeleteTalk) {
        GeneralAction *generalAction = [mappingResult.dictionary objectForKey:@""];
        NSIndexPath *indexPath = (tag == RequestFollowTalk) ? _unfollowIndexPath : _deleteIndexPath;
        if(generalAction.message_error!=nil && generalAction.message_error.count>0) {
            StickyAlertView *stickyAlert = [[StickyAlertView alloc] initWithErrorMessages:generalAction.message_error delegate:self];
            [stickyAlert show];
            
            UITableView *table = [_delegate getTable];
            [table beginUpdates];
            [table reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            [table endUpdates];
        } else {
            NSArray *successMessages = [[NSMutableArray alloc] init];
            if(tag == RequestDeleteTalk) {
                successMessages = @[@"Anda berhasil menghapus diskusi ini."];
            } else {
                successMessages = @[@"Anda berhasil (batal) mengikuti diskusi ini."];
            }
            StickyAlertView *stickyAlert = [[StickyAlertView alloc] initWithSuccessMessages:successMessages delegate:[_delegate getNavigationController:self]];
            [stickyAlert show];
        }
    }
}

- (void)actionAfterFailRequestMaxTries:(int)tag {
    
}

#pragma mark - Animate Follow Button
- (void)followAnimateZoomOut:(UIButton*)buttonUnfollow {
    double delayInSeconds = 2.0;
    if([[buttonUnfollow currentTitle] isEqualToString:TKPD_TALK_FOLLOW]) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.3];
        buttonUnfollow.transform = CGAffineTransformMakeScale(1.3,1.3);
        [buttonUnfollow setTitle:TKPD_TALK_UNFOLLOW forState:UIControlStateNormal];
        buttonUnfollow.transform = CGAffineTransformMakeScale(1,1);
        [UIView commitAnimations];
    } else {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.3];
        buttonUnfollow.transform = CGAffineTransformMakeScale(1.3,1.3);
        [buttonUnfollow setTitle:TKPD_TALK_FOLLOW forState:UIControlStateNormal];
        buttonUnfollow.transform = CGAffineTransformMakeScale(1,1);
        [UIView commitAnimations];
    }
    
    buttonUnfollow.enabled = NO;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        buttonUnfollow.enabled = YES;
    });
}

#pragma mark - AlertView Delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    //delete talk
    if(buttonIndex == 1) {
        NSInteger row = [_deleteIndexPath row];
        NSMutableArray *talkList = [_delegate getTalkList];
        _deleteTalk = talkList[row];
        
        NSDictionary *userInfo = @{@"index" : @(row)};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"TokopediaDeleteInboxTalk" object:nil userInfo:userInfo];
        
        _deleteNetworkManager = [TokopediaNetworkManager new];
        _deleteNetworkManager.delegate = self;
        _deleteNetworkManager.tagRequest = RequestDeleteTalk;
        [_deleteNetworkManager doRequest];
    }
}

#pragma mark - ReportViewController Delegate
- (NSDictionary *)getParameter {
    return @{
             @"action" : @"report_product_talk",
             @"talk_id" : _reportTalk.talk_id?:@(0),
             @"shop_id" : _reportTalk.talk_shop_id?:@(0),
             @"product_id" : _reportTalk.talk_product_id?:@(0)
             };
}

- (NSString *)getPath {
    return @"action/talk.pl";
}

- (UIViewController *)didReceiveViewController {
    return [_delegate getNavigationController:self];
}


@end
