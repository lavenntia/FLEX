//
//  InboxTalkViewController.m
//  Tokopedia
//
//  Created by Tokopedia on 11/28/14.
//  Copyright (c) 2014 TOKOPEDIA. All rights reserved.
//
#import "CMPopTipView.h"
#import "TKPDTabInboxTalkNavigationController.h"
#import "ShopTalkPageViewController.h"
#import "ProductTalkDetailViewController.h"
#import "GeneralTalkCell.h"

#import "Talk.h"
#import "GeneralAction.h"
#import "InboxTalk.h"

#import "inbox.h"
#import "string_home.h"
#import "stringrestkit.h"
#import "string_inbox_talk.h"
#import "detail.h"

#import "URLCacheController.h"
#import "ReputationDetail.h"
#import "ShopPageHeader.h"
#import "string_inbox_message.h"
#import "NoResultView.h"
#import "NSString+HTML.h"
#import "SmileyAndMedal.h"
#import "UserAuthentificationManager.h"

@interface ShopTalkPageViewController () <UITableViewDataSource,
UITableViewDelegate,
UIScrollViewDelegate,
SmileyDelegate,
CMPopTipViewDelegate,
GeneralTalkCellDelegate,
ShopPageHeaderDelegate,
UIAlertViewDelegate>

@property (strong, nonatomic) IBOutlet UIView *footer;
@property (strong, nonatomic) IBOutlet UIView *header;
@property (strong, nonatomic) IBOutlet UIView *stickyTab;
@property (strong, nonatomic) IBOutlet UIView *fakeStickyTab;

@property (weak, nonatomic) IBOutlet UITableView *table;
@property (nonatomic, strong) NSDictionary *userinfo;
@property (nonatomic, strong) NSMutableArray *list;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *act;


@end

@implementation ShopTalkPageViewController
{
    BOOL _isNoData;
    BOOL _isrefreshview;
    BOOL _iseditmode;
    
    NSInteger _page;
    NSInteger _limit;
    NSInteger _viewposition;

    CMPopTipView *cmPopTitpView;
    NSMutableDictionary *_paging;
    
    NSString *_uriNext;
    NSString *_talkNavigationFlag;
    
    UIRefreshControl *_refreshControl;
    NSInteger _requestCount;
    NSInteger _requestUnfollowCount;
    NSInteger _requestDeleteCount;
    
    NSTimer *_timer;
    UISearchBar *_searchbar;
    NSString *_keyword;
    NSString *_readstatus;
    NSString *_navthatwillrefresh;
    BOOL _isrefreshnav;
    BOOL _isNeedToInsertCache;
    BOOL _isLoadFromCache;
    NoResultView *_noResult;
    UserAuthentificationManager *_userManager;
    
    
    __weak RKObjectManager *_objectManager;
    __weak RKObjectManager *_objectUnfollowmanager;
    __weak RKObjectManager *_objectDeletemanager;
    
    __weak RKManagedObjectRequestOperation *_request;
    __weak RKManagedObjectRequestOperation *_requestUnfollow;
    __weak RKManagedObjectRequestOperation *_requestDelete;
    
    NSOperationQueue *_operationQueue;
    NSOperationQueue *_operationUnfollowQueue;
    NSOperationQueue *_operationDeleteQueue;
    
    
    NSString *_cachepath;
    URLCacheController *_cachecontroller;
    URLCacheConnection *_cacheconnection;
    NSTimeInterval _timeinterval;
    Talk *_talk;
    Shop *_shop;
}

#pragma mark - Initialization
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _isrefreshview = NO;
        _isNoData = YES;
    }
    
    return self;
}


- (void)initNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateTalkHeaderPosition:)
                                                 name:@"updateTalkHeaderPosition" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateTotalComment:)
                                                 name:@"UpdateTotalComment" object:nil];
  
}


