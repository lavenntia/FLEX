//
//  TKPDTabViewController.h
//  Tokopedia
//
//  Created by Feizal Badri Asmoro on 5/22/15.
//  Copyright (c) 2015 TOKOPEDIA. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TKPDTabViewDelegate <NSObject>

- (void)segmentController:(UISegmentedControl *)segmentedController didSelectSegmentAtIndex:(NSInteger)index;

@end

@interface TKPDTabViewController : UIViewController

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UIView *containerView;

@property (strong, nonatomic) NSArray *viewControllers;
@property (strong, nonatomic) NSArray *tabTitles;

@property (weak, nonatomic) id<TKPDTabViewDelegate> delegate;

@end
