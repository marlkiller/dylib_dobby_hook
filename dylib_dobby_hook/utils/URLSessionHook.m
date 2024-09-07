//
//  URLSessionHook.m
//  dylib_dobby_hook
//
//  Created by voidm on 2024/9/7.
//

#import <Foundation/Foundation.h>
#import "URLSessionHook.h"

@implementation URLSessionHook

- (void)resume {
    // 重写 resume 方法，使其不做任何事情
    NSLog(@">>>>>> DummyURLSessionDataTask.resume");
}

@end