#pragma mark - Life Cycle
- (void)addBottomInsetWhen14inch {
    if (is4inch) {
        UIEdgeInsets inset = _table.contentInset;
        inset.bottom += 155;
        _table.contentInset = inset;
    }
    else{
        UIEdgeInsets inset = _table.contentInset;
        inset.bottom += 240;
        _table.contentInset = inset;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self addBottomInsetWhen14inch];
    _talkNavigationFlag = [_data objectForKey:@"nav"];
    _page = 1;
    
    _operationQueue = [NSOperationQueue new];
    _operationUnfollowQueue = [NSOperationQueue new];
    _operationDeleteQueue = [NSOperationQueue new];
    _cacheconnection = [URLCacheConnection new];
    _cachecontroller = [URLCacheController new];
    _list = [NSMutableArray new];
    _refreshControl = [[UIRefreshControl alloc] init];
    _noResult = [[NoResultView alloc] initWithFrame:CGRectMake(0, 100, [UIScreen mainScreen].bounds.size.width, 200)];
    
    _table.delegate = self;
    _table.dataSource = self;
    
    _shopPageHeader = [ShopPageHeader new];
    _shopPageHeader.data = _data;
    _shopPageHeader.delegate = self;
    _header = _shopPageHeader.view;
    
    
    UIView *btmGreenLine = (UIView *)[_header viewWithTag:20];
    [btmGreenLine setHidden:NO];
    _stickyTab = [(UIView *)_header viewWithTag:18];
    
    _table.tableFooterView = _footer;
    //_table.tableHeaderView = _header;
    
    [_refreshControl addTarget:self action:@selector(refreshView:)forControlEvents:UIControlEventValueChanged];
    [_table addSubview:_refreshControl];
    
    if (_list.count > 0) {
        _isNoData = NO;
    }
    
    [_fakeStickyTab.layer setShadowOffset:CGSizeMake(0, 0.5)];
    [_fakeStickyTab.layer setShadowColor:[UIColor colorWithWhite:0 alpha:1].CGColor];
    [_fakeStickyTab.layer setShadowRadius:1];
    [_fakeStickyTab.layer setShadowOpacity:0.3];
    
    [self initNotification];
    [self configureRestKit];

    [self loadData];
    
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.screenName = @"Shop - Talk List";
    _userManager = [UserAuthentificationManager new];
    if (!_isrefreshview) {
        [self configureRestKit];
        
        if (_isNoData && _page < 1) {
            [self loadData];
        }
    }
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - TableView Delegate
-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return _header;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return _header.frame.size.height;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_isNoData) {
        
        cell.backgroundColor = [UIColor whiteColor];
    }
    
    NSInteger row = [self tableView:tableView numberOfRowsInSection:indexPath.section] -1;
    if (row == indexPath.row) {
        if (_uriNext != NULL && ![_uriNext isEqualToString:@"0"] && _uriNext != 0) {
            [self configureRestKit];
            [self loadData];
        } else {
            _table.tableFooterView = nil;
            [_act stopAnimating];
        }
    }
}


