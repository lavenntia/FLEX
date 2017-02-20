//
//  LoginViewController.h
//  tokopedia
//
//  Created by IT Tkpd on 8/14/14.
//  Copyright (c) 2014 TOKOPEDIA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GoogleSignIn/GoogleSignIn.h>
#import "Login.h"

@protocol LoginViewDelegate <NSObject>

@optional
- (void)redirectViewController:(id)viewController;
- (void)cancelLoginView;
- (void)didLoginSuccess:(LoginResult*) login;

@end

@interface LoginViewController : GAITrackedViewController <UITextFieldDelegate, GIDSignInDelegate, GIDSignInUIDelegate>

@property (strong,nonatomic) NSDictionary *data;
@property BOOL isPresentedViewController;
@property (weak, nonatomic) id<LoginViewDelegate> delegate;
@property (weak, nonatomic) id redirectViewController;
@property BOOL triggerPhoneVerification;
@property(strong, nonatomic) NSString* url;

- (void)navigateToRegister;

@end
