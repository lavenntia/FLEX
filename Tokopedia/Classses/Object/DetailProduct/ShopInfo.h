//
//  ShopInfo.h
//  Tokopedia
//
//  Created by IT Tkpd on 9/8/14.
//  Copyright (c) 2014 TOKOPEDIA. All rights reserved.
//

#import "ShopStats.h"
#import <Foundation/Foundation.h>

@interface ShopInfo : NSObject

@property (nonatomic, strong) NSString *shop_open_since;
@property (nonatomic, strong) NSString *shop_location;
@property (nonatomic) NSInteger shop_id;
@property (nonatomic, strong) NSString *shop_owner_last_login;
@property (nonatomic, strong) NSString *shop_tagline;
@property (nonatomic, strong) NSString *shop_name;
@property (nonatomic, strong) ShopStats *shop_stats;
@property (nonatomic) BOOL shop_already_favorited;
@property (nonatomic, strong) NSString *shop_description;
@property (nonatomic, strong) NSString *shop_avatar;
@property (nonatomic, strong) NSString *shop_total_favorit;
@property (nonatomic, strong) NSString *shop_cover;
@property (nonatomic, strong) NSString *shop_domain;


@end
