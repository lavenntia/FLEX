//
//  HomeTabViewController.m
//  Tokopedia
//
//  Created by Tonito Acen on 3/30/15.
//  Copyright (c) 2015 TOKOPEDIA. All rights reserved.
//

#import "HomeTabViewController.h"

#import "HotlistViewController.h"
#import "HistoryProductViewController.h"
#import "FavoritedShopViewController.h"

#import "HomeTabHeaderViewController.h"
#import "TKPDTabInboxTalkNavigationController.h"
#import "InboxTalkViewController.h"
#import "UserAuthentificationManager.h"

#import "MyWishlistViewController.h"

#import "RedirectHandler.h"

#import "NavigateViewController.h"

#import "UIView+HVDLayout.h"
#import "Tokopedia-Swift.h"
#import "SearchViewController.h"
#import "PromoViewController.h"
@import NativeNavigation;
@import FirebaseRemoteConfig;

@interface HomeTabViewController ()
<
UIScrollViewDelegate,
RedirectHandlerDelegate,
UISearchControllerDelegate,
UISearchResultsUpdating,
UIImagePickerControllerDelegate,
UINavigationControllerDelegate
>
{
    NSInteger _page;
    UserAuthentificationManager *_userManager;
    RedirectHandler *_redirectHandler;
    NavigateViewController *_navigate;
    NSURL *_deeplinkUrl;
    BOOL _needToActivateSearch;
    BOOL _isViewLoaded;
    NotificationBarButton *_barButton;
}

@property (strong, nonatomic) UIViewController *homePageController;
@property (strong, nonatomic) HotlistViewController *hotlistController;
@property (strong, nonatomic) FeedViewController *feedController;
@property (strong, nonatomic) PromoViewController *promoViewController;
@property (strong, nonatomic) UISearchController* searchController;
@property (strong, nonatomic) HistoryProductViewController *historyController;
@property (strong, nonatomic) FavoritedShopViewController *shopViewController;
@property (strong, nonatomic) HomeTabHeaderViewController *homeHeaderController;
@property (strong, nonatomic) MyWishlistViewController *wishListViewController;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIView *homeHeaderView;
@property (strong, nonatomic) NSArray<UIViewController*> *viewControllers;

@property (strong, nonatomic) SearchBarWrapperView *searchBarWrapperView;
@property (strong, nonatomic) UIButton *QRCodeButton;

@end

@implementation HomeTabViewController

#pragma mark - Init

- (instancetype)init {
    self = [super init];
    [self initNotificationCenter];
    return self;
}

