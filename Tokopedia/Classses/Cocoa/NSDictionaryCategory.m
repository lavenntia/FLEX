//
//  NSDictionaryCategory.m
//  Tokopedia
//
//  Created by IT Tkpd on 10/29/14.
//  Copyright (c) 2014 TOKOPEDIA. All rights reserved.
//

#import "NSDictionaryCategory.h"
#import "NSData+Encryption.h"
#import "UserAuthentificationManager.h"
#import "EncodeDecoderManager.h"


@implementation NSDictionary (tkpdcategory)

- (BOOL)isMutable
{
	@try {
		[(id)self setObject:@"" forKey:@""];	//TODO: unique key...
		[(id)self removeObjectForKey:@""];
		return YES;
	}
	@catch (NSException *exception) {
		return NO;
	}
	//@finally {
	//}
    return YES;
}


- (NSDictionary *)encrypt
{
    if ([self isKindOfClass:[NSDictionary class]]) {
        UserAuthentificationManager *userManager = [UserAuthentificationManager new];
        EncodeDecoderManager *encodeDecodeManager = [EncodeDecoderManager new];
        
        NSString *encryptedParam = [userManager addParameterAndConvertToString:self];
        NSString *encodedKey   = encodeDecodeManager.encryptKeyAndIv;
        NSString *encodedParam = [encodeDecodeManager encryptParams:encryptedParam];
        NSDictionary *keyAndParam = @{@"key" : encodedKey, @"param" : encodedParam};
        
        return keyAndParam;
    }
    return nil;
}

@end
