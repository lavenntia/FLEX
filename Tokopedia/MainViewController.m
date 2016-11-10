//
//  MainViewController.m
//  Tokopedia
//
//  Created by IT Tkpd on 9/1/14.
//  Copyright (c) 2014 TOKOPEDIA. All rights reserved.
//

#import "MainViewController.h"
#import "LoginViewController.h"
#import "SearchViewController.h"
#import "TransactionCartRootViewController.h"   
#import "MoreViewController.h"
#import "CategoryViewController.h"


#import "HotlistViewController.h"
#import "ProductFeedViewController.h"
#import "HistoryProductViewController.h"
#import "FavoritedShopViewController.h"

#import "activation.h"

#import "TKPDSecureStorage.h"
#import "URLCacheController.h"
#import "UserAuthentificationManager.h"
#import "HomeTabViewController.h"

#import "TokopediaNetworkManager.h"
#import "UserAuthentificationManager.h"
#import "Logout.h"
#import "AlertBaseUrl.h"

#import "InboxRootViewController.h"
#import "CategoryViewController.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

#import "TKPAppFlow.h"
#import "TKPStoreManager.h"
#import "MoreWrapperViewController.h"
#import "PhoneVerifViewController.h"
#import "Tokopedia-Swift.h"

#define TkpdNotificationForcedLogout @"NOTIFICATION_FORCE_LOGOUT"

@interface MainViewController ()
<
    UITabBarControllerDelegate,
    UIAlertViewDelegate,
    LoginViewDelegate,
    TKPAppFlow
>
{
    UITabBarController *_tabBarController;
    HomeTabViewController *_swipevc;
    URLCacheController *_cacheController;
    
    UserAuthentificationManager *_userManager;
    NSString *_persistToken;
    NSString *_persistBaseUrl;
    
    UIAlertView *_logingOutAlertView;
    NSTimer *_containerTimer;
    
    TKPStoreManager *_storeManager;
    
    MainViewControllerPage _page;
}

@end

typedef enum TagRequest {
    LogoutTag
} TagRequest;

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
       [self.navigationController.navigationBar setTranslucent:NO];
        self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    }
    return self;
}

- (instancetype)initWithPage:(MainViewControllerPage)page {
    if (self = [super init]) {
        _page = page;
    }
    return self;
}

- (instancetype)init {
    if (self = [super init]) {
        _page = MainViewControllerPageDefault;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [Localytics tagEvent:@"Enter Main Page"];
    
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
        
    [self adjustnavigationbar];
        
    _auth = [NSMutableDictionary new];
    _cacheController = [URLCacheController new];

    [[UISegmentedControl appearance] setTintColor:kTKPDNAVIGATION_NAVIGATIONBGCOLOR];
    
    [self performSelector:@selector(viewDidLoadQueued) withObject:nil afterDelay:kTKPDMAIN_PRESENTATIONDELAY];	//app launch delay presentation

    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    
    [center addObserver:self selector:@selector(applicationLogin:) name:kTKPDACTIVATION_DIDAPPLICATIONLOGINNOTIFICATION object:nil];
    [center addObserver:self selector:@selector(forceLogout) name:TkpdNotificationForcedLogout object:nil];
    [center addObserver:self selector:@selector(applicationlogout:) name:kTKPDACTIVATION_DIDAPPLICATIONLOGOUTNOTIFICATION object:nil];
    [center addObserver:self selector:@selector(redirectNotification:) name:@"redirectNotification" object:nil];
    [center addObserver:self selector:@selector(updateTabBarMore:) name:UPDATE_TABBAR object:nil];
    [center addObserver:self selector:@selector(didReceiveShowRatingNotification:) name:kTKPD_SHOW_RATING_ALERT object:nil];
    [center addObserver:self selector:@selector(redirectToHomeViewController) name:kTKPD_REDIRECT_TO_HOME object:nil];
    [center addObserver:self selector:@selector(navigateToPageInTabBar:) name:@"navigateToPageInTabBar" object:nil];
    [center addObserver:self selector:@selector(redirectToSearch) name:@"redirectToSearch"object:nil];
    [center addObserver:self selector:@selector(redirectToHotlist) name:@"redirectToHotlist"object:nil];
    
    //refresh timer for GTM Container
    _containerTimer = [NSTimer scheduledTimerWithTimeInterval:7200.0f target:self selector:@selector(didRefreshContainer:) userInfo:nil repeats:YES];
    
    [self makeSureDeviceTokenExists];
}

- (void)makeSureDeviceTokenExists {
    // Perhaps this method should be called at more appropriate places,
    // such as before logging in and registration.
    
    [UserAuthentificationManager ensureDeviceIdExistence];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _userManager = [UserAuthentificationManager new];
}


#pragma mark - Memory Management
-(void)dealloc{
    NSLog(@"%@ : %@",[self class], NSStringFromSelector(_cmd));
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma methods

- (void)viewDidLoadQueued
{
    TKPDSecureStorage* secureStorage = [TKPDSecureStorage standardKeyChains];
	NSDictionary* auth = [secureStorage keychainDictionary];
	_auth = [auth mutableCopy];
    	
    _data = nil;
    [self presentcontrollers];
    
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [AnalyticsManager localyticsSetCustomerID:[_userManager getUserId]];
        [AnalyticsManager localyticsValue:[_userManager getUserId] profileAttribute:@"user_id"];
    });
    
}