- (void)initNotificationCenter {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didSwipeHomePage:)
                                                 name:@"didSwipeHomePage" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(redirectNotification:)
                                                 name:@"redirectNotification" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidLogin:) name:TKPDUserDidLoginNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidLogout:) name:kTKPDACTIVATION_DIDAPPLICATIONLOGGEDOUTNOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activateSearch:) name:@"activateSearch" object:nil];
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _userManager = [UserAuthentificationManager new];
    NSDictionary* userData = [_userManager getUserLoginData];

    if (userData) {
        _homePageController = [[ReactViewController alloc] initWithModuleName:@"HomeScreen" props:@{@"authInfo": userData, @"cacheEnabled" : @(NO)}];
    } else {
        _homePageController = [[ReactViewController alloc] initWithModuleName:@"HomeScreen" props: @{@"cacheEnabled": @(NO)}];
    }

    _feedController = [FeedViewController new];
    
    _promoViewController = [PromoViewController new];
    
    _historyController = [HistoryProductViewController new];
    _shopViewController = [FavoritedShopViewController new];
    
    _homeHeaderController = [HomeTabHeaderViewController new];
    
    _redirectHandler = [RedirectHandler new];
    
    _navigate = [NavigateViewController new];
    
    [self instantiateViewControllers];
    
    self.modalPresentationStyle = UIModalPresentationCurrentContext;
    
    [_scrollView setFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    [_scrollView setPagingEnabled:YES];
    
    //this code to prevent user lose their hometabheader being hided by scrollview if they already loggedin from previous version
    //check didLoggedIn method
    CGRect frame = _scrollView.frame;
    frame.origin.y = 44;
    _scrollView.frame = frame;
    
    _scrollView.delegate = self;
    
    [self addChildViewController:_homePageController];
    [self.scrollView addSubview:_homePageController.view];
    
    [self setSearchByImage];
    
    
    NSLayoutConstraint *width =[NSLayoutConstraint
                                constraintWithItem:_homePageController.view
                                attribute:NSLayoutAttributeWidth
                                relatedBy:0
                                toItem:self.scrollView
                                attribute:NSLayoutAttributeWidth
                                multiplier:1.0
                                constant:0];
    NSLayoutConstraint *height =[NSLayoutConstraint
                                 constraintWithItem:_homePageController.view
                                 attribute:NSLayoutAttributeHeight
                                 relatedBy:0
                                 toItem:self.scrollView
                                 attribute:NSLayoutAttributeHeight
                                 multiplier:1.0
                                 constant:0];
    NSLayoutConstraint *top = [NSLayoutConstraint
                               constraintWithItem:_homePageController.view
                               attribute:NSLayoutAttributeTop
                               relatedBy:NSLayoutRelationEqual
                               toItem:self.scrollView
                               attribute:NSLayoutAttributeTop
                               multiplier:1.0f
                               constant:0.f];
    NSLayoutConstraint *leading = [NSLayoutConstraint
                                   constraintWithItem:_homePageController.view
                                   attribute:NSLayoutAttributeLeading
                                   relatedBy:NSLayoutRelationEqual
                                   toItem:self.scrollView
                                   attribute:NSLayoutAttributeLeading
                                   multiplier:1.0f
                                   constant:0.f];
    
    [self.scrollView addConstraints:@[width, height, top, leading]];
    [_homePageController.view setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [_homePageController didMoveToParentViewController:self];
    
    // init notification bar button
    _barButton = [[NotificationBarButton alloc] initWithParentViewController:self];
    
    [self setArrow];
    [self setHeaderBar];
    [self setSearchBar];
}


- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.searchController setActive:NO];
    self.definesPresentationContext = NO;
}

- (void)setSearchBar {
    SearchViewController* resultController = [[SearchViewController alloc] init];
    _searchController = [[UISearchController alloc] initWithSearchResultsController:resultController];
    [_searchController setSearchBarToTopWithViewController:self];
    _searchBarWrapperView = [_searchController getSearchWrapperView];
    
    [self.searchController.searchBar setTextFieldColorWithColor:[UIColor whiteColor]];
    [self.searchController.searchBar setTextColorWithColor:[UIColor blackColor]];
    
    resultController.searchBar = self.searchController.searchBar;
    resultController.searchBar.text = @"";
}

- (void)setSearchByImage {
    if([self isEnableImageSearch]) {
        self.searchController.searchBar.showsBookmarkButton = YES;
        [self.searchController.searchBar setImage:[UIImage imageNamed:@"icon_snap.png"] forSearchBarIcon:UISearchBarIconBookmark state:UIControlStateNormal];
    } else  {
        self.searchController.searchBar.showsBookmarkButton = NO;
    }
}


-(BOOL)isEnableImageSearch{
    UserAuthentificationManager* userManager = [UserAuthentificationManager new];
    if (!userManager.isLogin) {
        return NO;
    }
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    TAGContainer *gtmContainer = appDelegate.container;
    
    NSString *enableImageSearchString = [gtmContainer stringForKey:@"enable_image_search"]?:@"0";
    
    return [enableImageSearchString isEqualToString:@"1"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.title = @"Home";
    
    self.definesPresentationContext = YES;
    [self.searchController.searchBar setShowsCancelButton:NO animated:YES];
    
    [self goToPage:_page];
    [self tapButtonAnimate:_scrollView.frame.size.width*(_page)];
    if([_userManager isLogin]) {
        [_scrollView setContentSize:CGSizeMake(self.view.frame.size.width*5, 300)];
    } else {
        [_scrollView setContentSize:CGSizeMake(self.view.frame.size.width*2, 300)];
    }
    
    [self initNotificationManager];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    float fractionalPage = _scrollView.contentOffset.x  / _scrollView.frame.size.width;
    _page = lround(fractionalPage);
    
    _isViewLoaded = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _isViewLoaded = YES;
}

- (void)setArrow {
    UIBarButtonItem *backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@" "
                                                                          style:UIBarButtonItemStylePlain
                                                                         target:self
                                                                         action:nil];
    self.navigationItem.backBarButtonItem = backBarButtonItem;
}

