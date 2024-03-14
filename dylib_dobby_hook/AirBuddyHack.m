//
//  air_buddy_hack.m
//  dylib_dobby_hook
//
//  Created by artemis on 2024/1/15.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "dobby.h"
#import "MemoryUtils.h"
#import "HackProtocol.h"

@interface AirBuddyHack : NSObject <HackProtocol>

@end
@implementation AirBuddyHack


- (NSString *)getAppName {
    return @"codes.rambo.AirBuddy";
}

- (NSString *)getSupportAppVersion {
    // TODO
    return @"2.6.3";
}

- (BOOL)hack {
    [self hook];
    return YES;
}



#if defined(__arm64__) || defined(__aarch64__)
int (*_0x1000553b8Ori)();
int _0x1000553b8New() {
    // r20 + 0x99 != 0x1
    NSLog(@"==== _0x1000553b8New called");
    __asm__ __volatile__(
        "strb wzr, [x20, #0x99]"
    );
    NSLog(@"==== _0x1000553b8New call end");
    return _0x1000553b8Ori();
}

- (void)hook {
    NSLog(@"The current app running environment is __arm64__");
    intptr_t _0x1000553b8 =  [MemoryUtils getPtrFromAddress:0x1000553b8];
    DobbyHook(_0x1000553b8, _0x1000553b8New, (void *)&_0x1000553b8Ori);
    NSLog(@"_0x1000553b8 >> %p",_0x1000553b8);
}
#elif defined(__x86_64__)
int (*_0x100050480Ori)();
int _0x100050480New() {
    NSLog(@"==== _0x100050480New called");
    __asm
    {
        mov byte ptr[r13+99h], 0
    }
    NSLog(@"==== _0x100050480New call end");
    return _0x100050480Ori();
}
- (void)hook {
    NSLog(@"The current app running environment is __x86_64__");
    intptr_t _0x100050480 = [MemoryUtils getPtrFromAddress:0x100050480];
    DobbyHook(_0x100050480, _0x100050480New, (void *)&_0x100050480Ori);
    NSLog(@"_0x100050480 >> %p",_0x100050480);
}
#endif


@end
