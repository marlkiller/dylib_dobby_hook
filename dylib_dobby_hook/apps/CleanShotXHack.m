//
//  CleanShotXHack.m
//  dylib_dobby_hook
//
//  Created by voidm on 2024/7/19.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "dobby.h"
#import "MemoryUtils.h"
#import <objc/runtime.h>
#import "HackProtocolDefault.h"
#include <sys/ptrace.h>
#import "common_ret.h"


@interface CleanShotXHack : HackProtocolDefault



@end


@implementation CleanShotXHack


- (NSString *)getAppName {
    return @"pl.maketheweb.cleanshotx";
}

- (NSString *)getSupportAppVersion {
    return @"4.";
}

- (BOOL)hack {
   
    NSString *searchFilePath = [[Constant getCurrentAppPath] stringByAppendingString:@"/Contents/MacOS/CleanShot X"];
    uintptr_t fileOffset =[MemoryUtils getCurrentArchFileOffset: searchFilePath];

    void* showCleanShotAWC = DobbySymbolResolver(
                        "/Contents/Frameworks/Legit.framework/Versions/A/Legit",
                        "_$s5Legit0A9CleanShotC11productName03appE07website5email8delegate15updaterDelegate16cloudAPIDelegateACSS_S3SAA0aK0_pAA0a7UpdaterK0_pAA0a5CloudM0_ptcfc"
     );
    DobbyHook(showCleanShotAWC, ret0, nil);
    
#if defined(__arm64__) || defined(__aarch64__)
    // TODO
    NSString *checkHex = @"A8 EC 78 D3 BF 00 43 F2 88 00 88 9A 07 BD 40 92 08 FC 50 D3 29 FC 50 D3 5F 00 04 EB";
#elif defined(__x86_64__)
    NSString *checkHex = @"48 89 F0 49 89 FA 4C 89 CE 48 C1 EE 38 83 E6 0F 49 0F BA E1 3D 49 0F 43 F0 49 BB FF FF FF FF FF FF 00 00 49 21 F3 48 C1 E8 10 4C 39 C2";
#endif
    NSArray *checkHexOffsets =[MemoryUtils searchMachineCodeOffsets:
                                       searchFilePath
                                       machineCode:checkHex
                                       count:(int)1
        ];
    
    intptr_t checkHexPtr = [MemoryUtils getPtrFromGlobalOffset:0 targetFunctionOffset:(uintptr_t)[checkHexOffsets[0] unsignedIntegerValue] reduceOffset:(uintptr_t)fileOffset];

    DobbyHook((void *)checkHexPtr, ret1, NULL);

    return YES;
}

@end
