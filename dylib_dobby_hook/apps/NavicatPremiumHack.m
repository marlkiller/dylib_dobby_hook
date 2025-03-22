//
//  NavicatPremiumHack.m
//  dylib_dobby_hook
//
//  Created by voidm on 2024/1/27.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "tinyhook.h"
#import "MemoryUtils.h"
#import <objc/runtime.h>
#import "HackProtocolDefault.h"
#import "common_ret.h"

@interface NavicatPremiumHack : HackProtocolDefault

@end
@implementation NavicatPremiumHack


static IMP displayRegisteredInfoIMP;
static IMP subscriptionIsValidIMP;


- (NSString *)getAppName {
    return @"com.navicat.NavicatPremium";
}

- (NSString *)getSupportAppVersion {
    return @"17.";
}


//- (int)hk_productSubscriptionStillHaveTrialPeriod{
//    NSLogger(@"Swizzled hk_productSubscriptionStillHaveTrialPeriod method called");
//    return 0;
//}
//- (int)hk_isProductSubscriptionStillValid{
//    NSLogger(@"Swizzled hk_isProductSubscriptionStillValid method called");
//    return 1;
//}
//+ (void)hk_validate{
//    NSLogger(@"Swizzled hk_validate method called");
//}


- (BOOL)hack {
    
    [self hook_AllSecItem];

    [MemoryUtils hookInstanceMethod:
                objc_getClass("_TtC15Navicat_Premium9IAPHelper")
                originalSelector:NSSelectorFromString(@"isProductSubscriptionStillValid")
                swizzledClass:[self class]
                swizzledSelector: @selector(ret1)
    ];
    
    [MemoryUtils hookClassMethod:
                objc_getClass("AppStoreReceiptValidation")
                originalSelector:NSSelectorFromString(@"validate")
                swizzledClass:[self class]
                swizzledSelector:@selector(ret)
    ];

    [MemoryUtils replaceClassMethod:
                    objc_getClass("CCCore")
                originalSelector:NSSelectorFromString(@"initializeRegistrationCallback")
                   swizzledClass:[self class]
                swizzledSelector:@selector(ret)
    ];

    displayRegisteredInfoIMP = [MemoryUtils hookInstanceMethod:
                                    NSClassFromString(@"AboutNavicatWindowController")
                   originalSelector:NSSelectorFromString(@"displayRegisteredInfo")
                      swizzledClass:[self class]
                   swizzledSelector: @selector(hk_displayRegisteredInfo)
    ];

    subscriptionIsValidIMP = [MemoryUtils hookInstanceMethod:
                    NSClassFromString(@"AppDelegate")
                                              originalSelector:NSSelectorFromString(@"subscriptionIsValid:")
                                                 swizzledClass:[self class]
                                            swizzledSelector: @selector(hk_subscriptionIsValid:)
    ];
    return YES;
}
- (void)hk_displayRegisteredInfo {
    
//   TODO: self 有个ivar _extraInfo 的 dict 是 license 信息, 后面这个特征失效就跟一下 这个 dict
    ((void(*)(id, SEL))displayRegisteredInfoIMP)(self, _cmd);
    id _appExtraInfoLabel = [MemoryUtils getInstanceIvar:self ivarName:"_appExtraInfoLabel"];
    if (_appExtraInfoLabel) {
        [_appExtraInfoLabel setStringValue:[Constant G_EMAIL_ADDRESS]];
    }

}

- (void)hk_subscriptionIsValid:arg1{
    ((void(*)(id, SEL, id))subscriptionIsValidIMP)(self, _cmd, @(1));
}

@end
