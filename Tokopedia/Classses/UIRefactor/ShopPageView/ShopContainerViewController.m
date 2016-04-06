//
//  ContainerViewController.m
//  PageViewControllerExample
//
//  Created by Mani Shankar on 29/08/14.
//  Copyright (c) 2014 makemegeek. All rights reserved.
//
#import "CMPopTipView.h"
#import "DetailProductViewController.h"
#import "LoginViewController.h"
#import "ShopPageHeader.h"
#import "ShopContainerViewController.h"
#import "ShopTalkPageViewController.h"
#import "ShopProductPageViewController.h"
#import "ShopReviewPageViewController.h"
#import "ShopNotesPageViewController.h"
#import "ShopInfoViewController.h"
#import "SendMessageViewController.h"
#import "ShopSettingViewController.h"
#import "ShopBadgeLevel.h"
#import "ReputationDetail.h"
#import "ResponseSpeed.h"
#import "Rating.h"
#import "TTTAttributedLabel.h"
#import "ProductAddEditViewController.h"

#import "sortfiltershare.h"
#import "detail.h"
#import "string_product.h"

#import "ShopBadgeLevel.h"
#import "FavoriteShopAction.h"
#import "UserAuthentificationManager.h"
#import "ShopPageRequest.h"

@interface ShopContainerViewController () <UIScrollViewDelegate, LoginViewDelegate, UIPageViewControllerDelegate, CMPopTipViewDelegate> {
    BOOL _isNoData, isDoingFavorite, isDoingMessage;
    BOOL _isRefreshView;
    
    NSInteger _requestFavoriteCount;
    
    __weak RKObjectManager *_objectFavoriteManager;
    __weak RKManagedObjectRequestOperation *_requestFavorite;
    NSOperationQueue *_operationFavoriteQueue;
    NSTimer *_timerFavorite;
    
    CMPopTipView *cmPopTitpView;
    NSDictionary *_auth;
    UIBarButtonItem *_favoriteBarButton;
    UIBarButtonItem *_unfavoriteBarButton;
    UIBarButtonItem *_infoBarButton;
    UIBarButtonItem *_addProductBarButton;
    UIBarButtonItem *_settingBarButton;
    UIBarButtonItem *_messageBarButton;
    UserAuthentificationManager *_userManager;
    
    UIBarButtonItem *_fixedSpace;
    ShopPageRequest *shopPageRequest;
}

@property (strong, nonatomic) ShopProductPageViewController *shopProductViewController;
@property (strong, nonatomic) ShopTalkPageViewController *shopTalkViewController;
@property (strong, nonatomic) ShopReviewPageViewController *shopReviewViewController;
@property (strong, nonatomic) ShopNotesPageViewController *shopNotesViewController;
@property (strong, nonatomic) IBOutlet UIView *containerView;

@property (strong, nonatomic) IBOutlet UIScrollView *containerScrollView;
@property (strong, nonatomic) IBOutlet UIView *contentView;

@property (strong, nonatomic) IBOutlet UILabel *productLabel;
@property (strong, nonatomic) IBOutlet UILabel *talkLabel;
@property (strong, nonatomic) IBOutlet UILabel *reviewLabel;
@property (strong, nonatomic) IBOutlet UILabel *notesLabel;

@end




@implementation ShopContainerViewController

