//
//  ProxyManHack.m
//  dylib_dobby_hook
//
//  Created by 马治武 on 2024/4/9.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "dobby.h"
#import "MemoryUtils.h"
#import <objc/runtime.h>
#include <mach-o/dyld.h>
#import "HackProtocol.h"
#include <sys/ptrace.h>
#import "common_ret.h"

@interface ProxyManHack : NSObject <HackProtocol>

@end


@implementation ProxyManHack


- (NSString *)getAppName {
    // >>>>>> AppName is [com.proxyman.NSProxy],Version is [5.1.1], myAppCFBundleVersion is [50101].
    return @"com.proxyman.NSProxy";
}

- (NSString *)getSupportAppVersion {
    return @"5";
}



- (BOOL)hack {
    
    
    NSString *searchFilePath = [[Constant getCurrentAppPath] stringByAppendingString:@"/Contents/MacOS/Proxyman"];
    uintptr_t fileOffset =[MemoryUtils getCurrentArchFileOffset: searchFilePath];
    

#if defined(__arm64__) || defined(__aarch64__)
    NSString *sub_0x10001af90Code = @"F4 4F BE A9 FD 7B 01 A9 FD 43 00 91 F3 03 01 AA E1 03 00 AA .. .. 00 90 42 .. .. 91 48 80 5F F8 08 11 40 F9 E0 03 13 AA 00 01 3F D6 E0 03 13 AA FD 7B 41 A9 F4 4F C2 A8 C0 03 5F D6";
    NSString *remainingDaysCode = @".. .. .. 94 F4 03 00 AA F5 03 01 AA E0 83 01 91 .. .. .. 94 28 00 80 52 89 FE 7F D3 BF 02 00 72 34 01 88 1A";
#elif defined(__x86_64__)
    NSString *sub_0x10001af90Code = @"55 48 89 E5 53 50 48 89 F3 48 89 FE 48 8D .. .. .. .. .. 48 8B 42 F8 48 89 DF FF 50 20 48 89 D8 48 83 C4 08 5B 5D C3";
    NSString *remainingDaysCode =@"E8 .. .. .. .. 49 89 C6 41 89 D7 48 8D BD C8 FE FF FF E8 .. .. .. .. 41 B4 01 41 F6 C7 01 75 ..";

#endif
    
    
    NSArray *sub_0x10001af90Offsets =[MemoryUtils searchMachineCodeOffsets:
                                   searchFilePath
                                   machineCode:sub_0x10001af90Code
                                   count:(int)1
    ];
    intptr_t _sub_0x10001af90 = [MemoryUtils getPtrFromGlobalOffset:0 targetFunctionOffset:(uintptr_t)[sub_0x10001af90Offsets[0] unsignedIntegerValue] reduceOffset:(uintptr_t)fileOffset];
    
    
    NSArray *remainingDaysCodeOffsets =[MemoryUtils searchMachineCodeOffsets:
                                   searchFilePath
                                   machineCode:remainingDaysCode
                                   count:(int)1
    ];
    intptr_t _remainingDaysCode = [MemoryUtils getPtrFromGlobalOffset:0 targetFunctionOffset:(uintptr_t)[remainingDaysCodeOffsets[0] unsignedIntegerValue] reduceOffset:(uintptr_t)fileOffset];
//    000000010032a6b0         db         "You have reached the limit of free rules\n(Limit at %d)", 0
//     0x10001af90 ret 0 注册标识
//       frame #0: 0x00000001001324b0 Proxyman`___lldb_unnamed_symbol9700
//       frame #1: 0x00000001001adefb Proxyman`___lldb_unnamed_symbol12544 + 171 //  call       sub_1001324b0
//       frame #2: 0x00000001001ad9ef Proxyman`___lldb_unnamed_symbol12534 + 79 // call       sub_1001ade50
//       frame #3: 0x0000000102fb0e6c ProxymanCore`ProxymanCore.runOnMainThread(() -> ()) -> () + 140
//       frame #4: 0x00000001001ad313 Proxyman`___lldb_unnamed_symbol12530 + 595 // thread
//       frame #5: 0x0000000100054ae3 Proxyman`___lldb_unnamed_symbol4628 + 99 // call       sub_1001ad0c0 cmp 01 , // 需要 ret 0
    
    DobbyHook((void *)_sub_0x10001af90, ret0, nil);
    
    
    
    
    NSLog(@">>>>>> Before %s",[MemoryUtils readMachineCodeStringAtAddress:_remainingDaysCode length:8].UTF8String);
#if defined(__arm64__) || defined(__aarch64__)
    
    // nop:0x1F, 0x20, 0x03, 0xD5
    // mov x0,#1
    uint8_t ret1Day[4] = {0x20, 0x00, 0x80, 0xD2  };
    DobbyCodePatch((void *)_remainingDaysCode, ret1Day,4);
    
#elif defined(__x86_64__)
    //push 1,pop rax
    uint8_t ret1Day[5] = {0x6A, 0x01, 0x58, 0x90, 0x90  };
    DobbyCodePatch((void *)_remainingDaysCode, ret1Day,5);
#endif
    NSLog(@">>>>>> After %s",[MemoryUtils readMachineCodeStringAtAddress:_remainingDaysCode length:8].UTF8String);
    
    


    return YES;
}

@end
