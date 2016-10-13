//
//  MyWishlistMojitoResponse.h
//  Tokopedia
//
//  Created by Billion Goenawan on 9/23/16.
//  Copyright © 2016 TOKOPEDIA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Paging.h"

@interface MyWishlistMojitoResponse : NSObject <TKPObjectMapping>
    @property (nonatomic, strong) NSArray *data;
    @property (nonatomic, strong) Paging *pagination;
@end
