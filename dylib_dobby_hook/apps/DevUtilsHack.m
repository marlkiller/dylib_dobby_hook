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

return YES;
}
@end
