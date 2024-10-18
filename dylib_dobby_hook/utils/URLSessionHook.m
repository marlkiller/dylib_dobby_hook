//
//  URLSessionHook.m
//  dylib_dobby_hook
//
//  Created by voidm on 2024/9/7.
//

#import <Foundation/Foundation.h>
#import "URLSessionHook.h"
#import "Logger.h"

@implementation URLSessionHook

- (void)resume {
    // 重写 resume 方法，使其不做任何事情
    NSLogger(@"DummyURLSessionDataTask.resume");
}

@end
