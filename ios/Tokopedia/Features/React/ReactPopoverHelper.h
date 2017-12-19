//
//  ReactPopoverHelper.h
//  Tokopedia
//
//  Created by Ferico Samuel on 21/11/17.
//  Copyright © 2017 TOKOPEDIA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>

@interface ReactPopoverHelper : NSObject<RCTBridgeModule>

@property (nonatomic, weak, readonly) RCTBridge *bridge;

@end
