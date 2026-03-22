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
    
    //    sudo rm -Rf /Applications/Navicat\ Premium.app
    //    sudo rm -Rf /private/var/db/BootCaches/CB6F12B3-2C14-461E-B5A7-A8621B7FF130/app.com.prect.NavicatPremium.playlist
    //    sudo rm -Rf ~/Library/Caches/com.apple.helpd/SDMHelpData/Other/English/HelpSDMIndexFile/com.prect.NavicatPremium.help
    //    sudo rm -Rf ~/Library/Caches/com.apple.helpd/SDMHelpData/Other/zh_CN/HelpSDMIndexFile/com.prect.NavicatPremium.help
    //    sudo rm -Rf ~/Library/Preferences/com.prect.NavicatPremium.plist
    //    sudo rm -Rf ~/Library/Application\ Support/CrashReporter/Navicat\ Premium_54EDA2E9-528D-5778-A528-BBF9A4CE8BDC.plist
    //    sudo rm -Rf ~/Library/Application\ Support/PremiumSoft\ CyberTech
    
    [self hook_AllSecItem];
    
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[receiptURL path]];

    if (!exists) {
        NSLogger(@"App 不是 App Store 版本（第三方下载或未上架）");
        [MemoryUtils hookInstanceMethod:
                    objc_getClass("RegistrationSubscriptionWindowController")
                    originalSelector:NSSelectorFromString(@"checkAndSaveKey:activationGraceEndDate:")
                    swizzledClass:[self class]
                    swizzledSelector: @selector(ret1)
        ];
//        🌐 200 POST https://activate.navicat.com/AA8747009.php?v=2
//        👤 Delegate: CustomSessionDataDelegate
//         └─ Module: /Applications/Navicat Premium.app/Contents/Frameworks/libcf.dylib
//        🧠 Completion Handler Analysis:
//         ├─ Module: /Applications/Navicat Premium.app/Contents/Frameworks/libcf.dylib
//         └─ Address: Runtime=0x110b80bb1 | Offset=0x6fbb1 | Static=0x6fbb1
//        📝 Response Body:
//        {"error_no":0,"result":"MRWWqRuPJPsE9j\/96AUwfw7s5UAyAzmtrCWGNJWGfFlpRo2brdBbykn+ptwzLXQkbFNBhjsNpw7bfM4lGer2RRe7iazdwUwhx+rz3uKUwQi3ZlYDzlhSB5HAzJLkXpROafnzf3fQC+kL0fB+iUo9m9h7Np9NhkYCEZbC0Ey99iUpZAtMx8iuc3HBfI8NUeMuwDO6CxwSxpSZjo+1OEATGJeSvWWb25qPJhV3uY12bVQxi1AvUvHtCAE5jZvOSTigYrLgmPJ5BYCUzQdbgaqHMWwcQiMN8IXblwjbuvRh6abQYf5JtETsEz3vC7eBNndMmArqWC5pPfMi7tpopvTdjA=="}


        
        return NO;
    } else {
        NSLogger(@"App 来自 App Store");
    }

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
    
    ((void(*)(id, SEL))displayRegisteredInfoIMP)(self, _cmd);
    id _appExtraInfoLabel = IVAR_OBJ(self, "_appExtraInfoLabel");
    if (_appExtraInfoLabel) {
        [_appExtraInfoLabel setStringValue:[Constant G_EMAIL_ADDRESS]];
    }

}

- (void)hk_subscriptionIsValid:arg1{
    ((void(*)(id, SEL, id))subscriptionIsValidIMP)(self, _cmd, @(1));
}

@end
