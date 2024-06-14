//
//  NavicatPremiumHack.m
//  dylib_dobby_hook
//
//  Created by 马治武 on 2024/1/27.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "dobby.h"
#import "MemoryUtils.h"
#import <objc/runtime.h>
#import "HackProtocol.h"
#import "common_ret.h"

@interface NavicatPremiumHack : NSObject <HackProtocol>

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
//    NSLog(@">>>>>> Swizzled hk_productSubscriptionStillHaveTrialPeriod method called");
//    return 0;
//}
//- (int)hk_isProductSubscriptionStillValid{
//    NSLog(@">>>>>> Swizzled hk_isProductSubscriptionStillValid method called");
//    return 1;
//}
//+ (void)hk_validate{
//    NSLog(@">>>>>> Swizzled hk_validate method called");
//}


- (BOOL)hack {
    
//    -[IAPWindowController windowDidLoad]:
//    00000001001c791a         push       rbp                                         ; Objective C Implementation defined at 0x1017d9ad8 (instance method), DATA XREF=0x1017d9ad8
//    ...
//    00000001001c7e0b         lea        rdx, qword [cfstring_Start_Free_Trial]      ; @"Start Free Trial"
//    rax = [IAPHelper sharedHelper];
//    r15 = [rax productSubscriptionStillHaveTrialPeriod];
//    r15 == 0x0
//    [MemoryUtils hookInstanceMethod:
//                objc_getClass("IAPHelper")
//                originalSelector:NSSelectorFromString(@"productSubscriptionStillHaveTrialPeriod")
//                swizzledClass:[self class]
//                swizzledSelector:NSSelectorFromString(@"hk_productSubscriptionStillHaveTrialPeriod")
//    ];
    
   
    
//    Process 10120 exited with status = 173 (0x000000ad)
//    * thread #1, queue = 'com.apple.main-thread', stop reason = breakpoint 2.2
//        frame #0: 0x00007ff800e3a3af libsystem_c.dylib`exit
//    libsystem_c.dylib`exit:
//    ->  0x7ff800e3a3af <+0>: push   rbp
//        0x7ff800e3a3b0 <+1>: mov    rbp, rsp
//        0x7ff800e3a3b3 <+4>: push   rbx
//        0x7ff800e3a3b4 <+5>: push   rax
//    Target 0: (Navicat Premium) stopped.
//
//
//    * thread #1, queue = 'com.apple.main-thread', stop reason = breakpoint 2.2
//      * frame #0: 0x00007ff800e3a3af libsystem_c.dylib`exit
//        frame #1: 0x000000010a109d98 libcc-premium.dylib`___lldb_unnamed_symbol80122 + 1438
//        frame #2: 0x0000000109b968ea libcc-premium.dylib`___lldb_unnamed_symbol60041 + 24
//        frame #3: 0x0000000108da563b libcc-premium.dylib`CCNavicat::setupContext(bool, bool, std::__1::vector<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char>>, std::__1::allocator<std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char>>>> const&) + 3075
//        frame #4: 0x0000000100b4161a Navicat Premium`___lldb_unnamed_symbol29545 + 343
//        frame #5: 0x00007ff8010425b0 CoreFoundation`__CFNOTIFICATIONCENTER_IS_CALLING_OUT_TO_AN_OBSERVER__ + 137
//        frame #6: 0x00007ff8010d3116 CoreFoundation`___CFXRegistrationPost_block_invoke + 88
//        frame #7: 0x00007ff8010d3060 CoreFoundation`_CFXRegistrationPost + 532
//        frame #8: 0x00007ff8010124ab CoreFoundation`_CFXNotificationPost + 682
//        frame #9: 0x00007ff801f9215e Foundation`-[NSNotificationCenter postNotificationName:object:userInfo:] + 82
//        frame #10: 0x00007ff804661f6e AppKit`-[NSApplication _postDidFinishNotification] + 311
//        frame #11: 0x00007ff80464b8d9 AppKit`-[NSApplication finishLaunching] + 2631
//        frame #12: 0x00007ff80464abd1 AppKit`-[NSApplication run] + 250
//        frame #13: 0x00007ff80461ed41 AppKit`NSApplicationMain + 816
//        frame #14: 0x0000000100a33592 Navicat Premium`___lldb_unnamed_symbol27833 + 4264
//        frame #15: 0x00007ff800be6386 dyld`start + 1942
//
//
//    >> image list -o -f
//    [  2] 0x0000000108d75000 /Applications/Navicat Premium.app/Contents/Frameworks/libcc-premium.dylib
//
//    计算公式为 0x0000000108d75000 + 文件二进制偏移 = 内存地址偏移 0x000000010a109d98  |  0x0000000109b968ea
//
//    function sub_e218d2 {
//        [AppStoreReceiptValidation validate];
//        return 0x1;
//    }
//    0x109b968d6 <+4>:    mov    rdi, qword ptr [rip + 0x2504c23] ; (void *)0x000000010c09b5d8
//    >> po 0x000000010c09b5d8
//    >> AppStoreReceiptValidation
//    0x109b968dd <+11>:   mov    rsi, qword ptr [rip + 0x2504b84] ; "validate"
//    0x109b968e4 <+18>:   call   qword ptr [rip + 0x2336b56] ; (void *)0x00007ff800ba4a00: objc_msgSend
//
//    0x000000010a109d98 - 0x0000000108d75000 = 0x1394D98
//    0x109b968ea - 0x108d75000 = 0xE218EA
//
//    >> hopper > libcc-premium.dylib > 0xE218EA
//    >> lldb > dis -a 0x109b968ea
    
    
#if defined(__arm64__) || defined(__aarch64__)
#elif defined(__x86_64__)
#endif
    
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


    Class AboutNavicatWindowControllerClz = NSClassFromString(@"AboutNavicatWindowController");
    SEL displayRegisteredInfoSel = NSSelectorFromString(@"displayRegisteredInfo");
    Method dataTaskWithRequestMethod = class_getInstanceMethod(AboutNavicatWindowControllerClz, displayRegisteredInfoSel);
    displayRegisteredInfoIMP = method_getImplementation(dataTaskWithRequestMethod);
    
    [MemoryUtils hookInstanceMethod:
                    AboutNavicatWindowControllerClz
                   originalSelector:displayRegisteredInfoSel
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

    ((void(*)(id, SEL))displayRegisteredInfoIMP)(self, _cmd);
    
    
    
    // ivar 分静态非静态的?? [MemoryUtils getInstanceIvar] 似乎获取不到哦
    Ivar InfoLabel = class_getInstanceVariable([self class], "_appExtraInfoLabel");
    if (InfoLabel != NULL) {
        ptrdiff_t offset = ivar_getOffset(InfoLabel);
        uintptr_t address = (uintptr_t)(__bridge void *)self + offset;
        id  __autoreleasing *deviceIdPtr = (id  __autoreleasing *)(void *)address;
        id _appExtraInfoLabel = *deviceIdPtr;
         [_appExtraInfoLabel setStringValue:[NSString stringWithCString:global_email_address encoding:NSUTF8StringEncoding]];

    }
}
@end