-(void)presentcontrollers
{
    [self createtabbarController];
    
    _tabBarController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	[self presentViewController:_tabBarController animated:YES completion:^{

	}];
}

-(void)createtabbarController
{
    TKPDSecureStorage* secureStorage = [TKPDSecureStorage standardKeyChains];
    NSDictionary* auth = [secureStorage keychainDictionary];
    _auth = [auth mutableCopy];
    BOOL isauth = [[_auth objectForKey:kTKPD_ISLOGINKEY] boolValue];
    _tabBarController = [UITabBarController new];
    _tabBarController.delegate = self;
    
    [[UITabBarItem appearance] setTitleTextAttributes:@{ UITextAttributeTextColor : kTKPDNAVIGATION_TABBARTITLECOLOR }
                                             forState:UIControlStateNormal];
    [[UITabBarItem appearance] setTitleTextAttributes:@{ UITextAttributeTextColor : [UIColor colorWithRed:18.0/255.0 green:199.0/255.0 blue:0.0/255.0 alpha:1] }
                                             forState:UIControlStateSelected];
//    
//    /** TAB BAR INDEX 1 **/
//    /** adjust view controllers at tab bar controller **/
//    NSMutableArray *viewcontrollers = [NSMutableArray new];
//    /** create new view controller **/
//    if (!isauth) {
//        // before login
////        HotlistViewController *v = [HotlistViewController new];
////        v.data = @{kTKPD_AUTHKEY : _auth?:@{}};
////        [viewcontrollers addObject:v];
//        CategoryViewController *controller = [[CategoryViewController alloc] init];
//        controller.data = @{@"auth" : _auth?:@{}};
//        [viewcontrollers addObject:controller];
//    }
//    else{
//        // after login
//        HotlistViewController *controller = [[HotlistViewController alloc] init];
//        controller.data = @{@"auth" : _auth?:@{}};
//        [viewcontrollers addObject:controller];
//        ProductFeedViewController *v1 = [ProductFeedViewController new];
//        [viewcontrollers addObject:v1];
//        HistoryProductViewController *v2 = [HistoryProductViewController new];
//        [viewcontrollers addObject:v2];
//        FavoritedShopViewController *v3 = [FavoritedShopViewController new];
//        [viewcontrollers addObject:v3];
//    }
    
    _swipevc = [[HomeTabViewController alloc] init];
    UINavigationController *swipevcNav = [[UINavigationController alloc] initWithRootViewController:_swipevc];
    [swipevcNav.navigationBar setTranslucent:NO];
    _swipevc.edgesForExtendedLayout = UIRectEdgeNone;
    
    /** TAB BAR INDEX 2 **/
    HotlistViewController *categoryvc = [HotlistViewController new];
    UINavigationController *categoryNavBar = [[UINavigationController alloc]initWithRootViewController:categoryvc];

    [categoryNavBar.navigationBar setTranslucent:NO];
    categoryvc.edgesForExtendedLayout = UIRectEdgeNone;
    
    /** TAB BAR INDEX 3 **/
    SearchViewController *search = [SearchViewController new];
    if (_auth) {
        search.data = @{kTKPD_AUTHKEY:_auth?:@{}};
    }
    UINavigationController *searchNavBar = [[UINavigationController alloc]initWithRootViewController:search];
    searchNavBar.navigationBar.translucent = NO;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(iOS7_0)) {
        search.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    /** TAB BAR INDEX 4 **/
    TransactionCartRootViewController *cart = [TransactionCartRootViewController new];
    UINavigationController *cartNavBar = [[UINavigationController alloc]initWithRootViewController:cart];
    [cartNavBar.navigationBar setTranslucent:NO];
    cart.edgesForExtendedLayout = UIRectEdgeNone;
    
    /** TAB BAR INDEX 5 **/
    UINavigationController *moreNavBar;
    if (!isauth) {
        LoginViewController *more = [LoginViewController new];
        moreNavBar = [[UINavigationController alloc]initWithRootViewController:more];
        
        if (_page == MainViewControllerPageRegister) {
            [more navigateToRegister];
        }
    }
    else{
        MoreWrapperViewController *controller = [[MoreWrapperViewController alloc] init];
        moreNavBar = [[UINavigationController alloc] initWithRootViewController:controller];
    }

    [moreNavBar.navigationBar setTranslucent:NO];
    
    /** for ios 7 need to set automatically adjust scrooll view inset **/
    if([self respondsToSelector:@selector(setExtendedLayoutIncludesOpaqueBars:)])
    {
        _swipevc.extendedLayoutIncludesOpaqueBars = YES;
        categoryvc.extendedLayoutIncludesOpaqueBars = YES;
        search.extendedLayoutIncludesOpaqueBars = YES;
        cart.extendedLayoutIncludesOpaqueBars = YES;
        moreNavBar.extendedLayoutIncludesOpaqueBars = YES;
        [moreNavBar.navigationBar setTranslucent:NO];
    }
    
    NSArray* controllers = [NSArray arrayWithObjects:swipevcNav, categoryNavBar, searchNavBar, cartNavBar, moreNavBar, nil];
    _tabBarController.viewControllers = controllers;
    _tabBarController.delegate = self;
    //tabBarController.tabBarItem.title = nil;
    
    NSInteger pageIndex = [self pageIndex];
    
    _tabBarController.selectedIndex = pageIndex;
    
    [self initTabBar];
}

