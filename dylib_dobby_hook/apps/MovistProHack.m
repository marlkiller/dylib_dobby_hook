//
//  MovistProHack.m
//  dylib_dobby_hook
//
//  Created by 马治武 on 2024/4/17.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "HackProtocolDefault.h"


@interface MovistProHack : HackProtocolDefault

@end

@implementation MovistProHack

- (NSString *)getAppName {
    return @"com.movist.MovistPro";
}

- (NSString *)getSupportAppVersion {
    // >>>>>> AppName is [com.movist.MovistPro],Version is [2.11.4], myAppCFBundleVersion is [221].
    return @"2.";
}


- (BOOL)hack {
        

    id paddleBaseHackClz = [[NSClassFromString(@"PaddleBaseHack") alloc] init];
    SEL selector = NSSelectorFromString(@"hack");
    if ([paddleBaseHackClz respondsToSelector:selector]) {
        NSMethodSignature *methodSignature = [paddleBaseHackClz methodSignatureForSelector:selector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        [invocation setSelector:selector];
        [invocation invokeWithTarget:paddleBaseHackClz];
    } else {
        NSLog(@">>>>>> Error: paddleBaseHackClz does not respond to selector 'hack'");
    }
    return YES;
}
@end
