//
//  DevUtilsHack.m
//  dylib_dobby_hook
//
//  Updated by adm on 2025/6/6.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "tinyhook.h"
#import "MemoryUtils.h"
#import <objc/runtime.h>
#import "HackProtocolDefault.h"

@interface DevUtilsHack : HackProtocolDefault

@end

@implementation DevUtilsHack


- (NSString *)getAppName {
    return @"tonyapp.devutils";
}

- (NSString *)getSupportAppVersion {
    return @"1.";
}

- (BOOL)hack {

#if defined(__arm64__) || defined(__aarch64__)
    NSString *setAppPatchOriginal = @"0C 13 17";
    uint8_t setAppPatchTarget[3] = {0x22, 0x13, 0x17};
#elif defined(__x86_64__)
    NSString *setAppPatchOriginal = @"74 FF FF FF 8E";
    uint8_t setAppPatchTarget[5] = {0xBC, 0xFF, 0xFF, 0xFF, 0x8E};
#endif

    NSArray *setAppPatchPtrs =[MemoryUtils getPtrFromMachineCode:(NSString *) @"/Contents/MacOS/DevUtils"
                                                      machineCode:(NSString *) setAppPatchOriginal
                                                            count:(int)1];
    uintptr_t setAppPatchPtr = [setAppPatchPtrs[0] unsignedIntegerValue];
    write_mem((void*)setAppPatchPtr,(uint8_t *)setAppPatchTarget,sizeof(setAppPatchTarget) / sizeof(setAppPatchTarget[0]));

//
//#if defined(__arm64__) || defined(__aarch64__)
//    NSString* devHex = @"20 00 80 52 C0 03 5F D6 FF 83 01 D1 FA 67 01 A9 F8 5F 02 A9 F6 57 03 A9 F4 4F 04 A9";
//    uintptr_t devAddr = 0x3c10;
//#elif defined(__x86_64__)
//    NSString* devHex = @"55 48 89 E5 B8 01 00 00 00 5D C3 55 48 89 E5 41 57 41 56 41 55 41 54 53 48 83 EC 28";
//    uintptr_t devAddr = 0x3340;
//#endif
//
//    NSArray* devPtrs1 = [MemoryUtils getPtrFromMachineCode:(NSString*)@"/Contents/Frameworks/Sparkle.framework/Versions/A/Sparkle"
//                                machineCode:(NSString*)devHex
//                                    count:(int)1];
//    uintptr_t devPtrs2 = [MemoryUtils getPtrFromAddress:(NSString*)@"/Contents/Frameworks/Sparkle.framework/Versions/A/Sparkle"
//                                    targetFunctionAddress:(uintptr_t)devAddr];
//    // /Contents/Frameworks/Sparkle.framework/Versions/A/Sparkle > +[SPUDownloadData supportsSecureCoding]:
//    IMP imp = method_getImplementation(class_getClassMethod(objc_getClass("SPUDownloadData"), @selector(supportsSecureCoding)));
//    NSLogger(@"+[SPUDownloadData supportsSecureCoding] From Hex is 0x%llx", [devPtrs1[0] unsignedLongLongValue]);
//    NSLogger(@"+[SPUDownloadData supportsSecureCoding] From VA is 0x%lx", devPtrs2);
//    NSLogger(@"+[SPUDownloadData supportsSecureCoding] IMP: %p", imp);

    return YES;
}
@end
