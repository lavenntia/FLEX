//
//  ReportViewController.h
//  Tokopedia
//
//  Created by Tonito Acen on 3/31/15.
//  Copyright (c) 2015 TOKOPEDIA. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ReportViewControllerDelegate <NSObject>

@required
- (NSDictionary*)getParameter;
- (NSString*)getPath;

@end

@interface ReportViewController : UIViewController

@property (weak, nonatomic) id<ReportViewControllerDelegate> delegate;

@end
