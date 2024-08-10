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
    return @"codes.rambo.AirBuddy";
}

- (NSString *)getSupportAppVersion {
    return @"2.";
}


void (*sub_10005ad20_ori)(void);
void hook_sub_10005ad20(void){
    NSLog(@">>>>>> hook_sub_10005bf30 is called");
//    
//    // cmp        byte [r13+0x99], 0x1
//    // (lldb) po 0x00006000008eeda0
//    // AirBuddy.LicenseStatusViewModel
//    uint64_t registerValue;
//#if defined(__arm64__) || defined(__aarch64__)
//    asm("mov %0, x20" : "=r" (registerValue)); // 获取 x20 寄存器的值
//#elif defined(__x86_64__)
////    asm("mov %0, r13" : "=r" (registerValue));// x32 ??
//    asm("movq %%r13, %0" : "=r" (registerValue));// 获取 r13 寄存器的值
//#endif
//    // 操作 寄存器+0x99 偏移
//    uint8_t *addressToCompare = (uint8_t *)(registerValue + 0x99);
//    uint8_t byteValue = *addressToCompare;
//    NSLog(@">>>>>> byteValue :%d",byteValue);
//    *addressToCompare = 0;
//    byteValue = *addressToCompare;
//    NSLog(@">>>>>> byteValue :%d",byteValue);
//    // 转为 id 类型
//    uint8_t *obj = (uint8_t *)(registerValue);
//    id objId = (__bridge id)(void *)obj;
//    NSLog(@">>>>>> objId %@",objId);
//    [MemoryUtils inspectObjectWithAddress:(void *)obj];
//    [MemoryUtils listAllPropertiesMethodsAndVariables:[objId class]];
//
    
#if defined(__arm64__) || defined(__aarch64__)
    __asm__ __volatile__(
        "strb wzr, [x20, #0x99]"
    );
#elif defined(__x86_64__)
//    __asm
//        {
//            mov byte ptr[r13+99h], 0
//        }
    __asm__ (
         "movb $0, 0x99(%r13)"
    );
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
    
    
    //    0000000100009718         mov        x0, #0x1f                                   ; CODE XREF=EntryPoint+128
    //    000000010000971c         mov        x1, #0x0
    //    0000000100009720         mov        x2, #0x0
    //    0000000100009724         mov        x3, #0x0
    //    0000000100009728         mov        x16, #0x1a
    //    000000010000972c         svc        #0x80
    //    0000000100009730         ret
    //    E0 03 80 D2 01 00 80 D2 02 00 80 D2 03 00 80 D2 50 03 80 D2 01 10 00 D4 C0 03 5F D6
    NSArray *ptrace_offsets =[MemoryUtils searchMachineCodeOffsets:
                                   searchFilePath
                                   machineCode:@"01 10 00 D4"
                                   count:(int)1
    ];
    intptr_t ptraceptr = [MemoryUtils getPtrFromGlobalOffset:0 targetFunctionOffset:(uintptr_t)[ptrace_offsets[0] unsignedIntegerValue] reduceOffset:(uintptr_t)fileOffset];
    // patch svc #0x80 with  >>>> nop:0x1F, 0x20, 0x03, 0xD5
    uint8_t nop4[4] = {0x1F, 0x20,0x03, 0xD5};
    DobbyCodePatch((void *)ptraceptr, nop4, 4);
    
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
    // defaults write codes.rambo.AirBuddy hasCompletedOnboarding -bool YES
    NSUserDefaults *defaults  = [NSUserDefaults standardUserDefaults];
    [defaults setBool:true forKey:@"AMSkipOnboarding"];
    [defaults synchronize];

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
