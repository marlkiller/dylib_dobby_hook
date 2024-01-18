//
//  TablePlusHack.m
//  dylib_dobby_hook
//
//  Created by artemis on 2024/1/15.
//

#import <Foundation/Foundation.h>
#import "TablePlusHack.h"
#import "Constant.h"
#import "dobby.h"
#import "MemoryUtils.h"
#import "tableplus/LicenseModel.h"
#import <objc/runtime.h>
#include <mach-o/dyld.h>

@implementation TablePlusHack


- (NSString *)getAppName {
    return @"com.tinyapp.TablePlus";
}

- (NSString *)getSupportAppVersion {
    return @"5.8.2";
}


const LicenseModel *_rbx;


#if defined(__arm64__) || defined(__aarch64__)


id sub_100131360New(int arg0, int arg1, int arg2, int arg3){
    if (_rbx==nil){
        LicenseModel *r12 = [[NSClassFromString(@"LicenseModel") alloc] init];
        NSDictionary *propertyDictionary = @{
            @"sign": @"fuckSign",
            @"email": @"marlkiller@voidm.com",
            // @"deviceID": @"88548e5a38eeee04e89c5621ba04bc7e",
            @"deviceID": @"",
            @"purchasedAt": @"2999-01-16",
            @"nextChargeAt": @(9999999999999), // Replace with the actual double value
            @"updatesAvailableUntil": @"2999-01-16" // Replace with the actual value
        };
        _rbx = [r12 initWithDictionary:propertyDictionary];;
    }
    return _rbx;
}


bool sub_100050ea0New(uint64_t arg0, uint64_t arg1, uint64_t arg2, uint64_t arg3, uint64_t arg4){
    if (_rbx!=nil && _rbx.deviceID==@""){
        
        // r1 = *(int128_t *)(arg2 + 0x28);
        uintptr_t *ptr = (uintptr_t *)(arg2 + 0x28);
        void * addressPtr = (void *) *ptr;
        // NSString * deviceId = [MemoryUtils readStringAtAddress:(addressPtr+0x20)];
        // NSLog(@"deviceId: %@", deviceId);
        // _rbx.deviceID =deviceId;
        // 从地址中读取字符串 deviceID 数据
        NSString *deviceId = [NSString stringWithCString:addressPtr+0x20 encoding:NSUTF8StringEncoding];
        _rbx.deviceID =deviceId;
        NSLog(@"deviceId: %@", deviceId);
        
    }
    return sub_100050ea0Ori(arg0,arg1,arg2,arg3,arg4);
}

int (*sub_100131360Ori)();

int (*sub_100050ea0Ori)();

