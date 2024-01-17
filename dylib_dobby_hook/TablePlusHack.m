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
            @"deviceID": @"88548e5a38eeee04e89c5621ba04bc7e",
            @"purchasedAt": @"2999-01-16",
            @"nextChargeAt": @(9999999999999), // Replace with the actual double value
            @"updatesAvailableUntil": @"2999-01-16" // Replace with the actual value
        };
        _rbx = [r12 initWithDictionary:propertyDictionary];;
    }
    return _rbx;
}


bool sub_100050ea0New(int arg0, int arg1, int arg2, int arg3, int arg4){
    return 0x1;
}

int (*sub_100131360Ori)();

int (*sub_100050ea0Ori)();

- (BOOL)hack {
    sub_100131360New(1,2,3,4);
    intptr_t _sub_100131360 = [Constant getBaseAddr:0] + 0x100131360;
    DobbyHook(_sub_100131360, sub_100131360New, (void *)&sub_100131360Ori);
//    intptr_t _sub_100050ea0 = [Constant getBaseAddr:0] + 0x100050ea0  ;
//    DobbyHook(_sub_100050ea0, sub_100050ea0New, (void *)&sub_100050ea0Ori);
    return YES;
}
    
#elif defined(__x86_64__)


id sub_10014AF90New(int arg0, int arg1, int arg2, int arg3){
    if (_rbx==nil){
        LicenseModel *r12 = [[NSClassFromString(@"LicenseModel") alloc] init];
        NSDictionary *propertyDictionary = @{
            @"sign": @"fuckSign",
            @"email": @"marlkiller@voidm.com",
//            @"deviceID": @"ee4f1d1890b4eb49a5a4d7f195ca8b67",
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
        uint64_t _rsi = (arg2 + 0x28);
        // NSLog(@"_rsi: %p", _rsi);
        NSString * addressString = [MemoryUtils readMachineCodeStringAtAddress:(_rsi) length:(8)];
        NSArray<NSString *> *byteStrings = [addressString componentsSeparatedByString:@" "];
        NSMutableArray<NSString *> *reversedByteStrings = [NSMutableArray arrayWithCapacity:byteStrings.count];
        // 将字节字符串倒序
        for (NSInteger i = byteStrings.count - 1; i >= 0; i--) {
            [reversedByteStrings addObject:byteStrings[i]];
        }
        // 连接倒序后的字节字符串
        NSString *reversedAddressString = [reversedByteStrings componentsJoinedByString:@""];
        // 将倒序后的地址字符串转换为实际地址值
        unsigned long long address = strtoull([reversedAddressString UTF8String], NULL, 16);
        void *addressPtr = (void *)address;
        // NSLog(@"addressPtr: %p", addressPtr);
        NSString * deviceId = [MemoryUtils readStringAtAddress:(addressPtr+0x20)];
        NSLog(@"deviceId: %@", deviceId);
        _rbx.deviceID =deviceId;
    }
    return sub_100059E70Ori(arg0,arg1,arg2,arg3,arg4);
}

int (*sub_10014AF90Ori)();

int (*sub_100059E70Ori)();

- (BOOL)hack {
    sub_10014AF90New(1,2,3,4);
    intptr_t _sub_10014AF90 = [Constant getBaseAddr:0] + 0x10014AF90;
    DobbyHook(_sub_10014AF90, sub_10014AF90New, (void *)&sub_10014AF90Ori);
    intptr_t _sub_100059E70 = [Constant getBaseAddr:0] + 0x100059E70;
    DobbyHook(_sub_100059E70, sub_100059E70New, (void *)&sub_100059E70Ori);
    return YES;
}

#endif





@end