#pragma mark - TableView Source
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _isNoData ? 0 : _list.count;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell* cell = nil;
    if (!_isNoData) {
        
        NSString *cellid = kTKPDGENERALTALKCELL_IDENTIFIER;
        
        cell = (GeneralTalkCell*)[tableView dequeueReusableCellWithIdentifier:cellid];
        if (cell == nil) {
            cell = [GeneralTalkCell newcell];
            ((GeneralTalkCell*)cell).delegate = self;
            [((GeneralTalkCell*)cell).userButton setText:[UIColor colorWithRed:10/255.0f green:126/255.0f blue:7/255.0f alpha:1.0f] withFont:[UIFont fontWithName:@"GothamMedium" size:13.0f]];
            ((GeneralTalkCell*)cell).userButton.userInteractionEnabled = YES;
            [((GeneralTalkCell*)cell).userButton addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:cell action:@selector(tap:)]];
        }
        
        if (_list.count > indexPath.row) {
            TalkList *list = _list[indexPath.row];
            
            ((GeneralTalkCell*)cell).btnReputation.tag = indexPath.row;
            ((GeneralTalkCell*)cell).indexpath = indexPath;
            ((GeneralTalkCell*)cell).data = list;
            ((GeneralTalkCell*)cell).userButton.text = list.talk_user_name;
            [((GeneralTalkCell*)cell).productButton setTitle:list.talk_product_name forState:UIControlStateNormal];
            ((GeneralTalkCell*)cell).timelabel.text = list.talk_create_time;
            [((GeneralTalkCell*)cell).commentbutton setTitle:[NSString stringWithFormat:@"%@ %@", list.talk_total_comment, COMMENT_TALK] forState:UIControlStateNormal];
            
            
            if(list.talk_user_reputation.no_reputation!=nil && [list.talk_user_reputation.no_reputation isEqualToString:@"1"]) {
                [((GeneralTalkCell*)cell).btnReputation setTitle:@"" forState:UIControlStateNormal];
                [((GeneralTalkCell*)cell).btnReputation setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon_neutral_smile_small" ofType:@"png"]] forState:UIControlStateNormal];
            }
            else {
                [((GeneralTalkCell*)cell).btnReputation setTitle:[NSString stringWithFormat:@"%@%%", list.talk_user_reputation.positive_percentage==nil? @"0":list.talk_user_reputation.positive_percentage] forState:UIControlStateNormal];
                [((GeneralTalkCell*)cell).btnReputation setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon_smile_small" ofType:@"png"]] forState:UIControlStateNormal];
            }
            
            //Set user label
//            if([list.talk_user_label isEqualToString:CPenjual]) {
//                [((GeneralTalkCell*)cell).userButton setColor:CTagPenjual];
//            }
//            else if([list.talk_user_label isEqualToString:CPembeli]) {
//                [((GeneralTalkCell*)cell).userButton setColor:CTagPembeli];
//            }
//            else if([list.talk_user_label isEqualToString:CAdministrator]) {
//                [((GeneralTalkCell*)cell).userButton setColor:CTagAdministrator];
//            }
//            else if([list.talk_user_label isEqualToString:CPengguna]) {
//                [((GeneralTalkCell*)cell).userButton setColor:CTagPengguna];
//            }
//            else {
//                [((GeneralTalkCell*)cell).userButton setColor:-1];//-1 is set to empty string
//            }
            [((GeneralTalkCell*)cell).userButton setLabelBackground:list.talk_user_label];
            
            NSString *followStatus;
            if(!list.talk_follow_status) {
                followStatus = TKPD_TALK_FOLLOW;
            } else {
                followStatus = TKPD_TALK_UNFOLLOW;
            }
            [((GeneralTalkCell*)cell).unfollowButton setTitle:followStatus forState:UIControlStateNormal];
            
            if(![list.talk_own isEqualToString:@"1"] && [_userManager isLogin]) {
                ((GeneralTalkCell*)cell).unfollowButton.hidden = NO;
            } else {
                ((GeneralTalkCell*)cell).unfollowButton.hidden = YES;
                ((GeneralTalkCell*)cell).buttonsDividers.hidden = YES;
                
                ((GeneralTalkCell*)cell).commentbutton.translatesAutoresizingMaskIntoConstraints = YES;
                CGRect newFrame = ((GeneralTalkCell*)cell).commentbutton.frame;
                newFrame.origin.x = ([UIScreen mainScreen].bounds.size.width - ((GeneralTalkCell*)cell).commentbutton.frame.size.width) / 2-10;
                ((GeneralTalkCell*)cell).commentbutton.frame = newFrame;
            }
            
            
            if([_userManager isLogin]) {
                ((GeneralTalkCell*)cell).moreActionButton.hidden = NO;
            } else {
                ((GeneralTalkCell*)cell).moreActionButton.hidden = YES;
            }
            
            if ([list.talk_message length] > 30) {
                NSRange stringRange = {0, MIN([list.talk_message length], 30)};
                stringRange = [list.talk_message rangeOfComposedCharacterSequencesForRange:stringRange];
                ((GeneralTalkCell*)cell).commentlabel.text = [NSString stringWithFormat:@"%@...", [list.talk_message substringWithRange:stringRange]];
            } else {
                ((GeneralTalkCell*)cell).commentlabel.text = list.talk_message;
            }
            

            NSURLRequest *userImageRequest = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:list.talk_user_image] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:kTKPDREQUEST_TIMEOUTINTERVAL];
            UIImageView *userImageView = ((GeneralTalkCell*)cell).thumb;
            userImageView.image = nil;
            [userImageView setImageWithURLRequest:userImageRequest placeholderImage:[UIImage imageNamed:@"default-boy.png"] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
                [userImageView setImage:image];
                userImageView.layer.cornerRadius = userImageView.frame.size.width/2;
#pragma clang diagnostic pop
            } failure:nil];
            
            NSURLRequest *productImageRequest = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:list.talk_product_image] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:kTKPDREQUEST_TIMEOUTINTERVAL];
            UIImageView *productImageView = ((GeneralTalkCell*)cell).productImageView;
            productImageView.image = nil;
            [productImageView setImageWithURLRequest:productImageRequest placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
                [productImageView setImage:image];
                productImageView.layer.cornerRadius = productImageView.frame.size.width/2;
#pragma clang diagnostic pop
            } failure:nil];
            
        }
        
        
        
        return cell;
        
    } else {
        static NSString *cellIdentifier = kTKPDDETAIL_STANDARDTABLEVIEWCELLIDENTIFIER;
        
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        cell.textLabel.text = kTKPDDETAIL_NODATACELLTITLE;
        cell.detailTextLabel.text = kTKPDDETAIL_NODATACELLDESCS;
    }
    
    return cell;
}

