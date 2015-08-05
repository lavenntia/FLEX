//
//  SegmentedReviewReputationViewController.m
//  Tokopedia
//
//  Created by Tokopedia on 7/7/15.
//  Copyright (c) 2015 TOKOPEDIA. All rights reserved.
//
#import "MyReviewReputationViewController.h"
#import "SegmentedReviewReputationViewController.h"
#define CInboxReputation @"inbox-reputation"
#define CInboxReputationMyProduct @"inbox-reputation-my-product"
#define CInboxReputationMyReview @"inbox-reputation-my-review"

@interface SegmentedReviewReputationViewController ()

@end

@implementation SegmentedReviewReputationViewController
{
    MyReviewReputationViewController *allReviewViewController, *myProductViewController, *myReviewViewController;
    UIButton *btnTitle;
    NSString *selectedFilter;
    UIImage *arrowImage;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initNavigation];
    selectedFilter = CTagSemuaReview;
}

- (void)viewWillAppear:(BOOL)animated
{
    if(viewContent.subviews.count == 0) {
        [viewContent setNeedsLayout];
        [viewContent layoutIfNeeded];
        [self actionValueChange:segmentedControl];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Method
- (void)initNavigation
{
    btnTitle = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnTitle setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btnTitle.titleLabel.font = [self.navigationController.navigationBar.titleTextAttributes objectForKey:NSFontAttributeName];
    btnTitle.backgroundColor = [UIColor clearColor];
    [btnTitle addTarget:self action:@selector(actionChangeFilter:) forControlEvents:UIControlEventTouchUpInside];

    self.navigationItem.titleView = btnTitle;
    [self.navigationItem.titleView sizeToFit];
}

- (void)setNavigationTitle:(NSString *)strTitle {
    if([strTitle isEqualToString:CTagBelumDibaca]) {
        strTitle = btnBelumDibaca.titleLabel.text;
        selectedFilter = CTagBelumDibaca;
    }
    else if([strTitle isEqualToString:CTagSemuaReview]) {
        strTitle = btnAllReview.titleLabel.text;
        selectedFilter = CTagSemuaReview;
    }
    else if([strTitle isEqualToString:CtagBelumDireviw]) {
        strTitle = btnBelumDireview.titleLabel.text;
        selectedFilter = CtagBelumDireviw;
    }
    
    if(arrowImage == nil) {
        arrowImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon_triangle_down_white" ofType:@"png"]];
        CGRect rect = CGRectMake(0, 0, 10 ,7);
        UIGraphicsBeginImageContext( rect.size );
        [arrowImage drawInRect:rect];
        arrowImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        UILabel *lblTemp = [[UILabel alloc] initWithFrame:CGRectZero];
        lblTemp.textColor = btnTitle.titleLabel.textColor;
        lblTemp.font = btnTitle.titleLabel.font;
        lblTemp.text = strTitle;
        CGSize tempSize = [lblTemp sizeThatFits:CGSizeMake(320, 999)];
        btnTitle.frame = CGRectMake(0, 0, tempSize.width+30, self.navigationController.navigationBar.bounds.size.height);
    }
    
    
    [btnTitle setTitle:strTitle forState:UIControlStateNormal];
    [btnTitle setImage:arrowImage forState:UIControlStateNormal];
    btnTitle.titleEdgeInsets = UIEdgeInsetsMake(0, -btnTitle.imageView.frame.size.width-5, 0, btnTitle.imageView.frame.size.width+5);
    btnTitle.imageEdgeInsets = UIEdgeInsetsMake(0, btnTitle.titleLabel.frame.size.width, 0, -btnTitle.titleLabel.frame.size.width);

    [self.navigationItem.titleView sizeToFit];
}

- (int)getSelectedSegmented {
    return (int)segmentedControl.selectedSegmentIndex;
}

- (MyReviewReputationViewController *)getSegmentedViewController {
    switch (segmentedControl.selectedSegmentIndex) {
        case CTagSemua:
        {
            return allReviewViewController;
        }
            break;
        case CTagProductSaya:
        {
            return myProductViewController;
        }
            break;
        case CTagReviewSaya:
        {
            return myReviewViewController;
        }
            break;
    }
    
    return nil;
}

- (NSString *)getSelectedFilter {
    return selectedFilter;
}

- (void)hiddenShadowFilter:(BOOL)isHidden {
    viewShadow.hidden = viewContentAction.hidden = isHidden;
//    [btnTitle setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:(isHidden? @"icon_arrow_down_white":@"icon_arrow_up") ofType:@"png"]] forState:UIControlStateNormal];
}

#pragma mark - Action 
- (void)actionChangeFilter:(id)sender {
    [self hiddenShadowFilter:!viewShadow.isHidden];
    
    if([selectedFilter isEqualToString:CTagBelumDibaca]) {
        constTopCheckList.constant = btnBelumDibaca.frame.origin.y+5;
    }
    else if([selectedFilter isEqualToString:CTagSemuaReview]) {
        constTopCheckList.constant = btnAllReview.frame.origin.y+5;
    }
    else if([selectedFilter isEqualToString:CtagBelumDireviw]) {
        constTopCheckList.constant = btnBelumDireview.frame.origin.y+5;
    }
}

- (IBAction)actionReview:(id)sender {
    selectedFilter = CTagSemuaReview;
    [self hiddenShadowFilter:YES];
    [self setNavigationTitle:selectedFilter];
    
    switch (segmentedControl.selectedSegmentIndex) {
        case CTagSemua:
        {
            [allReviewViewController actionReview:sender];
        }
            break;
        case CTagProductSaya:
        {
            [myProductViewController actionReview:sender];
        }
            break;
        case CTagReviewSaya:
        {
            [myReviewViewController actionReview:sender];
        }
            break;
    }
}

- (IBAction)actionBelumDibaca:(id)sender {
    selectedFilter = CTagBelumDibaca;
    [self hiddenShadowFilter:YES];
    [self setNavigationTitle:selectedFilter];
    
    switch (segmentedControl.selectedSegmentIndex) {
        case CTagSemua:
        {
            [allReviewViewController actionBelumDibaca:sender];
        }
            break;
        case CTagProductSaya:
        {
            [myProductViewController actionBelumDibaca:sender];
        }
            break;
        case CTagReviewSaya:
        {
            [myReviewViewController actionBelumDibaca:sender];
        }
            break;
    }
}
- (IBAction)actionBelumDireview:(id)sender {
    selectedFilter = CtagBelumDireviw;
    [self hiddenShadowFilter:YES];
    [self setNavigationTitle:selectedFilter];
    
    switch (segmentedControl.selectedSegmentIndex) {
        case CTagSemua:
        {
            [allReviewViewController actionBelumDireview:sender];
        }
            break;
        case CTagProductSaya:
        {
            [myProductViewController actionBelumDireview:sender];
        }
            break;
        case CTagReviewSaya:
        {
            [myReviewViewController actionBelumDireview:sender];
        }
            break;
    }
}

- (IBAction)actionValueChange:(id)sender {
    for(UIView *subView in viewContent.subviews) {
        [subView removeFromSuperview];
    }
    [viewContent removeConstraints:viewContent.constraints];
    [allReviewViewController removeFromParentViewController];
    [myProductViewController removeFromParentViewController];
    [myReviewViewController removeFromParentViewController];
    
    switch (((UISegmentedControl *) sender).selectedSegmentIndex) {
        case CTagSemua:
        {
            if(allReviewViewController == nil) {
                allReviewViewController = [MyReviewReputationViewController new];
                allReviewViewController.strNav = CInboxReputation;
            }
            [self addChildViewController:allReviewViewController];
            [viewContent addSubview:allReviewViewController.view];

            UIView *tempView = allReviewViewController.view;
            [viewContent addConstraint:[NSLayoutConstraint constraintWithItem:tempView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:viewContent attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0]];
            [viewContent addConstraint:[NSLayoutConstraint constraintWithItem:tempView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:viewContent attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0]];
            [viewContent addConstraint:[NSLayoutConstraint constraintWithItem:tempView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:viewContent attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
            [viewContent addConstraint:[NSLayoutConstraint constraintWithItem:tempView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:viewContent attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
            
//            [tempView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[tempView(==%f)]", viewContent.bounds.size.height] options:0 metrics:0 views:NSDictionaryOfVariableBindings(tempView)]];
//            [tempView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:[tempView(==%f)]", viewContent.bounds.size.width] options:0 metrics:0 views:NSDictionaryOfVariableBindings(tempView)]];
            
//            if(SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(@"7.1.2"))
                tempView.frame = CGRectMake(0, 0, self.view.bounds.size.width, viewContent.bounds.size.height);
        }
            break;
        case CTagProductSaya:
        {
            if(myProductViewController == nil) {
                myProductViewController = [MyReviewReputationViewController new];
                myProductViewController.strNav = CInboxReputationMyProduct;
            }
            [self addChildViewController:myProductViewController];
            [viewContent addSubview:myProductViewController.view];

            UIView *tempView = myProductViewController.view;
            [viewContent addConstraint:[NSLayoutConstraint constraintWithItem:tempView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:viewContent attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0]];
            [viewContent addConstraint:[NSLayoutConstraint constraintWithItem:tempView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:viewContent attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0]];
            [viewContent addConstraint:[NSLayoutConstraint constraintWithItem:tempView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:viewContent attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
            [viewContent addConstraint:[NSLayoutConstraint constraintWithItem:tempView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:viewContent attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
            
//            [tempView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[tempView(==%f)]", viewContent.bounds.size.height] options:0 metrics:0 views:NSDictionaryOfVariableBindings(tempView)]];
//            [tempView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:[tempView(==%f)]", viewContent.bounds.size.width] options:0 metrics:0 views:NSDictionaryOfVariableBindings(tempView)]];
//            
//            if(SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(@"7.1.2"))
                tempView.frame = CGRectMake(0, 0, self.view.bounds.size.width, viewContent.bounds.size.height);
        }
            break;
        case CTagReviewSaya:
        {
            if(myReviewViewController == nil) {
                myReviewViewController = [MyReviewReputationViewController new];
                myReviewViewController.strNav = CInboxReputationMyReview;
            }
            [self addChildViewController:myReviewViewController];
            [viewContent addSubview:myReviewViewController.view];
            
            UIView *tempView = myReviewViewController.view;
            [viewContent addConstraint:[NSLayoutConstraint constraintWithItem:tempView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:viewContent attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0]];
            [viewContent addConstraint:[NSLayoutConstraint constraintWithItem:tempView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:viewContent attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0]];
            [viewContent addConstraint:[NSLayoutConstraint constraintWithItem:tempView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:viewContent attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
            [viewContent addConstraint:[NSLayoutConstraint constraintWithItem:tempView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:viewContent attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
            
//            [tempView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[tempView(==%f)]", viewContent.bounds.size.height] options:0 metrics:0 views:NSDictionaryOfVariableBindings(tempView)]];
//            [tempView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:[tempView(==%f)]", viewContent.bounds.size.width] options:0 metrics:0 views:NSDictionaryOfVariableBindings(tempView)]];
//            
//            
//            if(SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(@"7.1.2"))
                tempView.frame = CGRectMake(0, 0, self.view.bounds.size.width, viewContent.bounds.size.height);
        }
            break;
    }
}
@end
