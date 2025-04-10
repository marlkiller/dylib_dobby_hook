//
//  BoltAIHack.m
//  dylib_dobby_hook
//
//  Created by voidm on 2025/4/10.
//

#import <Foundation/Foundation.h>
#import "tinyhook.h"
#import "common_ret.h"
#import "HackProtocolDefault.h"
#import <objc/objc-exception.h>
#import "URLSessionHook.h"

#import "JSONUtils.h"

@interface BoltAIHack : HackProtocolDefault



@end

@implementation BoltAIHack

static IMP objectForKeyIMP;
static IMP dataTaskWithRequestIMP;

- (NSString *)getAppName {
    return @"co.podzim.BoltGPT";
}

- (NSString *)getSupportAppVersion {
    
    return @"1.";
}

- (id)hook_objectForKey:key{
    static NSDictionary *overrideDict = nil;
    static NSArray *keywords = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
       overrideDict = @{
//           LemonSqueezyAPIError(errors: nil, error: Optional("Missing `licenseKey`"))
           @"licenseKey":    @"11111111-1111-1111-1111-111111111111",
           @"deviceId":      @"22222222-2222-2222-2222-222222222222",
           @"deviceName":  @"BMW X6",
           @"customerName":  @"marlkiller",
           @"customerEmail": [Constant G_EMAIL_ADDRESS_FMT],
           @"isTrialLicense":  @NO,
           @"licenseCreateDate":  @"2020-01-24T14:15:07.000000Z", // https://docs.lemonsqueezy.com/api/license-api/validate-license-key
           @"licenseExpiryDate":  @"2050-01-24T14:15:07.000000Z",
           @"supportExpiryDate":  @"2050-01-24T14:15:07.000000Z",
           @"supportExpired":  @NO,
           // perpetual: 398295,397938,322322
           // perpetual productName: 398295,397938
           // productName plan 414510
           // variantName plan 200400
           @"licenseProductId": @200400,
           @"licenseProductName":  @"HUAWEI Mate XT ULTIMATE DESIGN",
           // 267335 267328,267329
           @"licenseVariantId": @267335,
           @"licenseVariantName":  @"Panamera GTS 4",
       };
       keywords = @[@"plan",@"product",@"date",@"license",@"store"];
    });
    id val = overrideDict[key];
    if (val) {
       NSLogger(@"[Override] %@ = %@", key, val);
       return val;
    }
    id ret = ((id(*)(id,SEL,id)) objectForKeyIMP)(self,_cmd,key);

    for (NSString *keyword in keywords) {
        if ([[key lowercaseString] containsString:[keyword lowercaseString]]) {
            NSLogger(@"[Hit Keyword] %@ = %@", key, val);
            break;
        }
    }
    return ret;
}

-(id) hook_dataTaskWithRequest:(NSURLRequest *)arg1{

    NSString *url = arg1.URL.absoluteString;
    NSDictionary *headers = arg1.allHTTPHeaderFields;
    NSMutableString *logString = [NSMutableString stringWithFormat:@"[HOOK] Request Info:\nURL: %@\nHeaders: %@\n", url, headers];
    NSData *body = arg1.HTTPBody;
    if (body) {
        NSString *bodyString = [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding];
        [logString appendFormat:@"Body: %@", bodyString];
    } else {
        [logString appendString:@"Body: <NULL>"];
    }
    NSLogger(@"%@", logString);
    if ([url containsString:@"/api.boltai.com/v1/license/"]) {
        NSLogger(@"[HOOK] Blocked request : %@",url);
        return nil;
    }
    return ((id(*)(id,SEL,id))dataTaskWithRequestIMP)(self,_cmd,arg1);
}


- (BOOL)hack {
    
    [self hook_AllSecCode:@"6D5N473QP3"];

    objectForKeyIMP = [MemoryUtils hookInstanceMethod:
                objc_getClass("NSUserDefaults")
                originalSelector:NSSelectorFromString(@"objectForKey:")
                swizzledClass:[self class]
                swizzledSelector:NSSelectorFromString(@"hook_objectForKey:")
    ];
    dataTaskWithRequestIMP = [MemoryUtils hookInstanceMethod:
                objc_getClass("NSURLSession")
                originalSelector:NSSelectorFromString(@"dataTaskWithRequest:")
                swizzledClass:[self class]
                swizzledSelector:NSSelectorFromString(@"hook_dataTaskWithRequest:")
    ];
    
    return YES;
}

@end