@synthesize data = _data;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (void)initBarButton {
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                      style:UIBarButtonItemStyleBordered
                                                                     target:self
                                                                     action:@selector(tap:)];
    barButtonItem.tag = 1;
    [self.navigationItem setBackBarButtonItem:barButtonItem];
    
    _infoBarButton = [self createBarButton:CGRectMake(0,0,22,22) withImage:[UIImage imageNamed:@"icon_shop_info@2x.png"] withAction:@selector(infoTap:)];
    _addProductBarButton = [self createBarButton:CGRectMake(22,0,22,22) withImage:[UIImage imageNamed:@"icon_shop_addproduct@2x.png"] withAction:@selector(addProductTap:)];
    _settingBarButton = [self createBarButton:CGRectMake(44,0,22,22) withImage:[UIImage imageNamed:@"icon_shop_setting@2x.png"] withAction:@selector(settingTap:)];
    
    _messageBarButton = [self createBarButton:CGRectMake(22,0,22,22) withImage:[UIImage imageNamed:@"icon_shop_message@2x.png"] withAction:@selector(messageTap:)];

    _favoriteBarButton = [self createBarButton:CGRectMake(44,0,22,22) withImage:[UIImage imageNamed:@"icon_love_active@2x.png"] withAction:@selector(favoriteTap:)];

    _unfavoriteBarButton = [self createBarButton:CGRectMake(44,0,22,22) withImage:[UIImage imageNamed:@"icon_love_white@2x.png"] withAction:@selector(unfavoriteTap:)];
    _fixedSpace = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
    _fixedSpace.width = 15;
    
    _unfavoriteBarButton.enabled = NO;
    _favoriteBarButton.enabled = NO;
    _messageBarButton.enabled = NO;
    _settingBarButton.enabled = NO;
    _addProductBarButton.enabled = NO;
    _infoBarButton.enabled = NO;
}

- (UIBarButtonItem*)createBarButton:(CGRect)frame withImage:(UIImage*)image withAction:(SEL)action {
    UIImageView *infoImageView = [[UIImageView alloc] initWithImage:image];
    infoImageView.frame = frame;
    infoImageView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:action];
    [infoImageView addGestureRecognizer:tapGesture];
    UIBarButtonItem *infoBarButton = [[UIBarButtonItem alloc] initWithCustomView:infoImageView];
    
    return infoBarButton;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initNotificationCenter];
    [[UIBarButtonItem appearance] setBackButtonTitlePositionAdjustment:UIOffsetMake(0, -60) forBarMetrics:UIBarMetricsDefault];

    // Do any additional setup after loading the view from its nib.
    
    _isNoData = YES;
    _isRefreshView = NO;
    
    shopPageRequest = [ShopPageRequest new];
    
    _userManager = [UserAuthentificationManager new];
    
    self.pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    
    _pageController.dataSource = self;
    _pageController.delegate = self;
    
    _shopProductViewController = [ShopProductPageViewController new];
    _shopProductViewController.data = _data;
    
    _shopTalkViewController = [ShopTalkPageViewController new];
    _shopTalkViewController.data = _data;
    
    _shopReviewViewController = [ShopReviewPageViewController new];
    _shopReviewViewController.data = _data;
    
    _shopNotesViewController = [ShopNotesPageViewController new];
    _shopNotesViewController.data = _data;
    
    
    NSArray *viewControllers = [NSArray arrayWithObject:_shopProductViewController];
    [self.pageController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward
                                   animated:NO
                                 completion:nil];
    
    [self addChildViewController:self.pageController];
    [self.view addSubview:[self.pageController view]];
    
    NSArray *subviews = self.pageController.view.subviews;
    UIPageControl *thisControl = nil;
    for (int i=0; i<[subviews count]; i++) {
        if ([[subviews objectAtIndex:i] isKindOfClass:[UIPageControl class]]) {
            thisControl = (UIPageControl *)[subviews objectAtIndex:i];
        }
    }
    
    thisControl.hidden = true;
    self.pageController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height+40);
    
    [self requestShopInfo];
    [self.pageController didMoveToParentViewController:self];
    [self setScrollEnabled:NO forPageViewController:_pageController];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self initBarButton];
}

