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
#include <sys/ptrace.h>
#import <CloudKit/CloudKit.h>
#import "tinyhook.h"
#import "HackProtocolDefault.h"

@interface ForkLiftHack : HackProtocolDefault



@end


@implementation ForkLiftHack

- (NSString *)getAppName {
    // com.binarynights.ForkLiftHelper
    return @"com.binarynights.ForkLift";
}

- (NSString *)getSupportAppVersion {
    return @"4.";
}

+ (CKContainer *)containerWithIdentifier:identifier {
    return class_createInstance([CKContainer class], 0);
}

- (BOOL)hack {
   
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
    
    
    
    [MemoryUtils hookClassMethod:
         NSClassFromString(@"CKContainer")
                   originalSelector:NSSelectorFromString(@"containerWithIdentifier:")
                      swizzledClass:[self class]
                   swizzledSelector:@selector(containerWithIdentifier: )
    ];
    
    return YES;
}

@end
