//
//  ProgressiveDownloader.m
//  dylib_dobby_hook
//
//  Created by NKR on 2025/7/6.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "tinyhook.h"
#import "MemoryUtils.h"
#import <objc/runtime.h>
#include <sys/ptrace.h>
#import "common_ret.h"
#import "HackProtocolDefault.h"

@interface ProgressiveDownloader : HackProtocolDefault

@end

@implementation ProgressiveDownloader


- (NSString *)getAppName {
    return @"com.PS.PSD";
}

- (NSString *)getSupportAppVersion {
    return @"";
}

static IMP enabledForCodeIMP;

+ (BOOL) hook_enabledForCode:(int) argv {
    if(argv == -1006) {
      return true;
    }
    return ((BOOL (*)(id, SEL,int))enabledForCodeIMP)(self, _cmd, argv);
}

- (BOOL)hack {

    enabledForCodeIMP = [MemoryUtils hookClassMethod:
             NSClassFromString(@"NSMutableDictionary")
                    originalSelector:NSSelectorFromString(@"enabledForCode:") swizzledClass:[self class] swizzledSelector:@selector(hook_enabledForCode:)
        ];

    return YES;
}

@end