#pragma  - UIPageViewController Methods
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    if ([viewController isKindOfClass:[ShopProductPageViewController class]]) {
        return nil;
    }
    if ([viewController isKindOfClass:[ShopTalkPageViewController class]]) {
        return _shopProductViewController;
    }
    else if ([viewController isKindOfClass:[ShopReviewPageViewController class]]) {
        return _shopTalkViewController;
    }
    else if ([viewController isKindOfClass:[ShopNotesPageViewController class]]) {
        return _shopReviewViewController;
    }
    
    return nil;
    
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    if ([viewController isKindOfClass:[ShopProductPageViewController class]]) {
        return _shopTalkViewController;
    }
    
    else if ([viewController isKindOfClass:[ShopTalkPageViewController class]]) {
        return _shopReviewViewController;
    }
    else if ([viewController isKindOfClass:[ShopReviewPageViewController class]]) {
        return _shopNotesViewController;
    }
    else if ([viewController isKindOfClass:[ShopNotesPageViewController class]]) {
        return nil;
    }
    
    return nil;
    
}


- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController {
    return 3;
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController {
    return 0;
}


#pragma mark - Init Notification
- (void)initNotificationCenter {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver:self selector:@selector(showNavigationShopTitle:) name:@"showNavigationShopTitle" object:nil];
    [nc addObserver:self selector:@selector(hideNavigationShopTitle:) name:@"hideNavigationShopTitle" object:nil];
    [nc addObserver:self selector:@selector(reloadShop) name:kTKPD_EDITSHOPPOSTNOTIFICATIONNAMEKEY object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidLogin:) name:TKPDUserDidLoginNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidLogout:) name:kTKPDACTIVATION_DIDAPPLICATIONLOGGEDOUTNOTIFICATION object:nil];

    
}

- (void)updateHeaderShopPage
{
    [_shopNotesViewController.shopPageHeader setHeaderShopPage:_shop];
    [_shopProductViewController.shopPageHeader setHeaderShopPage:_shop];
    [_shopReviewViewController.shopPageHeader setHeaderShopPage:_shop];
    [_shopTalkViewController.shopPageHeader setHeaderShopPage:_shop];
}

-(void)setScrollEnabled:(BOOL)enabled forPageViewController:(UIPageViewController*)pageViewController{
    for(UIView* view in pageViewController.view.subviews){
        if([view isKindOfClass:[UIScrollView class]]){
            UIScrollView* scrollView=(UIScrollView*)view;
            [scrollView setScrollEnabled:enabled];
            return;
        }
    }
}

#pragma mark - Request And Mapping
-(void)requestShopInfo{
    NSString *shopId = [_data objectForKey:kTKPDDETAIL_APISHOPIDKEY]?:@"";
    NSString *shopDomain = [_data objectForKey:@"shop_domain"]?:@"";
    [shopPageRequest requestForShopPageContainerWithShopId:shopId shopDomain:shopDomain onSuccess:^(Shop *shop) {
        _shop = shop;
        if ([_userManager isMyShopWithShopId:[_data objectForKey:kTKPDDETAIL_APISHOPIDKEY]]) {
            self.navigationItem.rightBarButtonItems = @[_settingBarButton,_fixedSpace, _addProductBarButton,_fixedSpace, _infoBarButton];
            _addProductBarButton.enabled = YES;
            _settingBarButton.enabled = YES;
        } else {
            if(_shop.result.info.shop_already_favorited == 1) {
                self.navigationItem.rightBarButtonItems = @[_favoriteBarButton,_fixedSpace, _messageBarButton,_fixedSpace, _infoBarButton];
                _favoriteBarButton.enabled = YES;
                _unfavoriteBarButton.enabled = YES;
                _messageBarButton.enabled = YES;
                
                if(isDoingFavorite) {
                    isDoingFavorite = !isDoingFavorite;
                    
                    [self favoriteTap:nil];
                }
                else if(isDoingMessage) {
                    isDoingMessage = !isDoingMessage;
                    [self messageTap:nil];
                }
            } else {
                self.navigationItem.rightBarButtonItems = @[_unfavoriteBarButton,_fixedSpace, _messageBarButton, _fixedSpace, _infoBarButton];
                _messageBarButton.enabled = YES;
                _unfavoriteBarButton.enabled = YES;
                _favoriteBarButton.enabled = YES;
                
                if(isDoingFavorite) {
                    isDoingFavorite = !isDoingFavorite;
                    [self unfavoriteTap:nil];
                }
                else if(isDoingMessage) {
                    isDoingMessage = !isDoingMessage;
                    [self messageTap:nil];
                }
            }
        }
        _infoBarButton.enabled = YES;
        
        TKPDSecureStorage *secureStorage = [TKPDSecureStorage standardKeyChains];
        [secureStorage setKeychainWithValue:_shop.result.info.shop_has_terms?:@"" withKey:@"shop_has_terms"];
        [[NSNotificationCenter defaultCenter] postNotificationName:DID_UPDATE_SHOP_HAS_TERM_NOTIFICATION_NAME object:nil userInfo:nil];
        _isNoData = NO;
        [self updateHeaderShopPage];
    } onFailure:^(NSError *error) {
        
    }];
}

