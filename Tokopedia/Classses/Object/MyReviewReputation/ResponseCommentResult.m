//
//  ResponseCommentResult.m
//  Tokopedia
//
//  Created by Tokopedia on 7/15/15.
//  Copyright (c) 2015 TOKOPEDIA. All rights reserved.
//

#import "ResponseCommentResult.h"

@implementation ResponseCommentResult

- (NSString*)shop_name {
    return [_shop_name kv_decodeHTMLCharacterEntities];
}

@end
