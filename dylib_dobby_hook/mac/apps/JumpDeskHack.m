//
//  JumpDeskHack.m
//  dylib_dobby_hook
//
//  Created by weizi on 2025/8/17.
//



#import <Foundation/Foundation.h>
#import "Constant.h"
#import "tinyhook.h"
#import "MemoryUtils.h"
#import <objc/runtime.h>
#include <sys/ptrace.h>
#import "common_ret.h"
#import "HackProtocolDefault.h"
//#include <mach/mach_vm.h>
//#import "Logger"

@interface JumpDesktopHack : HackProtocolDefault
//+ (id)buy_patch:(NSString *)searchFilePath;


@end

static IMP hook_check_jdlicenseIMP2;

@implementation JumpDesktopHack


- (NSString *)getAppName {
    return @"com.p5sys.jump.mac.viewer.web";
}

- (NSString *)getSupportAppVersion {
    return @"9.1.9";
}

- (BOOL)hack {
    NSString *searchFilePath = @"/Contents/MacOS/Jump Desktop";
    hook_check_jdlicense(searchFilePath);
    return YES;
}





void hook_check_jdlicense(NSString *searchFilePath) {
    tiny_hook((void *)ptrace, (void *)my_ptrace, (void *)&orig_ptrace);

    #if defined(__arm64__) || defined(__aarch64__)
        NSString *sub_0x100289CD8Code = @"F6 57 BD A9 F4 4F 01 A9 FD 7B 02 A9 FD 83 00 91 14 9F 00 F0 88 62 75 39 C8 00 00 34 20 00 80 52 FD 7B 42 A9 F4 4F 41 A9";
       
    #elif defined(__x86_64__)
        NSString *sub_0x100289CD8Code = @"55 48 89 E5 41 57 41 56 53 50 0F B6 05 77 19 70 01 84 C0 0F 85 BF 00 00 00 48 8B 3D A8 3A 6E 01";

    #endif
    
    NSLogger(@"hook_check : %@",searchFilePath);
    [MemoryUtils hookWithMachineCode:searchFilePath
                                machineCode:sub_0x100289CD8Code
                                  fake_func:(void *)ret1
                                      count:1
                               out_orig:(void *)&hook_check_jdlicenseIMP2
           ];

}



@end