#pragma mark - Memory Management
-(void)dealloc{
    NSLog(@"%@ : %@",[self class], NSStringFromSelector(_cmd));
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

#pragma mark - Notification Action

- (void)checkIsLogin {
    if(_auth) {
        
    }
}
- (void)showNavigationShopTitle:(NSNotification *)notification
{
    [UIView animateWithDuration:0.2 animations:^(void) {
        self.title = _shop.result.info.shop_name;
    } completion:^(BOOL finished) {
        
    }];
    
}

- (void)hideNavigationShopTitle:(NSNotification *)notification
{
    [UIView animateWithDuration:0.2 animations:^(void) {
        self.title = @"";
    } completion:^(BOOL finished) {
        
    }];
    
}

#pragma mark - CMPopTipView Delegate
- (void)popTipViewWasDismissedByUser:(CMPopTipView *)popTipView
{
    [self dismissAllPopTipViews];
}


#pragma mark - Method
- (void)setPropertyLabelDesc:(TTTAttributedLabel *)lblDesc {
    lblDesc.backgroundColor = [UIColor clearColor];
    lblDesc.textAlignment = NSTextAlignmentLeft;
    lblDesc.font = [UIFont fontWithName:@"GothamBook" size:13.0f];
    lblDesc.textColor = [UIColor colorWithRed:117/255.0f green:117/255.0f blue:117/255.0f alpha:1.0f];
    lblDesc.lineBreakMode = NSLineBreakByWordWrapping;
    lblDesc.numberOfLines = 0;
}

- (void)dismissAllPopTipViews
{
    [cmPopTitpView dismissAnimated:YES];
    cmPopTitpView = nil;
}

- (void)initPopUp:(NSString *)strText withSender:(id)sender withRangeDesc:(NSRange)range
{
    UILabel *lblShow = [[UILabel alloc] init];
    CGFloat fontSize = 13;
    UIFont *boldFont = [UIFont boldSystemFontOfSize:fontSize];
    UIFont *regularFont = [UIFont systemFontOfSize:fontSize];
    UIColor *foregroundColor = [UIColor whiteColor];
    
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys: boldFont, NSFontAttributeName, foregroundColor, NSForegroundColorAttributeName, nil];
    NSDictionary *subAttrs = [NSDictionary dictionaryWithObjectsAndKeys:regularFont, NSFontAttributeName, foregroundColor, NSForegroundColorAttributeName, nil];
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:strText attributes:attrs];
    [attributedText setAttributes:subAttrs range:range];
    [lblShow setAttributedText:attributedText];
    
    
    CGSize tempSize = [lblShow sizeThatFits:CGSizeMake(self.view.bounds.size.width-40, 9999)];
    lblShow.frame = CGRectMake(0, 0, tempSize.width, tempSize.height);
    lblShow.backgroundColor = [UIColor clearColor];
    
    //Init pop up
    cmPopTitpView = [[CMPopTipView alloc] initWithCustomView:lblShow];
    cmPopTitpView.delegate = self;
    cmPopTitpView.backgroundColor = [UIColor blackColor];
    cmPopTitpView.animation = CMPopTipAnimationSlide;
    cmPopTitpView.dismissTapAnywhere = YES;
    
    UIButton *button = (UIButton *)sender;
    [cmPopTitpView presentPointingAtView:button inView:self.view animated:YES];
}