#pragma mark - Request + Mapping

-(void)cancel
{
    [_request cancel];
    _request = nil;
    [_objectManager.operationQueue cancelAllOperations];
    _objectManager = nil;
}

- (void)configureRestKit
{
    // initialize RestKit
    _objectManager =  [RKObjectManager sharedClient];
    
    // setup object mappings
    RKObjectMapping *statusMapping = [RKObjectMapping mappingForClass:[Talk class]];
    [statusMapping addAttributeMappingsFromDictionary:@{kTKPD_APISTATUSKEY:kTKPD_APISTATUSKEY,
                                                        kTKPD_APISERVERPROCESSTIMEKEY:kTKPD_APISERVERPROCESSTIMEKEY
                                                        }];
    
    RKObjectMapping *resultMapping = [RKObjectMapping mappingForClass:[TalkResult class]];
    
    RKObjectMapping *listMapping = [RKObjectMapping mappingForClass:[TalkList class]];
    [listMapping addAttributeMappingsFromArray:@[TKPD_TALK_TOTAL_COMMENT,
                                                 TKPD_TALK_ID,
                                                 TKPD_TALK_CREATE_TIME,
                                                 TKPD_TALK_MESSAGE,
                                                 TKPD_TALK_FOLLOW_STATUS,
                                                 TKPD_TALK_PRODUCT_NAME,
                                                 TKPD_TALK_PRODUCT_IMAGE,
                                                 TKPD_TALK_PRODUCT_ID,
                                                 TKPD_TALK_OWN,
                                                 TKPD_TALK_USER_ID,
                                                 TKPD_TALK_USER_NAME,
                                                 TKPD_TALK_SHOP_ID,
                                                 TKPD_TALK_USER_IMG,
                                                 TKPD_TALK_PRODUCT_STATUS,
                                                 TKPD_TALK_USER_LABEL,
                                                 TKPD_TALK_USER_LABEL_ID
                                                 ]];
    
    RKObjectMapping *reputationDetailMapping = [RKObjectMapping mappingForClass:[ReputationDetail class]];
    [reputationDetailMapping addAttributeMappingsFromArray:@[CPositivePercentage,
                                                             CNoReputation,
                                                             CNegative,
                                                             CPositif,
                                                             CNeutral]];
    
    RKObjectMapping *pagingMapping = [RKObjectMapping mappingForClass:[Paging class]];
    [pagingMapping addAttributeMappingsFromDictionary:@{kTKPDDETAIL_APIURINEXTKEY:kTKPDDETAIL_APIURINEXTKEY}];
    
    // Relationship Mapping
    [listMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:CTalkUserReputation toKeyPath:CTalkUserReputation withMapping:reputationDetailMapping]];
    [statusMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:kTKPD_APIRESULTKEY toKeyPath:kTKPD_APIRESULTKEY withMapping:resultMapping]];
    
    RKRelationshipMapping *listRel = [RKRelationshipMapping relationshipMappingFromKeyPath:kTKPD_APILISTKEY toKeyPath:kTKPD_APILISTKEY withMapping:listMapping];
    [resultMapping addPropertyMapping:listRel];
    
    RKRelationshipMapping *pageRel = [RKRelationshipMapping relationshipMappingFromKeyPath:kTKPDDETAIL_APIPAGINGKEY toKeyPath:kTKPDDETAIL_APIPAGINGKEY withMapping:pagingMapping];
    [resultMapping addPropertyMapping:pageRel];
    
    // register mappings with the provider using a response descriptor
    RKResponseDescriptor *responseDescriptorStatus = [RKResponseDescriptor responseDescriptorWithMapping:statusMapping
                                                                                                  method:RKRequestMethodPOST
                                                                                             pathPattern:kTKPDDETAILSHOP_APIPATH
                                                                                                 keyPath:@""
                                                                                             statusCodes:kTkpdIndexSetStatusCodeOK];
    
    [_objectManager addResponseDescriptor:responseDescriptorStatus];
}