- (void)setHeaderBar {
    [self addChildViewController:_homeHeaderController];
    [_homeHeaderView addSubview:_homeHeaderController.view];
    [_homeHeaderController didMoveToParentViewController:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    float fractionalPage = scrollView.contentOffset.x  / scrollView.frame.size.width;
    int page = (int) lround(fractionalPage);
    if (page >= 0 && page < _viewControllers.count) {
        [self setIndexPage:page];
        [self goToPage:_page];
    }
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    return YES;
}



#pragma mark - Action
- (void)setIndexPage:(int)idxPage
{
    _page = idxPage;
}

- (void)goToPage:(NSInteger)page {
    if (!_viewControllers) return;
    
    _shopViewController.isOpened = false;
    if(page == 4){
        _shopViewController.isOpened = true;
    }
    
    CGRect frame = _viewControllers[page].view.frame;
    frame.origin.x = _scrollView.frame.size.width*page;
    frame.size.height = _scrollView.frame.size.height;
    frame.size.width = [UIScreen mainScreen].bounds.size.width;
    _viewControllers[page].view.frame = frame;
    
    [self addChildViewController:_viewControllers[page]];
    [self.scrollView addSubview:_viewControllers[page].view];
    [_viewControllers[page] didMoveToParentViewController:self];
    
    NSDictionary *userInfo = @{@"tag" : @(page)};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"didSwipeHomeTab" object:nil userInfo:userInfo];
}

- (void)didSwipeHomePage:(NSNotification*)notification {
    NSDictionary *userinfo = notification.userInfo;
    NSInteger index = [[userinfo objectForKey:@"page"]integerValue];
    [self setIndexPage:index-1];
    [self goToPage:_page];
    [self tapButtonAnimate:_scrollView.frame.size.width*(index-1)];
    if (_page == 0) {
        ReactEventManager *tabManager = [[UIApplication sharedApplication].reactBridge moduleForClass:[ReactEventManager class]];
        [tabManager sendRedirectHomeTabEvent];
    }
}

- (void)tapButtonAnimate:(CGFloat)totalOffset{
    [UIView animateWithDuration:0.3 animations:^{
        _scrollView.contentOffset = CGPointMake(totalOffset, _scrollView.contentOffset.y);
    }];
}

- (void)redirectToWishList
{
    UIButton *tempBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    tempBtn.tag = 4;
    [_homeHeaderController tapButton:tempBtn];
}

- (void)redirectToProductFeed
{
    UIButton *tempBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    tempBtn.tag = 2;
    [_homeHeaderController tapButton:tempBtn];
}

- (void)redirectToHome {
    _page = 0;
    UIButton *tempBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    tempBtn.tag = 1;
    [_homeHeaderController tapButton:tempBtn];
}


#pragma mark - Notification Manager

- (void)initNotificationManager {
    if ([_userManager isLogin]) {
        
        _QRCodeButton = [[UIButton alloc] init];
        _QRCodeButton.frame = CGRectMake(0, 0, 30, 20);
        [_QRCodeButton setImageEdgeInsets:UIEdgeInsetsMake(0.0, 10.0, 0.0, 0.0)];
        [_QRCodeButton setImage:[UIImage imageNamed: @"qr_code"] forState:UIControlStateNormal];
        [_QRCodeButton addTarget:self action:@selector(didTapQRCodeButton) forControlEvents:UIControlEventTouchUpInside];
        [_QRCodeButton setSemanticContentAttribute: UISemanticContentAttributeForceRightToLeft];
        
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:_barButton, [[UIBarButtonItem alloc] initWithCustomView:_QRCodeButton], nil];
        [_barButton reloadNotifications];
    } else {
        self.navigationItem.rightBarButtonItems = nil;
    }
}

