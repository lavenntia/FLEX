//
//  ReviewResponse.m
//  Tokopedia
//
//  Created by IT Tkpd on 9/25/14.
//  Copyright (c) 2014 TOKOPEDIA. All rights reserved.
//

#import "ReviewResponse.h"

@implementation ReviewResponse

- (NSString*)response_message {
    return [_response_message kv_decodeHTMLCharacterEntities];
}

@end
