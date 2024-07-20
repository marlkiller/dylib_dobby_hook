//
//  CleanShotXHack.m
//  dylib_dobby_hook
//
//  Created by voidm on 2024/7/19.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "MemoryUtils.h"
#import <objc/runtime.h>
#import "HackProtocol.h"
#include <sys/ptrace.h>


@interface ForkLiftHack : NSObject <HackProtocol>



@end


@implementation ForkLiftHack



- (NSString *)getAppName {
    return @"com.binarynights.ForkLift";
}

- (NSString *)getSupportAppVersion {
    return @"4.";
}


 
- (BOOL)hack {
    
    
//
//    ; struct ForkLift.RegistrationData {
//    ;     let name: Swift.String
//    ;     let quantity: Swift.Int
//    ;     let license_type: Swift.Int
//    ;     let validityDate: Foundation.Date
//    ;     let signature: Swift.String
//    ;     let licenseKey: Swift.String?
//    ; }
//_$s8ForkLift16RegistrationDataVMn:        // nominal type descriptor for ForkLift.RegistrationData
//00000001008327c0         struct __swift_StructDescriptor {                      ; "RegistrationData", DATA XREF=_$s8ForkLift16RegistrationDataVMa+7
//    struct __swift_ContextDescriptor {   // context
//        0x10051,                         // flags
//        _$s8ForkLiftMXM-0x1008327c4,     // parent context
//        aRegistrationda-0x1008327c8,     // name of the type
//        _$s8ForkLift16RegistrationDataVMa-0x1008327cc, // type accessor function pointer
//        _$s8ForkLift16RegistrationDataVMF-0x1008327d0 // fields
//    },
//    0x6,                                 // number of fields
//    0x2
//}
    // 自定义日期字符串
    NSDictionary *registrationDataDict = @{
        @"name": [Constant G_EMAIL_ADDRESS],
        @"quantity": @520,
        @"license_type": @1,
        @"validityDate": @1753025400, // @"2025-07-20 15:30:00",
        @"signature": @"SignatureExample",
        @"licenseKey": @"ABC123XYZ"
    };
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:registrationDataDict options:0 error:nil];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:jsonData forKey:@"registrationData"];
    [defaults synchronize];
    
    
    return YES;
}

@end
