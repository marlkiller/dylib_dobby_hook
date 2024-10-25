//
//  AlfredHack.m
//  dylib_dobby_hook
//
//  Created by asdf asd on 2024/10/13.
//



//  dylib_dobby_hook
//
//  Created by weizi on 2024/5/11.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "dobby.h"
#import "MemoryUtils.h"
#import <objc/runtime.h>
#include <sys/ptrace.h>
#import "common_ret.h"
#import "HackProtocolDefault.h"

@interface AlfredHack : HackProtocolDefault


@end


@implementation AlfredHack


- (NSString *)getAppName {
    // >>>>>> AppName is [com.runningwithcrayons.Alfred],Version is [5.5.1], myAppCFBundleVersion is [2273].
    // >>>>>> AppName is [com.runningwithcrayons.Alfred-Preferences],Version is [5], myAppCFBundleVersion is [1].
    return @"com.runningwithcrayons.Alfred";
}

- (NSString *)getSupportAppVersion {
    return @"5";
}

- (BOOL)hack {
    
    DobbyHook((void *)ptrace, (void *)my_ptrace, (void *)&orig_ptrace);
    
    void *symbol_address = DobbySymbolResolver("Alfred Framework", "_qrwG9chHdy1498");
    NSLogger(@"[qrwG9chHdy1498] address: %p",symbol_address);
    DobbyHook(symbol_address ,ret1, NULL);

    return YES;
}


@end