#pragma mark - Memory Management
-(void)dealloc{
    NSLog(@"%@ : %@",[self class], NSStringFromSelector(_cmd));
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)redirectNotification:(NSNotification*)notification {
    NSDictionary* data = [notification.userInfo objectForKey:@"data"];
    if ([data objectForKey:@"applinks"] != nil) {
        NSString* applinks = [data objectForKey:@"applinks"];
        //Need to delay, so routeURL called after popToRoot. Push Notification purpose.
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [TPRoutes routeURL:[NSURL URLWithString:applinks]];
        });
    } else {
        _redirectHandler = [[RedirectHandler alloc]init];
        _redirectHandler.delegate = self;
        
        NSInteger code = [[data objectForKey:@"tkp_code"] integerValue];
        
        [_redirectHandler proxyRequest:code];
    }
}

#pragma mark - Search Controller Delegate
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    [self setSearchControllerHidden:NO];
}

- (void)willPresentSearchController:(UISearchController *)searchController {
    [self setSearchControllerHidden:NO];
    self.navigationItem.rightBarButtonItems = nil;
    if (_searchBarWrapperView != nil)
    _searchBarWrapperView.frame = CGRectMake(0, 0, self.view.frame.size.width, 44);
}

- (void)didDismissSearchController:(UISearchController *)searchController {
    [self initNotificationManager];
}

- (void)userDidLogin:(NSNotification*)notification {
    // [self view] gunanya adalah memanggil viewDidLoad dari background. Dipakai di sini untuk ketika untuk mencegah bug crash saat user login langsung dari onboarding.
    [self view];
    [self instantiateViewControllers];
    [self setSearchByImage];
    [self setIndexPage:0];
}

- (void)userDidLogout:(NSNotification*)notification {
    [self view];
    [self instantiateViewControllers];
    [self redirectToHome];
    [self setSearchByImage];
    [self setSearchBar];
}

- (void)activateSearch:(NSNotification*)notification {
    if (_isViewLoaded) {
        dispatch_async(dispatch_get_main_queue(), ^{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.searchController.searchBar becomeFirstResponder];
            });
        });
    } else {
        _needToActivateSearch = YES;
        [self.navigationController popToRootViewControllerAnimated:NO];
    }
}

#pragma mark - Method

- (void) instantiateViewControllers {
    if (_userManager.isLogin) {
        _viewControllers = @[_homePageController, _feedController, _promoViewController, _historyController, _shopViewController];
    } else {
        _viewControllers = @[_homePageController, _promoViewController];
    }
}

-(void) setSearchControllerHidden:(BOOL) hidden {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.searchController.searchResultsController.view.hidden = hidden;
    });
}

- (void)scrollToTop {
    NSArray *vcs = [_viewControllers mutableCopy];
    if ([vcs[_page] respondsToSelector:@selector(scrollToTop)]) {
        [vcs[_page] scrollToTop];
    }
    
    ReactEventManager *tabManager = [[UIApplication sharedApplication].reactBridge moduleForClass:[ReactEventManager class]];
    [tabManager sendScrollToTopEvent];
}

- (void) didTapQRCodeButton {
    TokoCashQRCodeViewController *vc = [TokoCashQRCodeViewController new];
    TokoCashQRCodeNavigator *navigator = [[TokoCashQRCodeNavigator alloc] initWithNavigationController:self.navigationController];
    TokoCashQRCodeViewModel *viewModel = [[TokoCashQRCodeViewModel alloc] initWithNavigator:navigator];
    vc.viewModel = viewModel;
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
