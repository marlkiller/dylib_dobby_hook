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
            @"deviceID": @"88548e5a38eeee04e89c5621ba04bc7e",
            @"purchasedAt": @"2999-01-16",
            @"nextChargeAt": @(9999999999999), // Replace with the actual double value
            @"updatesAvailableUntil": @"2999-01-16" // Replace with the actual value
        };
        _rbx = [r12 initWithDictionary:propertyDictionary];;
    }
    return _rbx;
}


bool sub_100059E70New(int arg0, int arg1, int arg2, int arg3, int arg4){
    return 0x1;
}

int (*sub_10014AF90Ori)();

int (*sub_100059E70Ori)();

- (BOOL)hack {
    sub_10014AF90New(1,2,3,4);
    intptr_t _sub_10014AF90 = [Constant getBaseAddr:0] + 0x10014AF90;
    DobbyHook(_sub_10014AF90, sub_10014AF90New, (void *)&sub_10014AF90Ori);
//    intptr_t _sub_100059E70 = [Constant getBaseAddr:0] + 0x100059E70;
//    DobbyHook(_sub_100059E70, sub_100059E70New, (void *)&sub_100059E70Ori);
    return YES;
}

#endif





@end
