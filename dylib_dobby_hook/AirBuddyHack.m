//
//  air_buddy_hack.m
//  dylib_dobby_hook
//
//  Created by artemis on 2024/1/15.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "dobby.h"
#import "MemoryUtils.h"
#import "HackProtocol.h"
#include "common_ret.h"
#include <sys/ptrace.h>
#import <objc/runtime.h>
#include <mach-o/dyld.h>
#import <Cocoa/Cocoa.h>

@interface AirBuddyHack : NSObject <HackProtocol>

@end
@implementation AirBuddyHack



- (NSString *)getAppName {
    return @"codes.rambo.AirBuddy";
}

- (NSString *)getSupportAppVersion {
    return @"2.";
}


void (*sub_10005ad20_ori)(void);
void hook_sub_10005ad20(void){
    NSLog(@">>>>>> hook_sub_10005bf30 is called");

    
#if defined(__arm64__) || defined(__aarch64__)
    __asm__ __volatile__(
        "strb wzr, [x20, #0x99]"
    );
#elif defined(__x86_64__)
    __asm
        {
            mov byte ptr[r13+99h], 0
        }
#endif
    return sub_10005ad20_ori();
}

- (BOOL)hack {
    // 程序使用ptrace来进行动态调试保护，使得执行lldb的时候出现Process xxxx exited with status = 45 (0x0000002d)错误。
    // 使用 DobbyHook 替换 ptrace函数。
    DobbyHook((void *)ptrace, (void *)my_ptrace, (void *)&orig_ptrace);
    
    
//    000000010005b077         call       imp___stubs__$sSS7AirCoreE27locLicenseStateNotActivatedSSvau ; 
//    (extension in AirCore):Swift.String.locLicenseStateNotActivated.unsafeMutableAddressor : Swift.String
    
//sub_10005ad20:
//000000010005ad20         push       rbp                                         ; CODE XREF=sub_10005aa90+89, sub_10005b670+266, sub_10005b7c0+133, sub_10005b7c0+374, sub_10005bf30+151, sub_10005c090+118
//000000010005ad21         mov        rbp, rsp
//000000010005ad24         push       r15
//000000010005ad26         push       r14
//000000010005ad28         push       r12
//000000010005ad2a         push       rbx
//000000010005ad2b         sub        rsp, 0x10
//000000010005ad2f         mov        r12, qword [r13+0x88]
//000000010005ad36         mov        rcx, qword [r13+0x90]
//000000010005ad3d         movzx      r15d, byte [r13+0x98]
//000000010005ad45         cmp        byte [r13+0x99], 0x1
//000000010005ad4d         jne        loc_10005ae1f
    
    NSString *searchFilePath = [[Constant getCurrentAppPath] stringByAppendingString:@"/Contents/MacOS/AirBuddy"];
    uintptr_t fileOffset =[MemoryUtils getCurrentArchFileOffset: searchFilePath];
    

#if defined(__arm64__) || defined(__aarch64__)
    NSString *sub_10005ad20_hex = @"F8 5F BC A9 F6 57 01 A9 F4 4F 02 A9 FD 7B 03 A9 FD C3 00 91 95 DA 48 A9 97 62 42 39 88 66 42 39 1F 05 00 71";
    
#elif defined(__x86_64__)
    NSString *sub_10005ad20_hex = @"55 48 89 E5 41 57 41 56 41 54 53 48 83 EC 10 4D 8B A5 .. .. .. ..";
#endif
    
    
    NSArray *sub_10005ad20_offsets =[MemoryUtils searchMachineCodeOffsets:
                                   searchFilePath
                                   machineCode:sub_10005ad20_hex
                                   count:(int)1
    ];
    intptr_t sub_10005ad20 = [MemoryUtils getPtrFromGlobalOffset:0 targetFunctionOffset:(uintptr_t)[sub_10005ad20_offsets[0] unsignedIntegerValue] reduceOffset:(uintptr_t)fileOffset];
    
    DobbyHook((void *)sub_10005ad20, (void *)hook_sub_10005ad20, (void *)&sub_10005ad20_ori);

   
    // AMSkipOnboarding
    NSUserDefaults *defaults  = [NSUserDefaults standardUserDefaults];
    [defaults setBool:true forKey:@"AMSkipOnboarding"];
//    boolForKeyImp = method_getImplementation(class_getInstanceMethod(NSClassFromString(@"NSUserDefaults"), NSSelectorFromString(@"boolForKey:")));
//    [MemoryUtils hookInstanceMethod:
//                objc_getClass("NSUserDefaults")
//                originalSelector:NSSelectorFromString(@"boolForKey:")
//                swizzledClass:[self class]
//                swizzledSelector:NSSelectorFromString(@"hk_boolForKey:")
//    ];
//    
    return YES;
}


// IMP boolForKeyImp = nil;
//- (Boolean)hk_boolForKey:(id)arg1{
//    NSLog(@">>>>>> hk_boolForKey is called with self: %@ and arg1: %@", self, arg1);
//    if ([arg1 isEqualToString:@"AMSkipOnboarding"]) {
//        return true;
//    }
//    Boolean *ret = ((Boolean *(*)(id, SEL,id))boolForKeyImp)(self, @selector(boolForKey:),arg1);
//    return *ret;
//}


@end