- (void)adjustnavigationbar
{
    // Move to root view controller
    UINavigationBar *proxy = [UINavigationBar appearance];
    [proxy setBarTintColor:kTKPDNAVIGATION_NAVIGATIONBGCOLOR];
    [proxy setTintColor:[UIColor whiteColor]];
    [proxy setBackgroundColor:[UIColor colorWithRed:(18/255.0) green:(199/255.0) blue:(0/255.0) alpha:1]];
    [[UINavigationBar appearance] setBackgroundImage:[[UIImage alloc] init]
                                      forBarPosition:UIBarPositionAny
                                          barMetrics:UIBarMetricsDefault];
    
    [[UINavigationBar appearance] setShadowImage:[[UIImage alloc] init]];
    
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = kTKPDNAVIGATION_TITLESHADOWCOLOR;
    
    proxy.titleTextAttributes = @{
                                  NSForegroundColorAttributeName: kTKPDNAVIGATION_TITLECOLOR,
                                  NSShadowAttributeName: shadow,
                                  };
}

-(void)initTabBar {
    NSArray* items = @[@{@"name" : @"Home", @"image" : @"icon_home.png", @"selectedImage" : @"icon_home_active.png"},
                       @{@"name" : @"Hot List", @"image" : @"icon_hotlist.png", @"selectedImage" : @"icon_hotlist_active.png"},
                       @{@"name" : @"Cari", @"image" : @"icon_search.png", @"selectedImage" : @"icon_search_active.png"},
                       @{@"name" : @"Keranjang", @"image" : @"icon_cart.png", @"selectedImage" : @"icon_cart_active.png"},
                       @{@"name" : @"More", @"image" : @"icon_more.png", @"selectedImage" : @"icon_more_active.png"}];
    UITabBar *tabBar = _tabBarController.tabBar;
    tabBar.tintColor = [UIColor colorWithRed:(66/255.0) green:(189/255.0) blue:(65/255.0) alpha:1];
    tabBar.backgroundImage = [UIImage imageNamed:@"tabnav_bg"];
    
    NSUInteger index = 0;
    NSDictionary *textAttributes = @{
                                     NSForegroundColorAttributeName:[UIColor blackColor],
                                     NSFontAttributeName:IS_IPAD?[UIFont microTheme]:[UIFont systemFontOfSize:11]};
    for(NSDictionary* item in items) {
        
        UITabBarItem *tabBarItem = [tabBar.items objectAtIndex:index];
        if(index == items.count - 1) {
            UserAuthentificationManager* userManager = [UserAuthentificationManager new];
            if(!userManager.isLogin) {
                [tabBarItem initWithTitle:@"Login"
                                    image:[[UIImage imageNamed:@"icon_login.png"]imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                            selectedImage:[[UIImage imageNamed:@"icon_login_active.png"]imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
            } else {
                [tabBarItem initWithTitle:[item objectForKey:@"name"]
                                    image:[[UIImage imageNamed:[item objectForKey:@"image"]]imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                            selectedImage:[[UIImage imageNamed:[item objectForKey:@"selectedImage"]]imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
            }
        } else {
            [tabBarItem initWithTitle:[item objectForKey:@"name"]
                                image:[[UIImage imageNamed:[item objectForKey:@"image"]]imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                        selectedImage:[[UIImage imageNamed:[item objectForKey:@"selectedImage"]]imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
            
        }
        
        [tabBarItem setTitleTextAttributes:textAttributes forState:UIControlStateNormal];
        
        index++;
    }
}

- (NSInteger)pageIndex {
    switch (_page) {
        case MainViewControllerPageLogin:
            return 4;
            break;
        
        case MainViewControllerPageRegister:
            return 4;
            break;
            
        case MainViewControllerPageSearch:
            return 2;
            break;
            
        default:
            return 0;
            break;
    }
}

#pragma mark - Notification observers

- (void)applicationLogin:(NSNotification*)notification
{    
    _userManager = [UserAuthentificationManager new];
    _auth = [_userManager getUserLoginData];
    
    BOOL isauth = [[_auth objectForKey:kTKPD_ISLOGINKEY] boolValue];
    
    //refreshing cart when first login
    [[NSNotificationCenter defaultCenter] postNotificationName:@"doRefreshingCart" object:nil userInfo:nil];

	// Assume tabController is the tab controller
    // and newVC is the controller you want to be the new view controller at index 0
    NSMutableArray *newControllers = [NSMutableArray arrayWithArray:_tabBarController.viewControllers];
    UINavigationController *swipevcNav = [[UINavigationController alloc]initWithRootViewController:_swipevc];
    swipevcNav.navigationBar.translucent = NO;
    UIImageView *logo = [[UIImageView alloc]initWithImage:[UIImage imageNamed:kTKPDIMAGE_TITLEHOMEIMAGE]];
    _swipevc.navigationItem.titleView = logo;

    UINavigationController *searchNavBar = newControllers[2];
    id search = searchNavBar.viewControllers[0];
    if (_auth) {
        ((SearchViewController*)search).data = @{kTKPD_AUTHKEY:_auth?:@{}};
    }
    
    UINavigationController *moreNavBar = nil;
    if (!isauth) {
        LoginViewController *more = [LoginViewController new];
        moreNavBar = [[UINavigationController alloc]initWithRootViewController:more];
        [[_tabBarController.viewControllers objectAtIndex:3] tabBarItem].badgeValue = nil;
    }
    else{
        MoreWrapperViewController *controller = [[MoreWrapperViewController alloc] init];
        moreNavBar = [[UINavigationController alloc] initWithRootViewController:controller];
        
    }
    [moreNavBar.navigationBar setTranslucent:NO];

    [newControllers replaceObjectAtIndex:0 withObject:swipevcNav];
    [newControllers replaceObjectAtIndex:4 withObject:moreNavBar];

    [_tabBarController setViewControllers:newControllers animated:YES];

    [self initTabBar];
}

- (void)updateTabBarMore:(NSNotification*)notification
{
    TKPDSecureStorage* secureStorage = [TKPDSecureStorage standardKeyChains];
    NSDictionary* auth = [secureStorage keychainDictionary];
    _auth = [auth mutableCopy];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"doRefreshingCart" object:nil userInfo:nil];
    
    NSMutableArray *newControllers = [NSMutableArray arrayWithArray:_tabBarController.viewControllers];
    
    MoreWrapperViewController *controller = [[MoreWrapperViewController alloc] init];
    UINavigationController *moreNavController = [[UINavigationController alloc] initWithRootViewController:controller];
    
    [moreNavController.navigationBar setTranslucent:NO];
    [newControllers replaceObjectAtIndex:4 withObject:moreNavController];
    [_tabBarController setViewControllers:newControllers animated:YES];
    
    [self initTabBar];
}

- (void)applicationlogout:(NSNotification*)notification
{
    _userManager = [UserAuthentificationManager new];
    _persistToken = [_userManager getMyDeviceToken]; //token device from ios

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Apakah Anda ingin keluar?"
                                                        message:nil
                                                       delegate:self
                                              cancelButtonTitle:@"Batal"
                                              otherButtonTitles:@"Iya", nil];
    alertView.tag = 1;
    [alertView show];
}

- (void)doApplicationLogout {
    /*
    remove all cache from webview, all credential that been logged in, will be removed
    example : login kereta api, login pulsa
    */
    NSHTTPCookie *cookie;
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (cookie in [cookieStorage cookies]) {
        NSString* domainName = [cookie domain];
        NSRange domainRange = [domainName rangeOfString:@"tokopedia"];
        if(domainRange.length > 0) {
            [cookieStorage deleteCookie:cookie];
        }
    }
    
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    _logingOutAlertView = [[UIAlertView alloc] initWithTitle:@"Tunggu sebentar.."
                                                     message:nil
                                                    delegate:self
                                           cancelButtonTitle:nil
                                           otherButtonTitles:nil, nil];
    [_logingOutAlertView show];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"clearCacheNotificationBar"
                                                        object:nil];

    FBSDKLoginManager *loginManager = [[FBSDKLoginManager alloc] init];
    [loginManager logOut];
    [FBSDKAccessToken setCurrentAccessToken:nil];
    
//    [[GPPSignIn sharedInstance] signOut];
//    [[GPPSignIn sharedInstance] disconnect];
    [[GIDSignIn sharedInstance] signOut];
    [[GIDSignIn sharedInstance] disconnect];

    [self requestLogout];
    
    TKPDSecureStorage* storage = [TKPDSecureStorage standardKeyChains];
    _persistBaseUrl = [[storage keychainDictionary] objectForKey:@"AppBaseUrl"]?:kTkpdBaseURLString;
    
    NSString* securityQuestionUUID = [[storage keychainDictionary] objectForKey:@"securityQuestionUUID"];
    
    [storage resetKeychain];
    [_auth removeAllObjects];
    
    [storage setKeychainWithValue:_persistToken?:@"" withKey:@"device_token"];
    [storage setKeychainWithValue:_persistBaseUrl?:@"" withKey:@"AppBaseUrl"];
    if(securityQuestionUUID) {
        [storage setKeychainWithValue:securityQuestionUUID withKey:@"securityQuestionUUID"];
    }
    
    
    [self removeCacheUser];
    
    [[_tabBarController.viewControllers objectAtIndex:3] tabBarItem].badgeValue = nil;
    [((UINavigationController*)[_tabBarController.viewControllers objectAtIndex:3]) popToRootViewControllerAnimated:NO];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kTKPDACTIVATION_DIDAPPLICATIONLOGGEDOUTNOTIFICATION
                                                        object:nil
                                                      userInfo:@{}];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kTKPD_REMOVE_SEARCH_HISTORY object:nil];
    
    if (_logingOutAlertView) {
        [_logingOutAlertView dismissWithClickedButtonIndex:0 animated:YES];
        _logingOutAlertView = nil;
    }
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:PHONE_VERIF_LAST_APPEAR];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self performSelector:@selector(applicationLogin:) withObject:nil afterDelay:kTKPDMAIN_PRESENTATIONDELAY];
    
    [AnalyticsManager localyticsValue:@"No" profileAttribute:@"Is Login"];
    
    [self reinitCartTabBar];
}

- (void)removeCacheUser {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    [_cacheController initCacheWithDocumentPath:path];
    [_cacheController clearCache];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 1) {
        if(buttonIndex == 1) {
            [self doApplicationLogout];
        }
    } else if (alertView.tag == 2) {
        [self ratingAlertView:alertView clickedButtonAtIndex:buttonIndex];
    }
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    [AnalyticsManager trackEventName:@"clickTabBar"
                            category:GA_EVENT_CATEGORY_TAB_BAR
                              action:GA_EVENT_ACTION_CLICK
                               label:tabBarController.tabBar.selectedItem.title];
    static UIViewController *previousController = nil;
    if (previousController == viewController) {
        [[NSNotificationCenter defaultCenter] postNotificationName:TKPDUserDidTappedTapBar object:nil userInfo:nil];
    }
    previousController = viewController;

}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    return YES;
}

