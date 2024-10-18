//
//  NavicatPremiumHack.m
//  dylib_dobby_hook
//
//  Created by voidm on 2024/1/27.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "dobby.h"
#import "MemoryUtils.h"
#import <objc/runtime.h>
#import "HackProtocolDefault.h"
#import "common_ret.h"

@interface NavicatPremiumHack : HackProtocolDefault

@end
@implementation NavicatPremiumHack


static IMP displayRegisteredInfoIMP;


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
    
    DobbyHook(SecItemAdd, hk_SecItemAdd, NULL);
    DobbyHook(SecItemUpdate, hk_SecItemUpdate, NULL);
    DobbyHook(SecItemDelete, hk_SecItemDelete, NULL);
    DobbyHook(SecItemCopyMatching, hk_SecItemCopyMatching, NULL);

    [MemoryUtils hookInstanceMethod:
                objc_getClass("IAPHelper")
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


    displayRegisteredInfoIMP = [MemoryUtils hookInstanceMethod:
                                    NSClassFromString(@"AboutNavicatWindowController")
                   originalSelector:NSSelectorFromString(@"displayRegisteredInfo")
                      swizzledClass:[self class]
                   swizzledSelector: @selector(hk_displayRegisteredInfo)
    ];
    
    
    return YES;
}
- (void)hk_displayRegisteredInfo {
    
//   TODO: self 有个ivar _extraInfo 的 dict 是 license 信息, 后面这个特征失效就跟一下 这个 dict
//   Ivar ivar = class_getInstanceVariable([self class], "_extraInfo");
//   // 如果 ivar 不为空，说明属性存在
//   if (ivar != NULL) {
//       // 获取属性的偏移量
//       ptrdiff_t offset = ivar_getOffset(ivar);
//       uintptr_t address = (uintptr_t)(__bridge void *)self + offset;
//       NSDictionary * __autoreleasing *deviceIdPtr = (NSDictionary * __autoreleasing *)(void *)address;
//       NSDictionary *originalDict = *deviceIdPtr;
//       NSMutableDictionary *mutableDict = [originalDict mutableCopy];
//       [mutableDict setObject:@YES forKey:@"regMode"];
//       [mutableDict setObject:@"name" forKey:@"name"];
//       [mutableDict setObject:@"Registered" forKey:@"versionType"];
//       [mutableDict setObject:@"subscriptionNavicatID" forKey:@"subscriptionNavicatID"];
//       [mutableDict setObject:@"organization" forKey:@"organization"];
//       *deviceIdPtr = mutableDict;
//   }
    
    
//    指针转换 (void *)
//    id object = self;
//    NSString  *user = *(NSString __strong  **)((__bridge void *)object + 0x60);
//    NSString *newUser = @"";
//    *(NSString __strong **)((__bridge void *)object + 0x60) = newUser;


//    指针转换 (&)
//    id object = self;
//    NSString *user = *(NSString __strong **)(&object + 0x60);
//    NSString *newUser = @"";
//    *(NSString __strong **)((&object) + 0x60) = newUser;
    

    
//    指针转换 (uintptr_t)
//    id object = self;
//    NSString *user = *(NSString __strong **)(((void *)(uintptr_t)object) + 0x60);
//    NSString *newUser = @"";
//    *(NSString __strong **)(((void *)(uintptr_t)object) + 0x60) = newUser;

//    读写 id 类型
//    id  user = *(id __strong  *)((__bridge void *)object + 0x60);
//    id c = *(id __strong *)(&object + 0x60);
//    id newC = @"";
//    *(id __strong *)(&object + 0x60) = newC;


//    读写 int 属性对象
//    int intValue = *(int *)((__bridge void *)object + 0x30);
//    *(int *)((__bridge void *)object + 0x30) = 123;
    

//    读写 NSString 属性对象
//    NSString __strong **propertyPtr = (NSString __strong **)(&object + 0x60);
//    *propertyPtr = @"1";
//    NSString *propertyA = *propertyPtr = @"1";


    // demo
//    std::string str = "123";
//    std::string *ptr = &str;
//
//    uintptr_t address = reinterpret_cast<uintptr_t>(ptr);
//    void * address2 = (void *)ptr;
//    void * address3 = &str;

    ((void(*)(id, SEL))displayRegisteredInfoIMP)(self, _cmd);
    
    
    
    // ivar 分静态非静态的?? [MemoryUtils getInstanceIvar] 似乎获取不到哦
    Ivar InfoLabel = class_getInstanceVariable([self class], "_appExtraInfoLabel");
    if (InfoLabel != NULL) {
        ptrdiff_t offset = ivar_getOffset(InfoLabel);
        uintptr_t address = (uintptr_t)(__bridge void *)self + offset;
        id  __autoreleasing *deviceIdPtr = (id  __autoreleasing *)(void *)address;
        id _appExtraInfoLabel = *deviceIdPtr;
         [_appExtraInfoLabel setStringValue:[Constant G_EMAIL_ADDRESS]];

    }
//    id BaseFeaturesController  = self;
//    
////  r14 = *(r13 + *objc_ivar_offset__TtC13App_Cleaner_822BaseFeaturesController_licenseManager);
//    id  NKLicenseManager = *(id __strong *)((__bridge void *)BaseFeaturesController + 0x8);
//      
////  r14 = *(rbx + 0x28);
////  r15 = r14 + 0x20;
//    id  LicenseStateStorage = *(id __strong *)((__bridge void *)NKLicenseManager + 0x28);
//    id  TtC16NKLicenseManager19LicenseStateStorage_serialKey = *(id __strong *)((__bridge void *)LicenseStateStorage + 0x20);
//    if (!TtC16NKLicenseManager19LicenseStateStorage_serialKey) {
//        
//        
////        *(id __strong *)((__bridge void *)LicenseStateStorage + 0x20) = @"123456";
//        Ivar serialKeyIvar = class_getInstanceVariable([LicenseStateStorage class], "serialKey");
//        const char *ivarTypeEncoding = ivar_getTypeEncoding(serialKeyIvar);
//        NSString *ivarType = [NSString stringWithUTF8String:ivarTypeEncoding];
//        id currentValue = object_getIvar(LicenseStateStorage, serialKeyIvar);
//        object_setIvar(LicenseStateStorage, serialKeyIvar, @"2222222222");
//        *(int *)((__bridge void *)LicenseStateStorage + 0x28) = 1;
//    }
}
@end
