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

    void *patch2 =
        symexp_solve([MemoryUtils indexForImageWithName:@"Legit"],
                     "_$s7SwCrypt2CCC3RSAC6verify_6derKey7padding6digest7saltLen10signedDataSb10Foundation0M0V_AnE19AsymmetricSAPaddingOAC15DigestAlgorithmOSiANtKFZ");
    tiny_hook(patch2, ret1, NULL);
    // TODO : mitm 把 valid 改成 true 就行了
#if defined(__arm64__) || defined(__aarch64__)
    NSString *checkHex = @"A8 EC 78 D3 89 BC 40 92 BF 00 43 F2 27 01 88 9A 08 FC 50 D3 29 FC 50 D3 5F 00 04 EB"; // 27 01 88 9A 08 FC 50 D3 29 FC 50 D3 5F 00 04 EB is not necessary
#elif defined(__x86_64__)
    NSString *checkHex = @"48 89 F0 49 89 FA 4D 89 CB 49 C1 EB"; // 4D 89 CB 49 C1 EB is not necessary
#endif
    [MemoryUtils hookWithMachineCode:@"/Contents/MacOS/CleanShot X"
                             machineCode:checkHex
                               fake_func:(void *)ret1
                                   count:1];
    
#if defined(__arm64__) || defined(__aarch64__)
    NSString *sigaMachCode = @"FF 03 02 D1 E9 23 03 6D F8 5F 04 A9 F6 57 05 A9 F4 4F 06 A9 FD 7B 07 A9 FD C3 01 91 .. .. .. .. .. .. .. F9 .. .. 00 B4";
    [MemoryUtils hookWithMachineCode:@"/Contents/MacOS/CleanShot X"
                             machineCode:sigaMachCode
                               fake_func:(void *)ret
                                   count:1];
#elif defined(__x86_64__)
    
#endif
    return YES;
}

@end
