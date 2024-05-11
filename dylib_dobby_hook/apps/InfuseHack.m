//
//  InfuseHack.m
//  dylib_dobby_hook
//
//  Created by 马治武 on 2024/5/11.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "dobby.h"
#import "MemoryUtils.h"
#import <objc/runtime.h>
#import "HackProtocol.h"
#include <sys/ptrace.h>
#import "common_ret.h"


@interface InfuseHack : NSObject <HackProtocol>



@end


@implementation InfuseHack


- (NSString *)getAppName {
    // 2024-05-11 15:45:29.526 Infuse[84842:2247193] >>>>>> AppName is [com.firecore.infuse],Version is [7.7.5], myAppCFBundleVersion is [7.7.4827].
    return @"com.firecore.infuse";
}

- (NSString *)getSupportAppVersion {
    return @"7.7";
}

- (BOOL)hack {
   
    DobbyHook((void *)ptrace, (void *)my_ptrace, (void *)&orig_ptrace);

    [MemoryUtils hookInstanceMethod:
                objc_getClass("FCInAppPurchaseServiceFreemium")
                originalSelector:NSSelectorFromString(@"iapVersionStatus")
                swizzledClass:[self class]
                swizzledSelector:@selector(ret1)
    ];

    return YES;
}

@end
