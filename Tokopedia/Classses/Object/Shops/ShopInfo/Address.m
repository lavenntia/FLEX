//
//  Address.m
//  Tokopedia
//
//  Created by IT Tkpd on 9/9/14.
//  Copyright (c) 2014 TOKOPEDIA. All rights reserved.
//

#import "Address.h"

@implementation Address

- (NSString *)location_phone {
    if ([_location_phone isEqualToString:@"0"]) {
        return nil;
    } else {
        return _location_phone;
    }
}

@end
