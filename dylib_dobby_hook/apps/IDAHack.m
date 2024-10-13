//
//  IDAHack.m
//  dylib_dobby_hook
//
//  Created by voidm on 2024/8/10.
//

#import <Foundation/Foundation.h>
#import "dobby.h"
#import "common_ret.h"
#import "HackProtocolDefault.h"
#import <objc/objc-exception.h>

@interface IDAHack : HackProtocolDefault



@end


@implementation IDAHack

- (NSString *)getAppName {
//    >>>>>> AppName is [com.hexrays.ida64],Version is [9.0.240807], myAppCFBundleVersion is [240807].
//    >>>>>> AppName is [com.hexrays.ida],Version is [9.0.240925], myAppCFBundleVersion is [240925].
    return @"com.hexrays.ida";
}

- (NSString *)getSupportAppVersion {
    
    return @"9.";
}
- (BOOL)hack {
    
   
    // libida32.dylib/libida64.dylib
    // ED FD 42 5C F9 78 -> ED FD 42 CB F9 78


    DobbyHook(objc_addExceptionHandler, (void *)ret0, NULL);
    DobbyHook(objc_removeExceptionHandler, (void *)ret0, NULL);

    
    return YES;
}


@end
