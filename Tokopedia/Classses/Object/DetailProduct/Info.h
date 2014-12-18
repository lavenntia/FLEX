//
//  Info.h
//  Tokopedia
//
//  Created by IT Tkpd on 9/8/14.
//  Copyright (c) 2014 TOKOPEDIA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Info : NSObject

@property (nonatomic, strong) NSString *product_weight_unit;
@property (nonatomic, strong) NSString *product_weight;
@property (nonatomic, strong) NSString *product_description;
@property (nonatomic, strong) NSString *product_price;
@property (nonatomic, strong) NSString *product_insurance;
@property (nonatomic, strong) NSString *product_condition;
@property (nonatomic) NSInteger product_min_order;
@property (nonatomic, strong) NSString *product_status;
@property (nonatomic, strong) NSString *product_last_update;
@property (nonatomic, strong) NSNumber *product_id;
@property (nonatomic) NSInteger product_price_alert;
@property (nonatomic, strong) NSString *product_name;
@property (nonatomic, strong) NSString *product_url;

@property (nonatomic, strong) NSString *product_currency_id;
@property (nonatomic, strong) NSString *product_currency;
@property (nonatomic, strong) NSString *product_etalase_id;
@property (nonatomic) NSInteger product_department_id;
@property (nonatomic) NSString *product_short_desc;
@property (nonatomic) NSInteger product_department_tree;
@property (nonatomic, strong) NSString *product_must_insurance;
@property (nonatomic) NSInteger product_returnable;

@end
