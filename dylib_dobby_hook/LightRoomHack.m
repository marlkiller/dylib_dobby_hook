//
//  LightRoomHack.m
//  dylib_dobby_hook
//
//  Created by gyc on 2024/4/10.
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

@interface LightRoomHack : NSObject <HackProtocol>

@end


@implementation LightRoomHack



- (NSString *)getAppName {
    // >>>>>> AppName is [com.adobe.lightroomCC],Version is [7.2], myAppCFBundleVersion is [].
    return @"com.adobe.lightroomCC";
}

- (NSString *)getSupportAppVersion {
    return @"7.2";
}



- (BOOL)hack {
    
    NSString *searchFilePath = [[Constant getCurrentAppPath] stringByAppendingString:@"/Contents/MacOS/Adobe Lightroom"];
    // 获取文件中指定CPU架构段的偏移量
    uintptr_t fileOffset =[MemoryUtils getCurrentArchFileOffset: searchFilePath];
    
#if defined(__arm64__) || defined(__aarch64__)
    // TODO
    return false;
#elif defined(__x86_64__)
    NSString *get_licenseType =@"55 48 89 E5 41 57 41 56 41 54 53 48 83 EC .. .. .. F6 48 8B 07 48 8B 40 10 44 8B 78 08 .. .. .. 10 8B 58 30 48 8D 35 C1 69 1C 00 48 8D 7D C8 E8 83 F8 FF FF";

#endif
    
    //特征码搜索，在文件中搜索的
    NSArray *get_licenseTypeCodeOffsets =[MemoryUtils searchMachineCodeOffsets:
                                   searchFilePath
                                   machineCode:get_licenseType
                                   count:(int)1
    ];
    //获取特征码搜索到的函数实际在内存中的地址，，，理解是：执行文件在内存中加载的实际位置+偏移量，而偏移量=（特征码在文件中的位置-当前CPU类型的架构段基地值）
    intptr_t _get_licenseTypeCode =[MemoryUtils getPtrFromGlobalOffset:0 targetFunctionOffset:(uintptr_t)[get_licenseTypeCodeOffsets[0] unsignedIntegerValue] reduceOffset:(uintptr_t)fileOffset];

    // 将文件偏移量转换为内存地址// 确定 je 指令在get_license中的偏移量==0x10011970e - 0x1001196b9
    uintptr_t jumpInstructionMemoryAddress = 0x10011970e - 0x1001196b9 +_get_licenseTypeCode;

    // 验证内存地址处的机器码是否为 je 指令的机器码 (0x74)
    NSString *currentMachineCode =[MemoryUtils readMachineCodeStringAtAddress:jumpInstructionMemoryAddress length:1];
    NSLog(@"Machine code at address %p: %@", (void *)jumpInstructionMemoryAddress, currentMachineCode);
    if ([currentMachineCode isEqualToString:@"74"]) {
        // 如果是，则构造 jne (0x75) 指令的机器码字符串
        NSString *newMachineCode = @"75";
        // 写入新的机器码，writeMachineCodeString方法会导致试图写入只读内存崩溃
       // [MemoryUtils writeMachineCodeString:newMachineCode toAddress:jumpInstructionMemoryAddress];
        NSLog(@">>>>>> Before %s",[MemoryUtils readMachineCodeStringAtAddress:jumpInstructionMemoryAddress length:3].UTF8String);
        uint8_t ret1Day[1] = {0x75 };
        DobbyCodePatch((void *)jumpInstructionMemoryAddress, ret1Day,1);
        NSLog(@">>>>>> After %s",[MemoryUtils readMachineCodeStringAtAddress:jumpInstructionMemoryAddress length:3].UTF8String);
        NSString *machineCodeAfterWrite = [MemoryUtils readMachineCodeStringAtAddress:jumpInstructionMemoryAddress length:3];
        NSLog(@"Successfully changed JE to JNE at address: %p", (void *)jumpInstructionMemoryAddress);
        NSLog(@"Machine code at address %p: %@", (void *)jumpInstructionMemoryAddress, machineCodeAfterWrite);
        return YES;
    } else {
        // 如果不是，则记录一个错误并返回 NO
        NSLog(@"Expected JE instruction not found at address: %p", (void *)jumpInstructionMemoryAddress);
        return NO;
    }

    return YES;
}

@end