-(void)redirectViewController:(id)viewController {
    
}

- (void)redirectToSearch {
    _tabBarController.selectedIndex = 2;
}

- (void)redirectToHotlist {
    _tabBarController.selectedIndex = 1;
}

#pragma mark - Logout Controller
-(LogoutRequestParameter*) logoutObjectRequest{
    LogoutRequestParameter *object = [LogoutRequestParameter new];
    object.deviceTokenID = [_userManager getMyDeviceIdToken];
    object.deviceID = [_userManager getMyDeviceToken]; //token device from ios
    return object;
}

-(void)requestLogout{
    [LogoutRequest fetchLogout:[self logoutObjectRequest] onSuccess:^(LogoutResult * data) {}];
}

- (void)redirectNotification:(NSNotification*)notification {
    _tabBarController.selectedIndex = 0;
    for(UIViewController *viewController in _tabBarController.viewControllers) {
        if([viewController isKindOfClass:[UINavigationController class]]) {
            [(UINavigationController *)viewController popToRootViewControllerAnimated:NO];
        }
    }
    
}

#pragma mark - Notification Observer Method
- (void)forceLogout {
    // Need to use new UserAuthentificationManager becase the old one has wrong device token
    _persistToken = [[UserAuthentificationManager new] getMyDeviceToken]; //token device from ios
    [self doApplicationLogout];
}