- (void)loadData
{
    if (_request.isExecuting) return;
    
    _requestCount++;
    
    NSDictionary *param = @{kTKPDDETAIL_APIACTIONKEY : kTKPDDETAIL_APIGETSHOPTALKKEY,
                            kTKPDDETAIL_APISHOPIDKEY : [_data objectForKey:kTKPDDETAIL_APISHOPIDKEY]?:@(0),
                            @"shop_domain" : [_data objectForKey:@"shop_domain"]?:@"",
                            @"page" : @(_page),
                            @"per_page" : @(5)
                            };
    
    
    _request = [_objectManager appropriateObjectRequestOperationWithObject:self
                                                                    method:RKRequestMethodPOST
                                                                      path:kTKPDDETAILSHOP_APIPATH
                                                                parameters:[param encrypt]];
    
    if (!_isrefreshview) {
        _table.tableFooterView = _footer;
        [_act startAnimating];
    }
    
    [_request setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        [_timer invalidate];
        _timer = nil;
        [_act stopAnimating];
        self.table.hidden = NO;
        _isrefreshview = NO;
        [_refreshControl endRefreshing];
        [self requestSuccess:mappingResult withOperation:operation];
        
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        [_timer invalidate];
        _timer = nil;
        [_act stopAnimating];
        _table.hidden = NO;
        _isrefreshview = NO;
        [_refreshControl endRefreshing];
        [self requestFailure:error];
    }];
    [_operationQueue addOperation:_request];
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:kTKPDREQUEST_TIMEOUTINTERVAL
                                              target:self
                                            selector:@selector(requestTimeout)
                                            userInfo:nil
                                             repeats:NO];
    
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    
}

-(void)requestSuccess:(id)object withOperation:(RKObjectRequestOperation *)operation
{
    NSDictionary *result = ((RKMappingResult*)object).dictionary;
    id stats = [result objectForKey:@""];
    _talk = stats;
    BOOL status = [_talk.status isEqualToString:kTKPDREQUEST_OKSTATUS];
    
    if (status) {
        [self requestProcess:object];
    }
}

-(void)requestFailure:(id)object
{

}

