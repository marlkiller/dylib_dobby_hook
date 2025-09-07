//
//  irv.h
//  dylib_dobby_hook
//
//  Created by asdf asd on 2024/10/17.
//



#import <Foundation/Foundation.h>
#import "Constant.h"
#import "tinyhook.h"
#import "MemoryUtils.h"
#import <objc/runtime.h>
#include <sys/ptrace.h>
#import "common_ret.h"
#import "HackProtocolDefault.h"

@interface irvueHack : HackProtocolDefault



@end


@implementation irvueHack


- (NSString *)getAppName {
    // 2024-05-11 15:45:29.526 Infuse[84842:2247193] >>>>>> AppName is [com.firecore.infuse],Version is [7.7.5], myAppCFBundleVersion is [7.7.4827].
    return @"com.leonspok.osx.Irvue";
}

- (NSString *)getSupportAppVersion {
    return @"2025.";
}

- (BOOL)hack {
    [MemoryUtils hookInstanceMethod:
                objc_getClass("LPSubscriptionManager")
                originalSelector:NSSelectorFromString(@"unlimitedChannelsAvailable")
                swizzledClass:[self class]
                swizzledSelector:@selector(ret1)
    ];
    
    return YES;
}

@end
