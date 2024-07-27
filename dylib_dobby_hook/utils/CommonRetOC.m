//
//  CommonRetOC.m
//  dylib_dobby_hook
//
//  Created by voidm on 2024/7/27.
//

#import <Foundation/Foundation.h>
#import "CommonRetOC.h"

@implementation CommonRetOC

- (void)ret {
    NSLog(@">>>>>> called - ret");
}
- (void)ret_ {
    NSLog(@">>>>>> called - ret_");
}
- (void)ret__ {
    NSLog(@">>>>>> called - ret__");
}

- (int)ret1 {
    NSLog(@">>>>>> called - ret1");
    return 1;
}
- (int)ret0 {
    NSLog(@">>>>>> called - ret0");
    return 0;
}
+ (int)ret1 {
    NSLog(@">>>>>> called + ret1");
    return 1;
}
+ (int)ret0 {
    NSLog(@">>>>>> called + ret0");
    return 0;
}
+ (void)ret {
    NSLog(@">>>>>> called + ret");
}


- (NSString *)getAppName { 
    return @"EMPTY";
}

- (NSString *)getSupportAppVersion { 
    return @"EMPTY";
}

- (BOOL)hack { 
    return NO;
}

@end
