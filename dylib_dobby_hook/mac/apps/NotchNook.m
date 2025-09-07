//
//  NotchNook.m
//  dylib_dobby_hook
//
//  Created by NKR on 2025/4/23.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "tinyhook.h"
#import "MemoryUtils.h"
#import <objc/runtime.h>
#include <sys/ptrace.h>
#import "common_ret.h"
#import "HackProtocolDefault.h"

@interface NotchNook : HackProtocolDefault

@end

@implementation NotchNook


- (NSString *)getAppName {
    return @"lo.cafe.NotchNook";
}

- (NSString *)getSupportAppVersion {
    return @"";
}

static IMP hookNSUserDefaultsobjectForKeyIMP,initWithStringSeletorIMP;

+ (NSNumber *)updateTrialInitialTimeIfNeeded {
    NSString *defaultName = @"trialInitialTime";
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger currentTimestamp = (NSInteger)[[NSDate date] timeIntervalSince1970];
    NSInteger storedTimestamp = [defaults integerForKey:defaultName];
    NSInteger difference = currentTimestamp - storedTimestamp;
    if (difference >= 172800) {
        [defaults setInteger:currentTimestamp forKey:defaultName];
        [defaults synchronize];
        return @(currentTimestamp);
    }
    return @(storedTimestamp);
}

- (id)swizzled_objectForKey:(NSString *)defaultName {
    //if ([defaultName isEqualToString:@"trialInitialTime"]) {
    //  return [NotchNook updateTrialInitialTimeIfNeeded];
    // }
     if ([defaultName isEqualToString:@"keyActive"]) {
       return [NSString stringWithFormat:@"{\"email\": \"%@\", \"key\": \"UnlockFullVersion\"}", @"NKR🦁"];
     }
    return ((id(*)(id, SEL, NSString *))hookNSUserDefaultsobjectForKeyIMP)(self, _cmd, defaultName);
}

- (BOOL)hack {

  hookNSUserDefaultsobjectForKeyIMP = [MemoryUtils hookInstanceMethod:
                          objc_getClass("NSUserDefaults")
                   originalSelector:NSSelectorFromString(@"objectForKey:")
                      swizzledClass:[self class]
                        swizzledSelector:@selector(swizzled_objectForKey:)
    ];

  initWithStringSeletorIMP = [MemoryUtils hookInstanceMethod:
         NSClassFromString(@"NSURL")
                   originalSelector:NSSelectorFromString(@"initWithString:")
                      swizzledClass:[self class]
                swizzledSelector:@selector(hk_initWithString:)
    ];

    return YES;
}

 -(id)hk_initWithString:arg1{
   if ([arg1 containsString:@"lo.cafe/api/notchnook-verify-key-v2"]) {
        arg1 = @"lol.lol";
    }
    id ret = ((id(*)(id, SEL,id))initWithStringSeletorIMP)(self, _cmd,arg1);
    return ret;
}
@end