- (BOOL)hack {
    
    
    
    
    //    0000000100131360         stp        x28, x27, [sp, #-0x60]!                     ; CODE XREF=sub_100131978+1360, sub_1002bbfcc+8
    //    0000000100131364         stp        x26, x25, [sp, #0x10]
    //    0000000100131368         stp        x24, x23, [sp, #0x20]
    //    000000010013136c         stp        x22, x21, [sp, #0x30]
    //    0000000100131370         stp        x20, x19, [sp, #0x40]
    //    0000000100131374         stp        fp, lr, [sp, #0x50]
    //    0000000100131378         add        fp, sp, #0x50
    //    000000010013137c         sub        sp, sp, #0x80
    //    0000000100131380         adrp       x0, #0x10083d000
    //    FC 6F BA A9 FA 67 01 A9 F8 5F 02 A9 F6 57 03 A9 F4 4F 04 A9 FD 7B 05 A9 FD 43 01 91 FF 03 02 D1 60
    
    NSString *searchFilePath = [[Constant getCurrentAppPath] stringByAppendingString:@"/Contents/MacOS/TablePlus"];
    
    
    NSArray *globalOffsets =[MemoryUtils searchMachineCodeOffsets:(NSString *)searchFilePath
                                                      machineCode:(NSString *) @"FC 6F BA A9 FA 67 01 A9 F8 5F 02 A9 F6 57 03 A9 F4 4F 04 A9 FD 7B 05 A9 FD 43 01 91 FF 03 02 D1 60"
                                                            count:(int)1];
    uintptr_t globalOffset = [globalOffsets[0] unsignedIntegerValue];
    uintptr_t fileOffset =[MemoryUtils getCurrentArchFileOffset: searchFilePath];
    
    sub_100131360New(1,2,3,4);
    
    intptr_t _sub_100131360 = [MemoryUtils getPtrFromGlobalOffset:0 targetFunctionOffset:(uintptr_t)globalOffset reduceOffset:(uintptr_t)fileOffset];
    DobbyHook((void *)_sub_100131360, (void *)sub_100131360New, (void *)&sub_100131360Ori);
    
    //    0000000100050ea0         stp        x24, x23, [sp, #-0x40]!
    //    0000000100050ea4         stp        x22, x21, [sp, #0x10]
    //    0000000100050ea8         stp        x20, x19, [sp, #0x20]
    //    0000000100050eac         stp        fp, lr, [sp, #0x30]
    //    0000000100050eb0         add        fp, sp, #0x30
    //    0000000100050eb4         ldr        x22, [x2, #0x10]
    //    0000000100050eb8         cbz        x22, loc_100050efc
    //    F8 5F BC A9 F6 57 01 A9 F4 4F 02 A9 FD 7B 03 A9 FD C3 00 91 56 08 40 F9 36
    
    
    globalOffsets = [MemoryUtils searchMachineCodeOffsets:(NSString *)searchFilePath
                                              machineCode:(NSString *) @"F8 5F BC A9 F6 57 01 A9 F4 4F 02 A9 FD 7B 03 A9 FD C3 00 91 56 08 40 F9 36"
                                                    count:(int)1];
    globalOffset = [globalOffsets[0] unsignedIntegerValue];
    fileOffset =[MemoryUtils getCurrentArchFileOffset: searchFilePath];
    intptr_t _sub_100050ea0 = [MemoryUtils getPtrFromGlobalOffset:0 targetFunctionOffset:(uintptr_t)globalOffset reduceOffset:(uintptr_t)fileOffset];
    DobbyHook((void *)_sub_100050ea0, (void *)sub_100050ea0New, (void *)&sub_100050ea0Ori);
    
    
    //    intptr_t _sub_100131360 = [MemoryUtils getPtrFromAddress:0x100131360];
    //    DobbyHook((void *)_sub_100131360, (void *)sub_100131360New, (void *)&sub_100131360Ori);
    //    intptr_t _sub_100050ea0 = [MemoryUtils getPtrFromAddress:0x100050ea0];;
    //    DobbyHook((void *)_sub_100050ea0,(void *) sub_100050ea0New, (void *)&sub_100050ea0Ori);
    
    return YES;
}

#elif defined(__x86_64__)


id sub_10014AF90New(int arg0, int arg1, int arg2, int arg3){
    if (_rbx==nil){
        LicenseModel *r12 = [[NSClassFromString(@"LicenseModel") alloc] init];
        NSDictionary *propertyDictionary = @{
            @"sign": @"fuckSign",
            @"email": @"marlkiller@voidm.com",
            // @"deviceID": @"ee4f1d1890b4eb49a5a4d7f195ca8b67",
            @"deviceID": @"",
            @"purchasedAt": @"2999-01-16",
            @"nextChargeAt": @(9999999999999), // Replace with the actual double value
            @"updatesAvailableUntil": @"2999-01-16" // Replace with the actual value
        };
        _rbx = [r12 initWithDictionary:propertyDictionary];;
    }
    return _rbx;
}


bool sub_100059E70New(uint64_t arg0, uint64_t arg1, uint64_t arg2, uint64_t arg3, uint64_t arg4){
    if (_rbx!=nil && _rbx.deviceID==@""){
        
        // mov        rsi, qword [rdx+0x28] ; real device id
        // rsi = *(arg2 + 0x28);
        
        // 地址要倒叙处理,垃圾写法
        // uint64_t _rsi = (arg2 + 0x28);
        // NSString * addressString = [MemoryUtils readMachineCodeStringAtAddress:(_rsi) length:(8)];
        // NSArray<NSString *> *byteStrings = [addressString componentsSeparatedByString:@" "];
        // NSMutableArray<NSString *> *reversedByteStrings = [NSMutableArray arrayWithCapacity:byteStrings.count];
        // // 将字节字符串倒序
        // for (NSInteger i = byteStrings.count - 1; i >= 0; i--) {
        //     [reversedByteStrings addObject:byteStrings[i]];
        // }
        // // 连接倒序后的字节字符串
        // NSString *reversedAddressString = [reversedByteStrings componentsJoinedByString:@""];
        // // 将倒序后的地址字符串转换为实际地址值
        // unsigned long long address = strtoull([reversedAddressString UTF8String], NULL, 16);
        // void *addressPtr = (void *)address;
        
        
        // 虽然看不明白, 但是这个写法短小精干
        // memory read ptr = 00 0f 3c 00 00 60 00 00,
        // memory read *ptr *ptr+100 = deviceId
        // addressPtr = 60 00 00 3c 0f 00
        uintptr_t *ptr = (uintptr_t *)(arg2 + 0x28);
        // NSLog(@"ptr: %#lx", ptr);
        void * addressPtr = (void *) *ptr;
        // NSString * deviceId = [MemoryUtils readStringAtAddress:(addressPtr+0x20)];
        // NSLog(@"deviceId: %@", deviceId);
        // _rbx.deviceID =deviceId;
        NSString *deviceId = [NSString stringWithCString:addressPtr+0x20 encoding:NSUTF8StringEncoding];
        _rbx.deviceID =deviceId;
        NSLog(@"deviceId: %@", deviceId);
    }
    return sub_100059E70Ori(arg0,arg1,arg2,arg3,arg4);
}

