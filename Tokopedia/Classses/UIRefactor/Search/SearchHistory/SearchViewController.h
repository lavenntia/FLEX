//
//  SearchViewController.h
//  Tokopedia
//
//  Created by IT Tkpd on 8/21/14.
//  Copyright (c) 2014 TOKOPEDIA. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SearchViewController : GAITrackedViewController

@property (strong, nonatomic, setter = setData:) NSDictionary *data;
@property (strong, nonatomic) UISearchBar *searchBar;
@property (strong, nonatomic) UIViewController* presentController;

@end