- (void)didRefreshContainer:(NSTimer*)timer {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    TAGContainer *container = appDelegate.container;
    [container refresh];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"didRefreshGTM" object:nil];
}

- (void)didReceiveShowRatingNotification:(NSNotification *)notification {
    if ([[notification userInfo] objectForKey:kTKPD_ALWAYS_SHOW_RATING_ALERT]) {
        if ([[[notification userInfo] objectForKey:kTKPD_ALWAYS_SHOW_RATING_ALERT] boolValue]) {
            [self showRatingAlertFromNotification:notification];
        }
    } else {
        [self checkUserRating:notification];
    }
}

- (void)checkUserRating:(NSNotification *)notification {
    _userManager = [UserAuthentificationManager new];
    // Reviews data structure
    // ReviewData (Dictionary containing belows data)
    //   -> UserIds (Array containing user ids that already rated the app)
    //   -> UsersDueDates (Dictionary consist of user ids and due dates)
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *reviewData = [defaults objectForKey:kTKPD_USER_REVIEW_DATA];
    if (reviewData) {
        reviewData = [reviewData mutableCopy];
        NSMutableArray *userids = [reviewData objectForKey:kTKPD_USER_REVIEW_IDS];
        if (userids) {
            userids = [userids mutableCopy];
            if (![userids containsObject:_userManager.getUserId]) {
                NSMutableDictionary *dueDates = [reviewData objectForKey:kTKPD_USER_REVIEW_DUE_DATE];
                if (dueDates) {
                    dueDates = [dueDates mutableCopy];
                    NSDate *userDueDate = [dueDates objectForKey:_userManager.getUserId];
                    if (userDueDate) {
                        NSDate *today = [NSDate new];
                        if (today.timeIntervalSince1970 >= userDueDate.timeIntervalSince1970) {
                            [self showRatingAlertFromNotification:notification];
                        }
                    } else {
                        [self showRatingAlertFromNotification:notification];
                    }
                } else {
                    NSMutableDictionary *newUsersDueDates = [NSMutableDictionary new];
                    [reviewData setObject:newUsersDueDates forKey:kTKPD_USER_REVIEW_DUE_DATE];
                    [self showRatingAlertFromNotification:notification];
                }
            }
        } else {
            NSMutableArray *newUserIds = [NSMutableArray new];
            [reviewData setObject:newUserIds forKey:kTKPD_USER_REVIEW_IDS];
            if (![reviewData objectForKey:kTKPD_USER_REVIEW_DUE_DATE]) {
                NSMutableDictionary *dueDates = [NSMutableDictionary new];
                [reviewData setObject:dueDates forKey:kTKPD_USER_REVIEW_DUE_DATE];
            }
            [self showRatingAlertFromNotification:notification];
        }
    } else {
        NSMutableDictionary *newReviewData = [NSMutableDictionary new];
        NSMutableArray *newUserIds = [NSMutableArray new];
        NSMutableDictionary *newUsersDueDates = [NSMutableDictionary new];
        [newReviewData setObject:newUserIds forKey:kTKPD_USER_REVIEW_IDS];
        [newReviewData setObject:newUsersDueDates forKey:kTKPD_USER_REVIEW_DUE_DATE];
        reviewData = newReviewData;
        [self showRatingAlertFromNotification:notification];
    }
    [defaults setObject:reviewData forKey:kTKPD_USER_REVIEW_DATA];
    [defaults synchronize];
}