int (*sub_10014AF90Ori)();

int (*sub_100059E70Ori)();

- (BOOL)hack {
    
    
    //    000000010014af90         push       rbp                                         ; CODE XREF=sub_10014b5d0+1351, sub_1002fa1f0+4
    //    000000010014af91         mov        rbp, rsp
    //    000000010014af94         push       r15
    //    000000010014af96         push       r14
    //    000000010014af98         push       r13
    //    000000010014af9a         push       r12
    //    000000010014af9c         push       rbx
    //    000000010014af9d         sub        rsp, 0x98
    //    000000010014afa4         lea        rdi, qword [qword_1008ad698+8]              ; argument #1 for method sub_100015360, 0x1008ad6a0
    //    000000010014afab         call       sub_100015360
    //    55 48 89 E5 41 57 41 56 41 55 41 54 53 48 81 EC 98 00 00 00 48 8D 3D F5 26 76 00 E8
    
    NSString *searchFilePath = [[Constant getCurrentAppPath] stringByAppendingString:@"/Contents/MacOS/TablePlus"];
    NSString *searchMachineCode = @"55 48 89 E5 41 57 41 56 41 55 41 54 53 48 81 EC 98 00 00 00 48 8D 3D F5 26 76 00 E8";
    int count = 1;
    NSArray *globalOffsets =[MemoryUtils searchMachineCodeOffsets:(NSString *)searchFilePath machineCode:(NSString *)searchMachineCode count:(int)count];
    uintptr_t globalOffset = [globalOffsets[0] unsignedIntegerValue];
    uintptr_t fileOffset =[MemoryUtils getCurrentArchFileOffset: searchFilePath];
    
    intptr_t _sub_10014AF90 = [MemoryUtils getPtrFromGlobalOffset:0 targetFunctionOffset:(uintptr_t)globalOffset reduceOffset:(uintptr_t)fileOffset];
    DobbyHook((void *)_sub_10014AF90, (void *)sub_10014AF90New, (void *)&sub_10014AF90Ori);
    
    //    0000000100059e70         push       rbp                                         ;
    //    0000000100059e71         mov        rbp, rsp
    //    0000000100059e74         push       r15
    //    0000000100059e76         push       r14
    //    0000000100059e78         push       r13
    //    0000000100059e7a         push       r12
    //    0000000100059e7c         push       rbx
    //    0000000100059e7d         push       rax
    //    0000000100059e7e         mov        r12, qword [rdx+0x10]
    //    0000000100059e82         test       r12, r12
    //    55 48 89 E5 41 57 41 56 41 55 41 54 53 50 4C 8B 62 10 4D 85 E4 74
    
    sub_10014AF90New(1,2,3,4);
    
    
    globalOffsets = [MemoryUtils searchMachineCodeOffsets:(NSString *)searchFilePath
                                              machineCode:(NSString *) @"55 48 89 E5 41 57 41 56 41 55 41 54 53 50 4C 8B 62 10 4D 85 E4 74"
                                                    count:(int)1];
    globalOffset = [globalOffsets[0] unsignedIntegerValue];
    fileOffset =[MemoryUtils getCurrentArchFileOffset: searchFilePath];
    intptr_t _sub_100059E70 = [MemoryUtils getPtrFromGlobalOffset:0 targetFunctionOffset:(uintptr_t)globalOffset reduceOffset:(uintptr_t)fileOffset];
    DobbyHook((void *)_sub_100059E70, (void *)sub_100059E70New, (void *)&sub_100059E70Ori);
    
    //    intptr_t _sub_10014AF90 = [MemoryUtils getPtrFromGlobalOffset:0 targetFunctionOffset:(uintptr_t)globalOffset reduceOffset:(uintptr_t)fileOffset];
    //    DobbyHook(_sub_10014AF90, sub_10014AF90New, (void *)&sub_10014AF90Ori);
    //    intptr_t _sub_100059E70 = [MemoryUtils getPtrFromAddress:0x100059E70];
    //    DobbyHook(_sub_100059E70, sub_100059E70New, (void *)&sub_100059E70Ori);
    return YES;
}

#endif





@end