-(void)requestProcess:(id)object
{
    if (object) {
        if ([object isKindOfClass:[RKMappingResult class]]) {
            NSDictionary *result = ((RKMappingResult*)object).dictionary;
            
            id stats = [result objectForKey:@""];
            
            _talk = stats;
            
            BOOL status = [_talk.status isEqualToString:kTKPDREQUEST_OKSTATUS];
            
            if (status) {
                
                NSArray *list = _talk.result.list;
                
                [_list addObjectsFromArray:list];
                
                _uriNext =  _talk.result.paging.uri_next;
                NSURL *url = [NSURL URLWithString:_uriNext];
                NSArray* querry = [[url query] componentsSeparatedByString: @"&"];
                
                NSMutableDictionary *queries = [NSMutableDictionary new];
                [queries removeAllObjects];
                for (NSString *keyValuePair in querry)
                {
                    NSArray *pairComponents = [keyValuePair componentsSeparatedByString:@"="];
                    NSString *key = [pairComponents objectAtIndex:0];
                    NSString *value = [pairComponents objectAtIndex:1];
                    
                    [queries setObject:value forKey:key];
                }
                
                _page = [[queries objectForKey:kTKPDDETAIL_APIPAGEKEY] integerValue];
                NSLog(@"next page shop talk : %zd",_page);
                
                _isNoData = NO;
                
                [self.table reloadData];
                if (_list.count == 0) {
                    _act.hidden = YES;
                    _table.tableFooterView = _noResult;
                }
            }
        }else{
            
            [self cancel];
            NSLog(@" REQUEST FAILURE ERROR %@", [(NSError*)object description]);
            if ([(NSError*)object code] == NSURLErrorCancelled) {
                if (_requestCount<kTKPDREQUESTCOUNTMAX) {
                    NSLog(@" ==== REQUESTCOUNT %zd =====",_requestCount);
                    //_table.tableFooterView = _footer;
                    //[_act startAnimating];
                    [self performSelector:@selector(configureRestKit) withObject:nil afterDelay:kTKPDREQUEST_DELAYINTERVAL];
                    [self performSelector:@selector(loadData) withObject:nil afterDelay:kTKPDREQUEST_DELAYINTERVAL];
                }
                else
                {
                    [_act stopAnimating];
                    self.table.tableFooterView = nil;
                }
            }
            else
            {
                [_act stopAnimating];
                self.table.tableFooterView = nil;
            }
        }
    }
}

-(void)requestTimeout
{
    [self cancel];
}




#pragma mark - General Talk Delegate
- (void)actionSmile:(id)sender {
    TalkList *list = _list[((UIView *) sender).tag];
    
    if(! (list.talk_user_reputation.no_reputation!=nil && [list.talk_user_reputation.no_reputation isEqualToString:@"1"])) {
        int paddingRightLeftContent = 10;
        UIView *viewContentPopUp = [[UIView alloc] initWithFrame:CGRectMake(0, 0, (CWidthItemPopUp*3)+paddingRightLeftContent, CHeightItemPopUp)];
        SmileyAndMedal *tempSmileyAndMedal = [SmileyAndMedal new];
        [tempSmileyAndMedal showPopUpSmiley:viewContentPopUp andPadding:paddingRightLeftContent withReputationNetral:list.talk_user_reputation.neutral withRepSmile:list.talk_user_reputation.positive withRepSad:list.talk_user_reputation.negative withDelegate:self];
        
        //Init pop up
        cmPopTitpView = [[CMPopTipView alloc] initWithCustomView:viewContentPopUp];
        cmPopTitpView.delegate = self;
        cmPopTitpView.backgroundColor = [UIColor whiteColor];
        cmPopTitpView.animation = CMPopTipAnimationSlide;
        cmPopTitpView.dismissTapAnywhere = YES;
        cmPopTitpView.leftPopUp = YES;
        
        UIButton *button = (UIButton *)sender;
        [cmPopTitpView presentPointingAtView:button inView:self.view animated:YES];
    }
}

