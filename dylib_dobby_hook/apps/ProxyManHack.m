//
//  ProxyManHack.m
//  dylib_dobby_hook
//
//  Created by voidm on 2024/4/9.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "dobby.h"
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

intptr_t (*getProxyManAppStructOriginalAddress)(void);

intptr_t getProxyManAppStruct(void) {


    intptr_t app = getProxyManAppStructOriginalAddress();
    // 得到 App 里面的 license 对象
    intptr_t *licenseServer = app + 0xA0;
    // 得到 license 里面 112 偏移处的 licensekey 字段
    intptr_t *licenseKey = *licenseServer + 0x70;
    // 修改授权信息为激活状态
    *licenseKey = 0x0;
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

    NSString *searchFilePath = [[Constant getCurrentAppPath] stringByAppendingString:@"/Contents/MacOS/Proxyman"];
    uintptr_t fileOffset =[MemoryUtils getCurrentArchFileOffset: searchFilePath];
    
    
    int proxymanCoreIndex = [MemoryUtils indexForImageWithName:@"ProxymanCore"];
    NSString *proxymanCoreFilePath = [[Constant getCurrentAppPath] stringByAppendingString:@"/Contents/Frameworks/ProxymanCore.framework/Versions/A/ProxymanCore"];
    uintptr_t proxymanCoreFileOffset =[MemoryUtils getCurrentArchFileOffset: proxymanCoreFilePath];
    
    
    viewDidLoadIMP = [MemoryUtils hookInstanceMethod:
                          NSClassFromString(@"_TtC8Proxyman25PremiumPlanViewController")
                   originalSelector:NSSelectorFromString(@"viewDidLoad")
                      swizzledClass:[self class]
                   swizzledSelector:NSSelectorFromString(@"hook_viewDidLoad")
    ];

    
//    ProxymanCore.WorkspaceService.defaultProject
//    rbx = r13;
//    *(r13 + 0xe8) = 0x0;
//    *(int128_t *)(r13 + 0xb8) = intrinsic_movups(*(int128_t *)(r13 + 0xb8), 0x0);
//    *(int128_t *)(r13 + 0xc8) = intrinsic_movups(*(int128_t *)(r13 + 0xc8), 0x0);
//    *(r13 + 0xd8) = 0x0;
//    *(int8_t *)(r13 + 0xf0) = 0x2;
//    swift_allocObject(type metadata accessor for ProxymanCore.WorkspaceService(0x0), 0x20, 0x7);
//    r15 = ProxymanCore.WorkspaceService.init();
//    r12 = ProxymanCore.WorkspaceService.defaultProject();
//    swift_allocObject(type metadata accessor for ProxymanCore.ProxymanGateway(0x0), 0x38, 0x7);
//    swift_retain(r12);
//    r14 = ProxymanCore.ProxymanGateway.init(r12);
//    swift_allocObject(type metadata accessor for ProxymanCore.FlowPool(0x0), 0x30, 0x7);
//    var_30 = ProxymanCore.FlowPool.init();
//    static ProxymanCore.UserDataBackupService.backupUserDataIfNeedAsync();

#if defined(__arm64__) || defined(__aarch64__)
    NSString *patch_1Code = @"FF 43 03 D1 FC 6F 07 A9 FA 67 08 A9 F8 5F 09 A9 F6 57 0A A9 F4 4F 0B A9 FD 7B 0C A9 FD 03 03 91 F3 03 14 AA 9F 76 00 F9 00 E4 00 6F 80 82 8B 3C 80 82 8C 3C 9F 6E 00 F9 5B 00 80 52 9B C2 03 39";
#elif defined(__x86_64__)
    NSString *patch_1Code = @"55 48 89 E5 41 57 41 56 41 55 41 54 53 48 81 EC 98 00 00 00 4C 89 EB 49 C7 85 E8 00 00 00 00 00 00 00 0F 57 C0 41 0F 11 85 B8 00 00 00 41 0F 11 85 C8 00 00 00 49 C7 85 D8 00 00 00 00 00 00 00 41 C6 85 F0 00 00 00 02 31 FF";
#endif
    NSArray *patch_1Offsets =[MemoryUtils searchMachineCodeOffsets:
                    searchFilePath
                                                               machineCode:patch_1Code
                                                                     count:(int)1
    ];
    intptr_t _patch_1 = [MemoryUtils getPtrFromGlobalOffset:0 targetFunctionOffset:(uintptr_t)[patch_1Offsets[0] unsignedIntegerValue] reduceOffset:(uintptr_t)fileOffset];
    DobbyHook((void *)_patch_1, getProxyManAppStruct, &getProxyManAppStructOriginalAddress);

//
//#if defined(__arm64__) || defined(__aarch64__)
//    NSString *patch_2Code = @"55 48 89 E5 41 57 41 56 41 54 53 41 89 F4 ?? 89 ?? 48 89 D7 FF 15 ?? ?? ?? 00 ?? 89 ?? ?? 8D ?? 30 E8 ?? ?? ?? 00 49 89 C6 ?? 8B ?? 20 48 8D 3D ?? ?? ?? 00 ?? 89";
//#elif defined(__x86_64__)
//    NSString *patch_2Code = @"FF 03 01 D1 F6 57 01 A9 F4 4F 02 A9 FD 7B 03 A9 FD C3 00 91 F6 03 01 AA F5 03 00 AA E0 03 02 AA ?? ?? ?? 94 F3 03 00 AA A0 C2 00 91 ?? ?? ?? 94";
//#endif
//    NSArray *patch_2Offsets =[MemoryUtils searchMachineCodeOffsets:
//                    searchFilePath
//                                                               machineCode:patch_2Code
//                                                                     count:(int)1
//    ];
//    intptr_t _patch_2 = [MemoryUtils getPtrFromGlobalOffset:0 targetFunctionOffset:(uintptr_t)[patch_2Offsets[0] unsignedIntegerValue] reduceOffset:(uintptr_t)fileOffset];
//    DobbyHook((void *)_patch_2, handleHelper, nil);
    
   
    // Version 5.3.0 (50300)
    // ProxymanCore.AppConfiguration.isHideExpireLicenseBadge.getter : Swift.Bool
    // 如果返回 false , App StatusBar 会触发 Warning 按钮
//#if defined(__arm64__) || defined(__aarch64__)
//    NSString *patch_3Code = @"FF 83 01 D1 F8 5F 02 A9 F6 57 03 A9 F4 4F 04 A9 FD 7B 05 A9 FD 43 01 91 93 22 20 91 E1 23 00 91 E0 03 13 AA 02 00 80 D2 03 00 80 D2";
//#elif defined(__x86_64__)
//    NSString *patch_3Code = @"55 48 89 E5 41 57 41 56 41 55 41 54 53 48 83 EC 18 49 8D BD 08 08 00 00";
//#endif
//    NSArray *patch_3Offsets =[MemoryUtils searchMachineCodeOffsets:
//                                  proxymanCoreFilePath
//                                       machineCode:patch_3Code
//                                             count:(int)1
//    ];
//    intptr_t _patch_3 = [MemoryUtils getPtrFromGlobalOffset:proxymanCoreIndex targetFunctionOffset:(uintptr_t)[patch_3Offsets[0] unsignedIntegerValue] reduceOffset:(uintptr_t)proxymanCoreFileOffset];
//    DobbyHook((void *)_patch_3, ret1, nil);
    
    
    // 计算时间差
    NSDate *startTime = [NSDate date];
   // 直接 hook 导入表函数,似乎更优雅
    void* isHideExpireLicenseBadge = DobbySymbolResolver(
                                     "/Contents/Frameworks/ProxymanCore.framework/Versions/A/ProxymanCore", "_$s12ProxymanCore16AppConfigurationC24isHideExpireLicenseBadgeSbvg"
                                     );
    // 记录结束时间
    NSDate *endTime = [NSDate date];
    // 计算时间差
    NSTimeInterval executionTime2 = [endTime timeIntervalSinceDate:startTime];
    NSLogger(@"DobbySymbolResolver Execution Time: %f seconds", executionTime2);
    DobbyHook(isHideExpireLicenseBadge, ret1, nil);

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
