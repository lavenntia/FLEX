//
//  CloseShopResponse.m
//  Tokopedia
//
//  Created by Johanes Effendi on 5/17/16.
//  Copyright © 2016 TOKOPEDIA. All rights reserved.
//

#import "CloseShopResponse.h"

@implementation CloseShopResponse
+(RKObjectMapping *)mapping{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[CloseShopResponse class]];
    [mapping addAttributeMappingsFromArray:@[@"message_error", @"status",@"server_process_time"]];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"data"
                                                                            toKeyPath:@"data"
                                                                          withMapping:[CloseShopResult mapping]]];
    
    return mapping;
}
@end
