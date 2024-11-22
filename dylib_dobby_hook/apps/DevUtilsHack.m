//
//  DevUtilsHack.m
//  dylib_dobby_hook
//
//  Created by voidm on 2024/1/26.
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



- (void)hk_showUnregistered{
    NSLogger(@"Swizzled showUnregistered method called");
}




- (BOOL)hack {
    
    NSString *searchFilePath = [[Constant getCurrentAppPath] stringByAppendingString:@"/Contents/MacOS/DevUtils"];
    
    
    [MemoryUtils hookInstanceMethod:
         objc_getClass("_TtC8DevUtils16WindowController")
           originalSelector:NSSelectorFromString(@"showUnregistered")
              swizzledClass:[self class]
           swizzledSelector:NSSelectorFromString(@"hk_showUnregistered")
    ];
    
    uintptr_t fileOffset =[MemoryUtils getCurrentArchFileOffset: searchFilePath];

    
    
#if defined(__arm64__) || defined(__aarch64__)
    
//    fun: -[DevUtils.Tool .cxx_destruct]
//    000000010004bd28         sub        sp, sp, #0x20                               ;
//    000000010004bd2c         stp        fp, lr, [sp, #0x10]
//    000000010004bd30         add        fp, sp, #0x10
//    000000010004bd34         ldp        x9, x8, [fp, arg_30]
//    000000010004bd38         ldrb       w10, [fp, arg_28] ; >>>> mov w10, #1
//    000000010004bd3c         ldp        x12, x11, [fp, arg_18]
//    000000010004bd40         ldp        x14, x13, [fp, arg_8]
    
    NSArray *globalOffsets =[MemoryUtils searchMachineCodeOffsets:(NSString *)searchFilePath
                                                      machineCode:(NSString *) @"AA E3 40 39"
                                                            count:(int)1];
    uintptr_t globalOffset = [globalOffsets[0] unsignedIntegerValue];
    intptr_t freeTrialPtr = [MemoryUtils getPtrFromGlobalOffset:[MemoryUtils indexForImageWithName:@"DevUtils"] globalFunOffset:(uintptr_t)globalOffset fileOffset:(uintptr_t)fileOffset];


//    NSLogger(@"Before %s",[MemoryUtils readMachineCodeStringAtAddress:freeTrialPtr length:4].UTF8String); // AA E3 40 39; ldrb       w10, [fp, arg_28]
    uint8_t freeTrialHex[4] = {0x2A,0x00,0x80,0x52};
    write_mem((void*)freeTrialPtr,(uint8_t *)freeTrialHex,4);
//    NSLogger(@"After %s",[MemoryUtils readMachineCodeStringAtAddress:freeTrialPtr length:4].UTF8String); // 2A 00 80 52; mov w10, #1


    
    
#elif defined(__x86_64__)
    
    // fun: -[_TtC8DevUtils4Tool .cxx_destruct]
    //__text:00000001000550E0                 push    rbp
    //__text:00000001000550E1                 mov     rbp, rsp
    //__text:00000001000550E4                 sub     rsp, 10h
    //__text:00000001000550E8                 mov     rax, cs:_OBJC_IVAR_$__TtC8DevUtils4Tool_name
    //__text:00000001000550EF                 mov     [r13+rax+0], rdx
    //__text:00000001000550F4                 mov     [r13+rax+8], rcx
    //__text:00000001000550F9                 mov     rax, cs:_OBJC_IVAR_$__TtC8DevUtils4Tool_toolDescription
    // ...
    //    0000000100055175         and        al, 0x1
    //    0000000100055177         mov        byte [r13+rcx], al
    //    24 01 41 88 44 0d 00
    
    NSArray *globalOffsets =[MemoryUtils searchMachineCodeOffsets:(NSString *)searchFilePath
                                                      machineCode:(NSString *) @"24 01 41 88 44 0d 00"
                                                            count:(int)1];
    uintptr_t globalOffset = [globalOffsets[0] unsignedIntegerValue];
    intptr_t freeTrialPtr = [MemoryUtils getPtrFromGlobalOffset:[MemoryUtils indexForImageWithName:@"DevUtils"] globalFunOffset:(uintptr_t)globalOffset fileOffset:(uintptr_t)fileOffset];


//    NSLogger(@"Before %s",[MemoryUtils readMachineCodeStringAtAddress:freeTrialPtr length:2].UTF8String); // 24 01 and        al, 0x1
    uint8_t freeTrialHex[2] = {0xB0,0x1};
    // uint8_t * freeTrialFlagPtr = freeTrialHex;
    write_mem((void*)freeTrialPtr,(uint8_t *)freeTrialHex,2);
//    NSLogger(@"After %s",[MemoryUtils readMachineCodeStringAtAddress:freeTrialPtr length:2].UTF8String); // B0 01 mov        al, 0x1

    
#endif
    
#if defined(__arm64__) || defined(__aarch64__)
    uintptr_t retxx = [MemoryUtils getPtrFromGlobalOffset:@"/Contents/MacOS/DevUtils" globalFunOffset:0x627d38];
    NSLogger(@"retxx1 = 0x%lx",retxx);
    uintptr_t retxx2 = [MemoryUtils getPtrFromAddress:@"/Contents/MacOS/DevUtils" targetFunctionAddress:0x10004bd38];
    NSLogger(@"retxx2 = 0x%lx",retxx2);
    
#elif defined(__x86_64__)    
    uintptr_t retxx = [MemoryUtils getPtrFromGlobalOffset:@"/Contents/MacOS/DevUtils" globalFunOffset:0x59175];
    NSLogger(@"retxx1 = 0x%lx",retxx);
    uintptr_t retxx2 = [MemoryUtils getPtrFromAddress:@"/Contents/MacOS/DevUtils" targetFunctionAddress:0x100055175];
    NSLogger(@"retxx2 = 0x%lx",retxx2);
#endif
    
    
    return YES;
}
@end
