//
//  air_buddy_hack.m
//  dylib_dobby_hook
//
//  Created by artemis on 2024/1/15.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "tinyhook.h"
#import "MemoryUtils.h"
#include "common_ret.h"
#include <sys/ptrace.h>
#import <objc/runtime.h>
#include <mach-o/dyld.h>
#import <Cocoa/Cocoa.h>
#import "HackProtocolDefault.h"

@interface AirBuddyHack : HackProtocolDefault

@end
@implementation AirBuddyHack



- (NSString *)getAppName {
    // >>>>>> AppName is [codes.rambo.AirBuddyHelper],Version is [2.7.3], myAppCFBundleVersion is [641].
    // >>>>>> AppName is [codes.rambo.AirBuddy],Version is [2.7.3], myAppCFBundleVersion is [641].
    return @"codes.rambo.AirBuddy";
}

- (NSString *)getSupportAppVersion {
    return @"2.";
}


void (*sub_10005ad20_ori)(void);
void hook_sub_10005ad20(void){
    NSLogger(@"hook_sub_10005bf30 is called");
//    uint64_t registerValue;
//#if defined(__arm64__) || defined(__aarch64__)
//    asm("mov %0, x20" : "=r" (registerValue)); // 获取 x20 寄存器的值
//#elif defined(__x86_64__)
//    asm("movq %%r13, %0" : "=r" (registerValue));// 获取 r13 寄存器的值
//#endif
    
#if defined(__arm64__) || defined(__aarch64__)
    __asm__ __volatile__(
        "strb wzr, [x20, #0x99]"
    );
#elif defined(__x86_64__)
    __asm__ (
         "movb $0, 0x99(%r13)"
    );
#endif
    return sub_10005ad20_ori();
}

- (BOOL)hack {

    tiny_hook(SecCodeCheckValidityWithErrors, (void *)hk_SecCodeCheckValidityWithErrors, (void *)&SecCodeCheckValidityWithErrors_ori);
    if ([[Constant getCurrentAppName] containsString:@"codes.rambo.AirBuddyHelper"]) {
        NSLogger(@"this is codes.rambo.AirBuddyHelper");
        return YES;
    }
    
    // 程序使用ptrace来进行动态调试保护，使得执行lldb的时候出现Process xxxx exited with status = 45 (0x0000002d)错误。
    // 使用 tiny_hook 替换 ptrace函数。
    tiny_hook((void *)ptrace, (void *)my_ptrace, (void *)&orig_ptrace);
    
    // AMSkipOnboarding
    // defaults write codes.rambo.AirBuddy hasCompletedOnboarding -bool YES
    NSUserDefaults *defaults  = [NSUserDefaults standardUserDefaults];
    [defaults setBool:true forKey:@"AMSkipOnboarding"];
    [defaults synchronize];
    
    Class PaddleBaseHackClass = NSClassFromString(@"PaddleBaseHack");
    id hackInstance = [[PaddleBaseHackClass alloc] init];
    [hackInstance performSelector:@selector(hack)];

    return YES;
}

@end