- (void)GeneralTalkCell:(UITableViewCell *)cell withindexpath:(NSIndexPath *)indexpath {
    ProductTalkDetailViewController *vc = [ProductTalkDetailViewController new];
    NSInteger row = indexpath.row;
    TalkList *list = _list[row];
    vc.data = @{
                TKPD_TALK_REPUTATION_PERCENTAGE:list.talk_user_reputation,
                TKPD_TALK_MESSAGE:list.talk_message?:@0,
                TKPD_TALK_USER_IMG:list.talk_user_image?:@0,
                TKPD_TALK_CREATE_TIME:list.talk_create_time?:@0,
                TKPD_TALK_USER_NAME:list.talk_user_name?:@0,
                TKPD_TALK_ID:list.talk_id?:@0,
                TKPD_TALK_USER_ID:[NSString stringWithFormat:@"%d", (int)list.talk_user_id],
                TKPD_TALK_TOTAL_COMMENT : list.talk_total_comment?:@0,
                kTKPDDETAILPRODUCT_APIPRODUCTIDKEY : list.talk_product_id,
                TKPD_TALK_SHOP_ID:list.talk_shop_id?:@0,
                TKPD_TALK_PRODUCT_IMAGE:list.talk_product_image,
                TKPD_TALK_PRODUCT_NAME:list.talk_product_name,
                kTKPDDETAIL_DATAINDEXKEY : @(row)?:@0,
                TKPD_TALK_PRODUCT_STATUS:list.talk_product_status?:@"",
                TKPD_TALK_USER_LABEL:list.talk_user_label?:@""
                };
    [self.navigationController pushViewController:vc animated:YES];
    
}

#pragma mark - action
-(void) configureUnfollowRestkit {
    _objectUnfollowmanager =  [RKObjectManager sharedClient];
    
    // setup object mappings
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
                                                                                             pathPattern:TKPD_MESSAGE_TALK_ACTION keyPath:@"" statusCodes:kTkpdIndexSetStatusCodeOK];
    
    [_objectUnfollowmanager addResponseDescriptor:responseDescriptorStatus];
}

- (void)configureDeleteRestkit {
    _objectDeletemanager =  [RKObjectManager sharedClient];
    
    // setup object mappings
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
    RKResponseDescriptor *responseDescriptorStatus = [RKResponseDescriptor responseDescriptorWithMapping:statusMapping
                                                                                                  method:RKRequestMethodPOST
                                                                                             pathPattern:TKPD_MESSAGE_TALK_ACTION
                                                                                                 keyPath:@""
                                                                                             statusCodes:kTkpdIndexSetStatusCodeOK];
    
    [_objectDeletemanager addResponseDescriptor:responseDescriptorStatus];
}

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

- (void)unfollowTalk:(UITableViewCell *)cell withindexpath:(NSIndexPath *)indexpath withButton:(UIButton *)buttonUnfollow {
    [self configureUnfollowRestkit];
    [self followAnimateZoomOut:buttonUnfollow];
    
    TalkList *list = _list[indexpath.row];
    if (_requestUnfollow.isExecuting) return;
    
    NSDictionary* param = @{
                            kTKPDDETAIL_ACTIONKEY : TKPD_FOLLOW_TALK_ACTION,
                            kTKPDDETAILPRODUCT_APIPRODUCTIDKEY : list.talk_product_id,
                            TKPD_TALK_ID:list.talk_id?:@0,
                            };
    
    _requestUnfollowCount ++;
    _requestUnfollow = [_objectUnfollowmanager appropriateObjectRequestOperationWithObject:self method:RKRequestMethodPOST path:TKPD_MESSAGE_TALK_ACTION parameters:[param encrypt]];
    
    [_requestUnfollow setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        
        
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        
    }];
    
    [_operationUnfollowQueue addOperation:_requestUnfollow];
    
}

- (void)deleteTalk:(UITableViewCell *)cell withindexpath:(NSIndexPath *)indexpath {
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:PROMPT_DELETE_TALK
                          message:PROMPT_DELETE_TALK_MESSAGE
                          delegate:self
                          cancelButtonTitle:BUTTON_CANCEL
                          otherButtonTitles:nil];
    
    [alert addButtonWithTitle:BUTTON_OK];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    //delete talk
    if(buttonIndex == 1) {
        TalkList *list = _list[buttonIndex];
        [_list removeObjectAtIndex:buttonIndex];
        [_table reloadData];
        [self configureDeleteRestkit];
        
        if (_requestDelete.isExecuting) return;
        
        NSDictionary* param = @{
                                kTKPDDETAIL_ACTIONKEY : TKPD_DELETE_TALK_ACTION,
                                kTKPDDETAILPRODUCT_APIPRODUCTIDKEY : list.talk_product_id,
                                TKPD_TALK_ID:list.talk_id?:@0,
                                kTKPDDETAILSHOP_APISHOPID : list.talk_shop_id
                                };
        
        _requestDeleteCount ++;
        _requestDelete = [_objectDeletemanager appropriateObjectRequestOperationWithObject:self
                                                                                    method:RKRequestMethodPOST
                                                                                      path:TKPD_MESSAGE_TALK_ACTION
                                                                                parameters:[param encrypt]];
        
        [_requestDelete setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
            
            
        } failure:^(RKObjectRequestOperation *operation, NSError *error) {
            
        }];
        
        [_operationDeleteQueue addOperation:_requestDelete];
        
    }
}

