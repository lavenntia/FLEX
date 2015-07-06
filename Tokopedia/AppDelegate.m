//
//  AppDelegate.m
//  Tokopedia
//
//  Created by IT Tkpd on 8/19/14.
//  Copyright (c) 2014 TOKOPEDIA. All rights reserved.
//
#import <AFNetworking/AFNetworking.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <FacebookSDK/FacebookSDK.h>
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

#import "AppDelegate.h"
#import "MainViewController.h"
#import "TKPDSecureStorage.h"
#import "AppsFlyerTracker.h"
#import "ChangeMessageUrlTagHandler.h"



@interface AppDelegate ()<TAGContainerOpenerNotifier>

@end

@implementation AppDelegate

@synthesize viewController = _viewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [application setStatusBarStyle:UIStatusBarStyleLightContent];
    
    _viewController = [MainViewController new];
    _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    _window.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    _window.backgroundColor = kTKPDNAVIGATION_NAVIGATIONBGCOLOR;
    _window.rootViewController = _viewController;
    [_window makeKeyAndVisible];
    
    _tagManager = [TAGManager instance];
    [_tagManager.logger setLogLevel:kTAGLoggerLogLevelVerbose];
    
    
//    id<TAGContainerFuture> future = [TAGContainerOpener openContainerWithId:@"GTM-NCTWRP"   // Update with your Container ID.
//                                                                 tagManager:self.tagManager
//                                                                   openType:kTAGOpenTypePreferFresh
//                                                                    timeout:nil
//                                                                   notifier:self];
    
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        //Open container GTM
        id<TAGContainerFuture> future = [TAGContainerOpener openContainerWithId:@"GTM-NCTWRP"    // Placeholder Container ID.
                                                                     tagManager:[TAGManager instance]
                                                                       openType:kTAGOpenTypePreferFresh
                                                                        timeout:nil];
        
        self.container = [future get];
        [self registerFunctionCallTags];
        
        //appsflyer init
        [AppsFlyerTracker sharedTracker].appsFlyerDevKey = @"SdSopxGtYr9yK8QEjFVHXL";
        [AppsFlyerTracker sharedTracker].appleAppID = @"1001394201";
        [AppsFlyerTracker sharedTracker].currencyCode = @"IDR";
        
        //fabric init
        [Fabric with:@[CrashlyticsKit]];
        
        //push notification init
        if ([application respondsToSelector:@selector(isRegisteredForRemoteNotifications)]) {
            // iOS 8 Notifications
            [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
            [application registerForRemoteNotifications];
        }
        else {
            // iOS < 8 Notifications
            [application registerForRemoteNotificationTypes:
             (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)];
        }
        
        //Google Analytics init
        [GAI sharedInstance].trackUncaughtExceptions = YES;
//        [[GAI sharedInstance].logger setLogLevel:kGAILogLevelVerbose];
        [GAI sharedInstance].dispatchInterval = 60;
        [[GAI sharedInstance] trackerWithTrackingId:GATrackingId];
        [[[GAI sharedInstance] trackerWithTrackingId:GATrackingId] setAllowIDFACollection:YES];
        [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
        [self preparePersistData];
    });
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [FBAppEvents activateApp];
    [[AppsFlyerTracker sharedTracker]trackAppLaunch];
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    TKPDSecureStorage* secureStorage = [TKPDSecureStorage standardKeyChains];
    
    NSString *deviceTokenString = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    deviceTokenString = [deviceTokenString stringByReplacingOccurrencesOfString:@" " withString:@""];
    [secureStorage setKeychainWithValue:deviceTokenString withKey:kTKPD_DEVICETOKENKEY];
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    //opened when application is on background
    if(application.applicationState == UIApplicationStateInactive ||
       application.applicationState == UIApplicationStateBackground) {
        [[NSNotificationCenter defaultCenter] postNotificationName:TokopediaNotificationRedirect object:nil userInfo:userInfo];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:TokopediaNotificationReload object:self];
    }
}


- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    
    return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
}


#pragma mark - reset persist data if freshly installed
- (void)preparePersistData
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary* application = [defaults dictionaryForKey:kTKPD_APPLICATIONKEY];
    
    BOOL isInstalled = [[application objectForKey:kTKPD_INSTALLEDKEY]boolValue];
    if (!isInstalled) {
        NSMutableDictionary* mutable = (application != nil) ? [application mutableCopy] : [[NSMutableDictionary alloc] initWithCapacity:1];
        [mutable setValue:@(YES) forKey:kTKPD_INSTALLEDKEY];
        [defaults setObject:mutable forKey:kTKPD_APPLICATIONKEY];
        
        TKPDSecureStorage* storage = [TKPDSecureStorage standardKeyChains];
        [storage resetKeychain];
    }
}

- (void)containerAvailable:(TAGContainer *)container {
    // Note that containerAvailable may be called on any thread, so you may need to dispatch back to
    // your main thread.
    dispatch_async(dispatch_get_main_queue(), ^{
        self.container = container;
    });
}

#pragma mark - Other Method
- (void)registerFunctionCallTags {
    [self.container registerFunctionCallTagHandler:[[ChangeMessageUrlTagHandler alloc] init] forTag:@"ChangeMessageUrl"];
}

@end
