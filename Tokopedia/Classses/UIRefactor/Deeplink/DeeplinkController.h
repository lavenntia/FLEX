//
//  DeeplinkController.h
//  Tokopedia
//
//  Created by Tonito Acen on 9/10/15.
//  Copyright (c) 2015 TOKOPEDIA. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DeeplinkControllerDelegate <NSObject>

@required
- (NSURL*)sanitizedURL;

@end

@interface DeeplinkController : NSObject {
    TAGContainer *_gtmContainer;
    NSURL *_sanitizedURL;
}

@property (weak, nonatomic) id<DeeplinkControllerDelegate> delegate;

- (BOOL)shouldRedirectToWebView;

- (void)redirectToAppsViewController:(NSString*)url;
- (void)redirectToWebViewController;
- (void)doRedirect;

+ (BOOL)handleURL:(NSURL *)url
sourceApplication:(NSString *)sourceApplication
       annotation:(id)annotation;

@end
