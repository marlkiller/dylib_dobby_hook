//
//  CleanMyMacHack.m
//  dylib_dobby_hook
//
//  Created by voidm on 2025/4/18.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "tinyhook.h"
#import "MemoryUtils.h"
#import <objc/runtime.h>
#include <sys/ptrace.h>
#import "common_ret.h"
#import "HackProtocolDefault.h"
#import <AppKit/AppKit.h>

@interface CleanMyMacHack : HackProtocolDefault


@end


@implementation CleanMyMacHack

- (NSString *)getAppName {
    return @"com.macpaw.CleanMyMac5";
}

- (NSString *)getSupportAppVersion {
    // AppName is [com.macpaw.CleanMyMac5],Version is [5.0.7], myAppCFBundleVersion is [50007.0.2503261326].
    return @"5.";
}

- (BOOL)hack {
    [self hook_AllSecCode:@"S8EX82NJP6"];

#if defined(__arm64__) || defined(__aarch64__)
    NSString *patch1Ori = @"61 00 00 54 1B 00 80 52 14 00 00 14";
    uint8_t patch1Target[12] = {0x1F,0x20,0x03,0xD5,0x3B,0x00,0x80,0x52,0x14,0x00,0x00,0x14};
#elif defined(__x86_64__)
    NSString *patch1Ori = @"75 05 45 31 E4 EB 55 80";
    uint8_t patch1Target[8] = {0x41, 0xBC, 0x01, 0x00, 0x00, 0x00, 0xEB, 0x54};

    
#endif
    NSArray *patch1Ptrs =[MemoryUtils getPtrFromMachineCode:(NSString *) @"/Contents/MacOS/CleanMyMac_5"
                                                      machineCode:(NSString *) patch1Ori
                                                            count:(int)1];
    uintptr_t patch1Ptr = [patch1Ptrs[0] unsignedIntegerValue];
    // int size = sizeof(patch1Target) / sizeof(patch1Target[0]);
    write_mem((void*)patch1Ptr,(uint8_t *)patch1Target,sizeof(patch1Target) / sizeof(patch1Target[0]));
    return YES;
}

@end
