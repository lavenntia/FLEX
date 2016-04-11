//
//  NSString+TPBaseUrl.m
//  Tokopedia
//
//  Created by Tonito Acen on 3/24/16.
//  Copyright © 2016 TOKOPEDIA. All rights reserved.
//

#import "NSString+TPBaseUrl.h"

@implementation NSString (TPBaseUrl)

+ (NSString*)basicUrl {
    return FBTweakValue(@"General", @"Environment", @"Tokopedia Base Url", @"http://www.tokopedia.com/ws",
                        (@{
                           @"http://staging.tokopedia.com/ws" : @"Staging",
                           @"http://alpha.tokopedia.com/ws" : @"Alpha",
                           @"http://www.tokopedia.com/ws" : @"Production",
                           FBTweakValue(@"General", @"Developer's", @"NDVL Base Url", @"http://lo-lucky.ndvl/ws") : @"Developer's"
                           }
                         ));
}


+ (NSString*)aceUrl {
    return  FBTweakValue(@"General", @"Environment", @"Tokopedia Ace Url", @"https://ace.tokopedia.com",
                         (@{
                            @"https://ace-staging.tokopedia.com" : @"Staging",
                            @"https://ace-alpha.tokopedia.com" : @"Alpha",
                            @"https://ace.tokopedia.com" : @"Production",
                            }
                          ));
    
}

+ (NSString*)v4Url {
    return  FBTweakValue(@"General", @"Environment", @"Tokopedia v4 Url", @"https://ws.tokopedia.com",
                         (@{
                            @"https://ws-staging.tokopedia.com" : @"Staging",
                            @"https://ws-alpha.tokopedia.com" : @"Alpha",
                            @"https://ws.tokopedia.com" : @"Production",
                            FBTweakValue(@"General", @"Developer's", @"NDVL Base Url", @"http://lo-lucky.ndvl/web-service") : @"Developer's"
                            }
                          ));
}

@end