- (void)failToDelete:(id)talk {
    
}


- (id)navigationController:(UITableViewCell *)cell withindexpath:(NSIndexPath *)indexpath
{
    return self;
}

#pragma mark - Refresh View
-(void)refreshView:(UIRefreshControl*)refresh
{
    /** clear object **/
    [self cancel];
    _requestCount = 0;
    [_list removeAllObjects];
    _page = 1;
    _isrefreshview = YES;
    
    [_table reloadData];
    /** request data **/
    [self configureRestKit];
    [self loadData];
}

#pragma mark - Notification Handler
-(void) updateTotalComment:(NSNotification*)notification{
    NSDictionary *userinfo = notification.userInfo;
    NSInteger index = [[userinfo objectForKey:kTKPDDETAIL_DATAINDEXKEY]integerValue];
    
    TalkList *list = _list[index];
    list.talk_total_comment = [NSString stringWithFormat:@"%@",[userinfo objectForKey:TKPD_TALK_TOTAL_COMMENT]];
    [_table reloadData];
}


#pragma mark - Memory Management
-(void)dealloc{
    NSLog(@"%@ : %@",[self class], NSStringFromSelector(_cmd));
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSLog(@"Content offset container %f", scrollView.contentOffset.y);

    
    BOOL isFakeStickyVisible = scrollView.contentOffset.y > (305 - _fakeStickyTab.frame.size.height);
    
    NSLog(@"Sticky Tab %hhd", isFakeStickyVisible);
    //    NSLog(@"Range : %f", (_header.frame.size.height - _stickyTab.frame.size.height));
    
    if(isFakeStickyVisible) {
        _fakeStickyTab.hidden = NO;
    } else {
        _fakeStickyTab.hidden = YES;
    }
    
    [self determineOtherScrollView:scrollView];
}

- (void)determineOtherScrollView:(UIScrollView *)scrollView {
    NSDictionary *userInfo = @{@"y_position" : [NSNumber numberWithFloat:scrollView.contentOffset.y]};

    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateReviewHeaderPosition" object:nil userInfo:userInfo];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateNotesHeaderPosition" object:nil userInfo:userInfo];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateProductHeaderPosition" object:nil userInfo:userInfo];

}


- (void)updateTalkHeaderPosition:(NSNotification *)notification
{
    id userinfo = notification.userInfo;
    float ypos;
    if([[userinfo objectForKey:@"y_position"] floatValue] < 0) {
        ypos = 0;
    } else {
        ypos = [[userinfo objectForKey:@"y_position"] floatValue];
    }
    CGPoint cgpoint = CGPointMake(0, ypos);
    NSLog(@"Child Position %f",[[userinfo objectForKey:@"yposition"] floatValue]);
    
//    if(ypos < _header.frame.size.height - _stickyTab.frame.size.height) {
        _table.contentOffset = cgpoint;
//    }
}

#pragma mark - Shop Header Delegate

- (void)didLoadImage:(UIImage *)image
{
    //    _navigationImageView.image = [image applyLightEffect];
}

- (void)didReceiveShop:(Shop *)shop
{
    _shop = shop;
}

- (id)didReceiveNavigationController {
    return self;
}


/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

#pragma mark - PopUp
- (void)dismissAllPopTipViews
{
    [cmPopTitpView dismissAnimated:YES];
    cmPopTitpView = nil;
}

- (void)popTipViewWasDismissedByUser:(CMPopTipView *)popTipView
{
    [self dismissAllPopTipViews];
}
@end