- (void)showPopUp:(NSString *)strText withSender:(id)sender {
    [self initPopUp:strText withSender:sender withRangeDesc:NSMakeRange(strText.length-4, 4)];
}

- (UIViewController *)getActiveViewController {
    return [_pageController.viewControllers lastObject];
}

- (void)setFavoriteRightButtonItem
{
    StickyAlertView *stickyAlertView;
    if([self.navigationItem.rightBarButtonItems firstObject] == _favoriteBarButton) {
        self.navigationItem.rightBarButtonItems = @[_unfavoriteBarButton, _fixedSpace, _messageBarButton, _fixedSpace, _infoBarButton];
        stickyAlertView = [[StickyAlertView alloc] initWithSuccessMessages:@[CStringSuccessUnFavoriteShop] delegate:self];
    }
    else {
        self.navigationItem.rightBarButtonItems = @[_favoriteBarButton,_fixedSpace, _messageBarButton,_fixedSpace, _infoBarButton];
        stickyAlertView = [[StickyAlertView alloc] initWithSuccessMessages:@[CStringSuccessFavoriteShop] delegate:self];
    }
    
    [stickyAlertView show];
}


#pragma mark - Tap Action
- (IBAction)infoTap:(id)sender {
    if (_shop) {
        ShopInfoViewController *vc = [[ShopInfoViewController alloc] init];
        vc.data = @{kTKPDDETAIL_DATAINFOSHOPSKEY : _shop,
                    kTKPD_AUTHKEY:[_data objectForKey:kTKPD_AUTHKEY] && [_data objectForKey:kTKPD_AUTHKEY]!=[NSNull null]?[_data objectForKey:kTKPD_AUTHKEY]:@{}};
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (IBAction)messageTap:(id)sender {
    if([_userManager isLogin]) {
        SendMessageViewController *messageController = [SendMessageViewController new];
        messageController.data = @{
                                   kTKPDDETAIL_APISHOPIDKEY:@([[_data objectForKey:kTKPDDETAIL_APISHOPIDKEY]integerValue]?:0),
                                   kTKPDDETAIL_APISHOPNAMEKEY:_shop.result.info.shop_name
                                   };
        [self.navigationController pushViewController:messageController animated:YES];
    } else {
        UINavigationController *navigationController = [[UINavigationController alloc] init];
        navigationController.navigationBar.backgroundColor = [UIColor colorWithCGColor:[UIColor colorWithRed:18.0/255.0 green:199.0/255.0 blue:0.0/255.0 alpha:1].CGColor];
        navigationController.navigationBar.translucent = NO;
        navigationController.navigationBar.tintColor = [UIColor whiteColor];
        
        
        LoginViewController *controller = [LoginViewController new];
        controller.delegate = self;
        controller.isPresentedViewController = YES;
        controller.redirectViewController = self;
        navigationController.viewControllers = @[controller];
        isDoingMessage = YES;
        [self.navigationController presentViewController:navigationController animated:YES completion:nil];
    }
}

//this function called when user tap RED HEART button, with intention to UNFAVORITE a shop
- (IBAction)favoriteTap:(id)sender {
    if(_requestFavorite.isExecuting) return;
    
    if([_userManager isLogin]) {
        _requestFavoriteCount = 0;
        [self configureFavoriteRestkit];
        [self favoriteShop:_shop.result.info.shop_id];

    }
}

//this function called when user tap WHITE HEART button, with intention to FAVORITE a shop
- (IBAction)unfavoriteTap:(id)sender {
    if(_requestFavorite.isExecuting) return;
    
    if([_userManager isLogin]) {
        _requestFavoriteCount = 0;
        [self configureFavoriteRestkit];
        [self favoriteShop:_shop.result.info.shop_id];
    }else {
        UINavigationController *navigationController = [[UINavigationController alloc] init];
        navigationController.navigationBar.backgroundColor = [UIColor colorWithCGColor:[UIColor colorWithRed:18.0/255.0 green:199.0/255.0 blue:0.0/255.0 alpha:1].CGColor];
        navigationController.navigationBar.translucent = NO;
        navigationController.navigationBar.tintColor = [UIColor whiteColor];
        
        
        LoginViewController *controller = [LoginViewController new];
        controller.delegate = self;
        controller.isPresentedViewController = YES;
        controller.redirectViewController = self;
        navigationController.viewControllers = @[controller];
        isDoingFavorite = YES;
        [self.navigationController presentViewController:navigationController animated:YES completion:nil];
    }
}

- (IBAction)settingTap:(id)sender {
    if (_shop) {
        ShopSettingViewController *settingController = [ShopSettingViewController new];
        settingController.data = @{
                                   kTKPD_AUTHKEY : [_data objectForKey:kTKPD_AUTHKEY]?:@{},
                                   kTKPDDETAIL_DATAINFOSHOPSKEY:_shop.result
                                   };
        [self.navigationController pushViewController:settingController animated:YES];
    }
}

- (IBAction)addProductTap:(id)sender {
    ProductAddEditViewController *productViewController = [ProductAddEditViewController new];
    productViewController.data = @{
                                   kTKPD_AUTHKEY: [_data objectForKey:kTKPD_AUTHKEY]?:@{},
                                   DATA_TYPE_ADD_EDIT_PRODUCT_KEY : @(TYPE_ADD_EDIT_PRODUCT_ADD),
                                   };
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:productViewController];
    nav.navigationBar.translucent = NO;
    
    [self.navigationController presentViewController:nav animated:YES completion:nil];
}

- (IBAction)tap:(id)sender {
    
    if ([sender isKindOfClass:[UIBarButtonItem class]]) {
        UIBarButtonItem *button = (UIBarButtonItem*)sender;
        switch (button.tag) {
            case 1:
            {
                [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                break;
            }
            case 2:
            {
                if (_shop) {
                    ShopInfoViewController *vc = [[ShopInfoViewController alloc] init];
                    vc.data = @{kTKPDDETAIL_DATAINFOSHOPSKEY : _shop,
                                kTKPD_AUTHKEY:[_data objectForKey:kTKPD_AUTHKEY]?:@{}};
                    [self.navigationController pushViewController:vc animated:YES];
                }
                break;
            }
            default:
                break;
        }
    }
    
    if ([sender isKindOfClass: [UIButton class]]) {
        UIButton *btn = (UIButton *)sender;
        
        switch (btn.tag) {
            case 10:
            {
                [_pageController setViewControllers:@[_shopTalkViewController] direction:UIPageViewControllerNavigationDirectionReverse animated:NO completion:nil];
                [self updateHeaderShopPage];
                break;
            }
            case 11:
            {
                [_pageController setViewControllers:@[_shopReviewViewController] direction:UIPageViewControllerNavigationDirectionReverse animated:NO completion:nil];
                [self updateHeaderShopPage];
                break;
            }
            case 12:
            {
                
                [_pageController setViewControllers:@[_shopNotesViewController] direction:UIPageViewControllerNavigationDirectionReverse animated:NO completion:nil];
                [self updateHeaderShopPage];
                break;
            }
                
            case 13:
            {
                
                [_pageController setViewControllers:@[_shopProductViewController] direction:UIPageViewControllerNavigationDirectionReverse animated:NO completion:nil];
                [self updateHeaderShopPage];
                break;
            }
            default:
                break;
        }
    }
}


#pragma mark - Request and mapping favorite action

-(void)configureFavoriteRestkit {
    
    // initialize RestKit
    _objectFavoriteManager =  [RKObjectManager sharedClient];
    
    // setup object mappings
    RKObjectMapping *statusMapping = [RKObjectMapping mappingForClass:[FavoriteShopAction class]];
    [statusMapping addAttributeMappingsFromDictionary:@{kTKPD_APISTATUSKEY:kTKPD_APISTATUSKEY,
                                                        kTKPD_APISERVERPROCESSTIMEKEY:kTKPD_APISERVERPROCESSTIMEKEY}];
    
    RKObjectMapping *resultMapping = [RKObjectMapping mappingForClass:[FavoriteShopActionResult class]];
    [resultMapping addAttributeMappingsFromDictionary:@{@"content":@"content",
                                                        @"is_success":@"is_success"}];
    
    //relation
    RKRelationshipMapping *resulRel = [RKRelationshipMapping relationshipMappingFromKeyPath:kTKPD_APIRESULTKEY
                                                                                  toKeyPath:kTKPD_APIRESULTKEY
                                                                                withMapping:resultMapping];
    [statusMapping addPropertyMapping:resulRel];
    
    //register mappings with the provider using a response descriptor
    RKResponseDescriptor *responseDescriptorStatus = [RKResponseDescriptor responseDescriptorWithMapping:statusMapping
                                                                                                  method:RKRequestMethodPOST
                                                                                             pathPattern:@"action/favorite-shop.pl"
                                                                                                 keyPath:@""
                                                                                             statusCodes:kTkpdIndexSetStatusCodeOK];
    
    [_objectFavoriteManager addResponseDescriptor:responseDescriptorStatus];
}

-(void)favoriteShop:(NSString*)shop_id
{
    if (_requestFavorite.isExecuting) return;
    
    _requestFavoriteCount ++;
    
    NSDictionary *param = @{kTKPDDETAIL_ACTIONKEY   :   @"fav_shop",
                            @"shop_id"              :   shop_id};
    
    _requestFavorite = [_objectFavoriteManager appropriateObjectRequestOperationWithObject:self
                                                                                    method:RKRequestMethodPOST
                                                                                      path:@"action/favorite-shop.pl"
                                                                                parameters:[param encrypt]];
    
    [_requestFavorite setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        [self requestFavoriteResult:mappingResult withOperation:operation];
        //[_timer invalidate];
        //_timer = nil;
        [self setFavoriteRightButtonItem];
        NSArray *tempArr = self.navigationController.viewControllers;
        if([[tempArr objectAtIndex:tempArr.count-2] isMemberOfClass:[DetailProductViewController class]]) {
            [((DetailProductViewController *) [tempArr objectAtIndex:tempArr.count-2]) setButtonFav];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"updateFavoriteShop" object:nil];
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        /** failure **/
        [self requestFavoriteError:error];
        //[_timer invalidate];
        //_timer = nil;
    }];
    
    [_operationFavoriteQueue addOperation:_requestFavorite];
    
    _timerFavorite = [NSTimer scheduledTimerWithTimeInterval:kTKPDREQUEST_TIMEOUTINTERVAL
                                                      target:self
                                                    selector:@selector(requestTimeout)
                                                    userInfo:nil
                                                     repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:_timerFavorite forMode:NSRunLoopCommonModes];
}

-(void)requestFavoriteResult:(id)mappingResult withOperation:(NSOperation *)operation {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"notifyFav" object:nil];
}

-(void)requestFavoriteError:(id)object {
    
}

#pragma mark - LoginView Delegate
- (void)redirectViewController:(id)viewController
{
    TKPDSecureStorage *secureStorage = [TKPDSecureStorage standardKeyChains];
    NSDictionary *tempAuth = [secureStorage keychainDictionary];
    _auth = [tempAuth mutableCopy];
    [self requestShopInfo];
}

#pragma mark - Reload Shop
- (void)reloadShop {
    [self requestShopInfo];
}

#pragma mark - Notification Center Action

#pragma mark - Notification Delegate
- (void)userDidLogin:(NSNotification*)notification {
    _userManager = [UserAuthentificationManager new];
}

- (void)userDidLogout:(NSNotification*)notification {
    _userManager = [UserAuthentificationManager new];
}

@end