- (void)showRatingAlertFromNotification:(NSNotification *)notification {
    NSString *title = @"Suka dengan aplikasi iOS Tokopedia?";
    NSString *message = @"Rate 5 bintang untuk aplikasi ini. Setiap rating yang kalian berikan adalah semangat bagi kami! Terima kasih Toppers.";
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"Tidak"
                                          otherButtonTitles:@"Ya", nil];

    if ([[notification userInfo] objectForKey:kTKPD_ALWAYS_SHOW_RATING_ALERT]) {
        if ([[[notification userInfo] objectForKey:kTKPD_ALWAYS_SHOW_RATING_ALERT] boolValue]) {
            alert.tag = 1;
        }
    } else {
        alert.tag = 2;
    }
    alert.delegate = self;
    [alert show];
}

- (void)ratingAlertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 1) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kTKPD_ITUNES_APP_URL]];
    }
    else if (alertView.tag == 2) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSMutableDictionary *reviewData = [[defaults objectForKey:kTKPD_USER_REVIEW_DATA] mutableCopy];
        if (buttonIndex == 0) {
            NSMutableDictionary *dueDates = [[reviewData objectForKey:kTKPD_USER_REVIEW_DUE_DATE] mutableCopy];
            NSDate *today = [NSDate date];
            int daysInterval = 7;
            NSDate *nextWeek = [today dateByAddingTimeInterval:60*60*24*daysInterval];
            [dueDates setObject:nextWeek forKey:_userManager.getUserId];
            [reviewData setObject:dueDates forKey:kTKPD_USER_REVIEW_DUE_DATE];
        } else if (buttonIndex == 1) {
            NSMutableArray *userids = [[reviewData objectForKey:kTKPD_USER_REVIEW_IDS] mutableCopy];
            [userids addObject:_userManager.getUserId];
            [reviewData setObject:userids forKey:kTKPD_USER_REVIEW_IDS];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kTKPD_ITUNES_APP_URL]];
        }
        [defaults setObject:reviewData forKey:kTKPD_USER_REVIEW_DATA];
        [defaults synchronize];
    }
}

