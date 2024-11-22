//
//  InfuseHack.m
//  dylib_dobby_hook
//
//  Created by voidm on 2024/5/11.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "tinyhook.h"
#import "MemoryUtils.h"
#import <objc/runtime.h>
#include <sys/ptrace.h>
#import "common_ret.h"
#import "HackProtocolDefault.h"

@interface InfuseHack : HackProtocolDefault



@end


@implementation InfuseHack


- (NSString *)getAppName {
    // 2024-05-11 15:45:29.526 Infuse[84842:2247193] >>>>>> AppName is [com.firecore.infuse],Version is [7.7.5], myAppCFBundleVersion is [7.7.4827].
    return @"com.firecore.infuse";
}

- (NSString *)getSupportAppVersion {
    return @"8";
}

- (BOOL)hack {
   
    tiny_hook((void *)ptrace, (void *)my_ptrace, (void *)&orig_ptrace);

    [MemoryUtils hookInstanceMethod:
                objc_getClass("FCInAppPurchaseServiceFreemium")
                originalSelector:NSSelectorFromString(@"iapVersionStatus")
                swizzledClass:[self class]
                swizzledSelector:@selector(ret1)
    ];

    [self hook_AllSecItem];
    
    [MemoryUtils hookClassMethod:
         NSClassFromString(@"NSUbiquitousKeyValueStore")
                   originalSelector:NSSelectorFromString(@"defaultStore")
                      swizzledClass:[self class]
                   swizzledSelector:@selector(hook_defaultStore)
    ];

    [MemoryUtils hookClassMethod:
        NSClassFromString(@"CKContainer")
                  originalSelector:NSSelectorFromString(@"containerWithIdentifier:")
                     swizzledClass:[self class]
                  swizzledSelector:@selector(hook_containerWithIdentifier: )
    ];
    [MemoryUtils hookClassMethod:
        NSClassFromString(@"CKContainer")
                  originalSelector:NSSelectorFromString(@"defaultContainer")
                     swizzledClass:[self class]
                  swizzledSelector:@selector(hook_defaultContainer)

    ];
    
    return YES;
}

@end
