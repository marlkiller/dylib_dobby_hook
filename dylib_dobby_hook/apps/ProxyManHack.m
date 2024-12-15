//
//  ProxyManHack.m
//  dylib_dobby_hook
//
//  Created by voidm on 2024/4/9.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "tinyhook.h"
#import "MemoryUtils.h"
#import <objc/runtime.h>
#import "HackProtocolDefault.h"
#import <dlfcn.h>
#import <mach-o/nlist.h>
#import <AppKit/AppKit.h>
#import "common_ret.h"

@interface ProxyManHack : HackProtocolDefault

@end


@implementation ProxyManHack

static IMP viewDidLoadIMP;

- (NSString *)getAppName {
    // >>>>>> AppName is [com.proxyman.NSProxy],Version is [5.1.1], myAppCFBundleVersion is [50101].
    return @"com.proxyman.NSProxy";
}

- (NSString *)getSupportAppVersion {
    return @"5";
}

intptr_t (*getProxyManAppStructOriginalAddress)(void) = NULL;

intptr_t getProxyManAppStruct(void) {
    intptr_t app = getProxyManAppStructOriginalAddress();
    // 得到 App 里面的 license 对象
    intptr_t *licenseServer = (intptr_t *)(app + 0xA0);
    // 得到 license 里面 112 偏移处的 licensekey 字段
    intptr_t *licenseKey = (intptr_t *)(*licenseServer + 0x70);
    // 修改授权信息为激活状态
    *licenseKey = 0x0;
    NSLogger(@"getProxyManAppStructOriginalAddress address: %p", (void*)getProxyManAppStructOriginalAddress);
    return app;
}




/**
 *  通杀掉ProxyMan 的 Helper Check函数
 */
intptr_t handleHelper(intptr_t a1, intptr_t a2, intptr_t a3) {
    intptr_t *v7 = (void *) a1 + 40;
    intptr_t *v6 = (void *) a1 + 32;
    intptr_t v6_1 = *v6; //版本号
    intptr_t v7_1 = *v7;
    intptr_t *v8 = (void *) v7_1 + 16;
    intptr_t v8_1 = *v8;
    void (*v8Call)(intptr_t, int, intptr_t) = (void *) v8_1;// 让Helper版本识别正确
    v8Call(v7_1, 1, v6_1);
    return v6_1;
}

- (void) hook_viewDidLoad{
    ((void*(*)(id, SEL))viewDidLoadIMP)(self, _cmd);
    // objc_ivar_offset__TtC8Proxyman25PremiumPlanViewController_registerAtLbl:
    // -[_TtC8Proxyman25PremiumPlanViewController registerAtLbl]:        // -[Proxyman.PremiumPlanViewController registerAtLbl]
    NSTextField *registerAtLbl =  [MemoryUtils getInstanceIvar:self ivarName:"registerAtLbl"];
    NSView *expiredLicenseInfoStackView = [MemoryUtils getInstanceIvar:self ivarName:"expiredLicenseInfoStackView"];
    NSTextField *licenseUntilLbl = [MemoryUtils getInstanceIvar:self ivarName:"licenseUntilLbl"];
    [expiredLicenseInfoStackView setHidden:true];
    [licenseUntilLbl setStringValue:@"Saturday, Sep 01, 2050"];
    [registerAtLbl setStringValue:[Constant G_EMAIL_ADDRESS]];
}
- (BOOL)hack {
    viewDidLoadIMP = [MemoryUtils hookInstanceMethod:
                          NSClassFromString(@"_TtC8Proxyman25PremiumPlanViewController")
                   originalSelector:NSSelectorFromString(@"viewDidLoad")
                      swizzledClass:[self class]
                   swizzledSelector:NSSelectorFromString(@"hook_viewDidLoad")
    ];

#if defined(__arm64__) || defined(__aarch64__)
    NSString *patch_1Code = @"FF 43 03 D1 FC 6F 07 A9 FA 67 08 A9 F8 5F 09 A9 F6 57 0A A9 F4 4F 0B A9 FD 7B 0C A9 FD 03 03 91 F3 03 14 AA 9F 76 00 F9 00 E4 00 6F 80 82 8B 3C 80 82 8C 3C 9F 6E 00 F9 5B 00 80 52 9B C2 03 39";
#elif defined(__x86_64__)
    NSString *patch_1Code = @"55 48 89 E5 41 57 41 56 41 55 41 54 53 48 81 EC 98 00 00 00 4C 89 EB 49 C7 85 E8 00 00 00 00 00 00 00 0F 57 C0 41 0F 11 85 B8 00 00 00 41 0F 11 85 C8 00 00 00 49 C7 85 D8 00 00 00 00 00 00 00 41 C6 85 F0 00 00 00 02 31 FF";
#endif
    [MemoryUtils hookWithMachineCode:@"/Contents/MacOS/Proxyman"
                             machineCode:patch_1Code
                               fake_func:getProxyManAppStruct
                                   count:1
                            out_orig:(void *)&getProxyManAppStructOriginalAddress
    ];

    
    
    // 计算时间差
    NSDate *startTime = [NSDate date];
   // 直接 hook 导入表函数,似乎更优雅
    void* isHideExpireLicenseBadge = symexp_solve(
                                     [MemoryUtils indexForImageWithName:@"ProxymanCore"], "_$s12ProxymanCore16AppConfigurationC24isHideExpireLicenseBadgeSbvg"
                                     );
    // 记录结束时间
    NSDate *endTime = [NSDate date];
    // 计算时间差
    NSTimeInterval executionTime2 = [endTime timeIntervalSinceDate:startTime];
    NSLogger(@"sym_solve Execution Time: %f seconds", executionTime2);
    tiny_hook(isHideExpireLicenseBadge, ret1, nil);

//    TODO: Undefined symbol: _DobbyImportTableReplace
//    DobbyImportTableReplace(
//                            "/Contents/Frameworks/ProxymanCore.framework/Versions/A/ProxymanCore",
//                            "_$s12ProxymanCore16AppConfigurationC24isHideExpireLicenseBadgeSbvg",
//                            (void *)ret1,
//                            nil
//                            );

    return YES;
}


@end