- (void)redirectToHomeViewController {
    _tabBarController.selectedIndex = 0;
}

- (void) navigateToPageInTabBar:(NSNotification*) notification{
    NSString *pageId = [notification object];
    int pagenum = [pageId intValue];
    _tabBarController.selectedIndex = pagenum;
}

// MARK: TKPAppFlow methods

- (TKPStoreManager *)storeManager {
    if (_storeManager == nil) {
        _storeManager = [[TKPStoreManager alloc] init];
    }
    return _storeManager;
}

// MARK: Reinit Cart TabBar

- (void) reinitCartTabBar {
    UINavigationController *transactionCartRootNavController = [_tabBarController.viewControllers objectAtIndex: 3];
    if ([[transactionCartRootNavController.viewControllers objectAtIndex:0] isKindOfClass:[TransactionCartRootViewController class]]) {
        TransactionCartRootViewController *transactionCartRootVC = (TransactionCartRootViewController *)[transactionCartRootNavController.viewControllers objectAtIndex:0];
        
        // Pakai remove observer karena iOS 7 tidak mau otomatis remove observer ketika TransactionCartRootVC dealloc
        [[NSNotificationCenter defaultCenter]removeObserver:transactionCartRootVC];
        [transactionCartRootNavController setViewControllers:[NSArray arrayWithObject: [TransactionCartRootViewController new]]];
    }
}



@end
