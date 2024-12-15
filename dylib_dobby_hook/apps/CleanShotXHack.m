//
//  CleanShotXHack.m
//  dylib_dobby_hook
//
//  Created by voidm on 2024/7/19.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "tinyhook.h"
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

    void* showCleanShotAWC = symexp_solve(
                        [MemoryUtils indexForImageWithName:@"Legit"],
                        "_$s5Legit0A9CleanShotC11productName03appE07website5email8delegate15updaterDelegate16cloudAPIDelegateACSS_S3SAA0aK0_pAA0a7UpdaterK0_pAA0a5CloudM0_ptcfc"
     );
    tiny_hook(showCleanShotAWC, ret0, NULL);
    
#if defined(__arm64__) || defined(__aarch64__)
    NSString *checkHex = @"A8 EC 78 D3 BF 00 43 F2 88 00 88 9A 07 BD 40 92 08 FC 50 D3 29 FC 50 D3 5F 00 04 EB";
#elif defined(__x86_64__)
    NSString *checkHex = @"48 89 F0 49 89 FA 4C 89 CE 48 C1 EE 38 83 E6 0F 49 0F BA E1 3D 49 0F 43 F0 49 BB FF FF FF FF FF FF 00 00 49 21 F3 48 C1 E8 10 4C 39 C2";
#endif
    [MemoryUtils hookWithMachineCode:@"/Contents/MacOS/CleanShot X"
                             machineCode:checkHex
                               fake_func:(void *)ret1
                                   count:1];
    
#if defined(__arm64__) || defined(__aarch64__)
    NSString *sigaMachCode = @"FF 03 02 D1 E9 23 03 6D F8 5F 04 A9 F6 57 05 A9 F4 4F 06 A9 FD 7B 07 A9 FD C3 01 91 .. .. .. .. .. .. 41 F9 .. .. 00 B4";
    [MemoryUtils hookWithMachineCode:@"/Contents/MacOS/CleanShot X"
                             machineCode:sigaMachCode
                               fake_func:(void *)ret
                                   count:1];
#elif defined(__x86_64__)
    
#endif
    return YES;
}

@end
