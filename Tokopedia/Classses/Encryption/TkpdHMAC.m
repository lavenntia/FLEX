//
//  TkpdHMAC.m
//  Tokopedia
//
//  Created by Tonito Acen on 8/25/15.
//  Copyright (c) 2015 TOKOPEDIA. All rights reserved.
//

#import "TkpdHMAC.h"
#import "UserAuthentificationManager.h"
#import "NSString+MD5.h"

#include <CommonCrypto/CommonDigest.h>
#include <CommonCrypto/CommonHMAC.h>

@implementation TkpdHMAC

- (id)init {
    self = [super init];
    
    _userManager = [UserAuthentificationManager new];
    
    return self;
}

- (NSString *)generateTokenRatesPath:(NSString*)path withUnixTime:(NSString*)unixTime{
    NSString *secret = @"Keroppi";
    NSString *stringToSign = [NSString stringWithFormat:@"%@\n%@\n%@\n%@\n/%@", @"GET", @"", @"", unixTime, path];
    return [self getOutputFromString:stringToSign srcret:secret];
}

-(NSString *)getOutputFromString:(NSString *)stringToSign srcret:(NSString*)secret
{
    const char *cKey = [secret cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [stringToSign cStringUsingEncoding:NSUTF8StringEncoding];
    
    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
    NSString *output = [self base64forData:HMAC];
    
    return output;
}

- (NSString *)generateSignatureWithMethod:(NSString*)method tkpdPath:(NSString*)path parameter:(NSDictionary*)parameter{
    NSString *output;
    NSString *secret = @"web_service_v4";
    
    //set request method
    [self setRequestMethod:method];
    [self setParameterMD5:parameter];
    [self setTkpdPath:path];
    [self setSecret:secret];

    NSString *stringToSign = [NSString stringWithFormat:@"%@\n%@\n%@\n%@\n%@", method, [self getParameterMD5], [self getContentType], [self getDate], [self getTkpdPath]];
//    NSString *stringToSign = @"POST\n1234567890asdfghjkl\napplication/x-www-form-urlencoded\nThu, 27 Aug 2015 17:59:05 +0700\n/v4/home/get_hotlist.pl";

    
    const char *cKey = [secret cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [stringToSign cStringUsingEncoding:NSUTF8StringEncoding];
    
    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
    output = [self base64forData:HMAC];
    
    return output;
}

// convert NSData to NSString
- (NSString*)base64forData:(NSData*)theData {
    const uint8_t* input = (const uint8_t*)[theData bytes];
    NSInteger length = [theData length];
    
    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
    
    NSMutableData* data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t* output = (uint8_t*)data.mutableBytes;
    
    NSInteger i;
    for (i=0; i < length; i += 3) {
        NSInteger value = 0;
        NSInteger j;
        for (j = i; j < (i + 3); j++) {
            value <<= 8;
            
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        
        NSInteger theIndex = (i / 3) * 4;
        output[theIndex + 0] =                    table[(value >> 18) & 0x3F];
        output[theIndex + 1] =                    table[(value >> 12) & 0x3F];
        output[theIndex + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
        output[theIndex + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
}

//============ getter setter

- (NSString*)getDate {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EE, dd MMM yyyy HH:mm:ss Z"];
    
    NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [dateFormatter setLocale:usLocale];
    
    NSString *todayString = [dateFormatter stringFromDate:[NSDate date]];
    
    return todayString;
}

- (void)setDate:(NSString*)date {
    _date = date;
}

- (NSString*)getContentType {
    return @"application/x-www-form-urlencoded";
}

- (void)setContentType:(NSString*)contentType {
    _contentType = contentType;
}

- (NSString*)getParameterMD5 {
    return _parameterMD5;
}

- (void)setParameterMD5:(NSDictionary*)parameter {
    NSError *error;
    NSData *parameterData = [NSJSONSerialization dataWithJSONObject:parameter options:NSJSONWritingPrettyPrinted error:&error];
    NSString *serializedParameter = [[NSString alloc] initWithData:parameterData encoding:NSUTF8StringEncoding];
    
    _parameterMD5 = [serializedParameter encryptWithMD5];
}

- (NSString*)getRequestMethod {
    return _requestMethod;
}

- (void)setRequestMethod:(NSString*)requestMethod {
    _requestMethod = requestMethod;
}

- (NSString*)getTkpdPath {
    return _tkpdPath;
}

- (void)setTkpdPath:(NSString*)tkpdPath {
    _tkpdPath = tkpdPath;
}

- (NSString*)getSecret {
    return _secret;
}

- (void)setSecret:(NSString*)secret {
    _secret = secret;
}

@end
