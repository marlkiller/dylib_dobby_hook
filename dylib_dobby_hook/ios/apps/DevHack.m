//
//  DevHack.m
//  dylib_dobby_hook_ios
//
//  Created by voidm on 2025/9/5.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "tinyhook.h"
#import "MemoryUtils.h"
#import "HackProtocolDefault.h"
#import "common_ret.h"


@interface DevHack : HackProtocolDefault

@end

@implementation DevHack

- (NSString *)getAppName {
    return @"com.voidm.ios-app-dev-swift";
}

- (NSString *)getSupportAppVersion {
    return @"";
}



- (BOOL)hack {
  

    return YES;
}


@end
