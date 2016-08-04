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
    return FBTweakValue(@"Network", @"Environment", @"Tokopedia Base Url", @"http://www.tokopedia.com/ws",
                        (@{
                           @"http://staging.tokopedia.com/ws" : @"Staging",
                           @"http://alpha.tokopedia.com/ws" : @"Alpha",
                           @"http://www.tokopedia.com/ws" : @"Production",
                           FBTweakValue(@"Network", @"Developer's", @"NDVL Base Url", @"http://lo-lucky.ndvl/ws") : @"Developer's"
                           }
                         ));
}


+ (NSString*)aceUrl {
    return  FBTweakValue(@"Network", @"Environment", @"Tokopedia Ace Url", @"https://ace.tokopedia.com",
                         (@{
                            @"https://ace-staging.tokopedia.com" : @"Staging",
                            @"https://ace-alpha.tokopedia.com" : @"Alpha",
                            @"https://ace.tokopedia.com" : @"Production",
                            }
                          ));
    
}

+ (NSString*)v4Url {
    return  FBTweakValue(@"Network", @"Environment", @"Tokopedia v4 Url", @"https://ws.tokopedia.com",
                         (@{
                            @"https://ws-staging.tokopedia.com" : @"Staging",
                            @"https://ws-alpha.tokopedia.com" : @"Alpha",
                            @"https://ws.tokopedia.com" : @"Production",
                            }
                          ));
}

+ (NSString*)topAdsUrl {
    return  FBTweakValue(@"Network", @"Environment", @"Tokopedia TopAds Url", @"https://ta.tokopedia.com",
                         (@{
                            @"https://ta-staging.tokopedia.com" : @"Staging",
                            @"https://ta-alpha.tokopedia.com" : @"Alpha",
                            @"https://ta.tokopedia.com" : @"Production",
                            }
                          ));
}


+ (NSString*)keroUrl {
    return  FBTweakValue(@"Network", @"Environment", @"Tokopedia Kero Url", @"https://kero.tokopedia.com",
                         (@{
                            @"https://kero-staging.tokopedia.com" : @"Staging",
                            @"https://kero-alpha.tokopedia.com" : @"Alpha",
                            @"https://kero.tokopedia.com" : @"Production",
                            }
                          ));
}

+ (NSString*)hadesUrl {
    return  FBTweakValue(@"Network", @"Environment", @"Tokopedia Hades Url", @"https://hades.tokopedia.com",
                         (@{
                            @"https://hades-staging.tokopedia.com" : @"Staging",
                            @"https://hades-alpha.tokopedia.com" : @"Alpha",
                            @"https://hades.tokopedia.com" : @"Production",
                            }
                          ));
}

+ (NSString*)mojitoUrl {
    return  FBTweakValue(@"Network", @"Environment", @"Tokopedia Mojito Url", @"https://mojito.tokopedia.com",
                         (@{
                            @"https://mojito-staging.tokopedia.com" : @"Staging",
                            @"https://mojito.tokopedia.com" : @"Production",
                            }
                          ));
}

@end
