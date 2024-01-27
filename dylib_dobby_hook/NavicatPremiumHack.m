//
//  NavicatPremiumHack.m
//  dylib_dobby_hook
//
//  Created by 马治武 on 2024/1/27.
//

#import <Foundation/Foundation.h>
#import "NavicatPremiumHack.h"
#import "Constant.h"
#import "dobby.h"
#import "MemoryUtils.h"
#import <objc/runtime.h>

@implementation NavicatPremiumHack


- (NSString *)getAppName {
    return @"com.navicat.NavicatPremium";
}

- (NSString *)getSupportAppVersion {
    return @"16.3.5";
}


- (int)hk_productSubscriptionStillHaveTrialPeriod{
    NSLog(@">>>>>> Swizzled hk_productSubscriptionStillHaveTrialPeriod method called");
    return 1;
}
+ (void)hk_validate{
    NSLog(@">>>>>> Swizzled hk_validate method called");
//    return 0;
}


- (BOOL)hack {
    
//    rax = [IAPHelper sharedHelper];
//    r15 = [rax productSubscriptionStillHaveTrialPeriod];
//    r15 != 0x0
    [MemoryUtils hookInstanceMethod:
                objc_getClass("IAPHelper")
                originalSelector:NSSelectorFromString(@"productSubscriptionStillHaveTrialPeriod")
                swizzledClass:[self class]
                swizzledSelector:NSSelectorFromString(@"hk_productSubscriptionStillHaveTrialPeriod")
    ];
    
    [MemoryUtils hookClassMethod:
                objc_getClass("AppStoreReceiptValidation")
                originalSelector:NSSelectorFromString(@"validate")
                swizzledClass:[self class]
                swizzledSelector:NSSelectorFromString(@"hk_validate")
    ];
    
    NSLog(@">>>>>> 123");
#if defined(__arm64__) || defined(__aarch64__)
#elif defined(__x86_64__)
#endif
    
    return YES;
}

@end
