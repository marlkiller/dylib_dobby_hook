//
//  DevUtilsHack.m
//  dylib_dobby_hook
//
//  Created by 马治武 on 2024/1/26.
//

#import <Foundation/Foundation.h>
#import "DevUtilsHack.h"
#import "Constant.h"
#import "dobby.h"
#import "MemoryUtils.h"
#import <objc/runtime.h>

@implementation DevUtilsHack


- (NSString *)getAppName {
    return @"tonyapp.devutils";
}

- (NSString *)getSupportAppVersion {
    return @"1.";
}



- (void)hk_showUnregistered{
    NSLog(@"Swizzled showUnregistered method called");
}




- (BOOL)hack {
    
    NSString *searchFilePath = [[Constant getCurrentAppPath] stringByAppendingString:@"/Contents/MacOS/DevUtils"];
    
    
    [MemoryUtils hookMethod:
         objc_getClass("_TtC8DevUtils16WindowController")
           originalSelector:NSSelectorFromString(@"showUnregistered")
              swizzledClass:[self class]
           swizzledSelector:NSSelectorFromString(@"hk_showUnregistered")
    ];
    
    
#if defined(__arm64__) || defined(__aarch64__)
    
    
    
    
#elif defined(__x86_64__)
    
    uintptr_t fileOffset =[MemoryUtils getCurrentArchFileOffset: searchFilePath];
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
    intptr_t freeTrialPtr = [MemoryUtils getPtrFromGlobalOffset:0 targetFunctionOffset:(uintptr_t)globalOffset reduceOffset:(uintptr_t)fileOffset];


    NSLog(@"%s",[MemoryUtils readMachineCodeStringAtAddress:freeTrialPtr length:2].UTF8String); // 24 01 and        al, 0x1
    uint8_t freeTrialHex[2] = {0xB0,0x1};
    // uint8_t * freeTrialFlagPtr = freeTrialHex;
    DobbyCodePatch((void*)0x100055175,(uint8_t *)freeTrialHex,2);
    NSLog(@"%s",[MemoryUtils readMachineCodeStringAtAddress:freeTrialPtr length:2].UTF8String); // B0 01 mov        al, 0x1

    
#endif
    
    return YES;
}
@end
