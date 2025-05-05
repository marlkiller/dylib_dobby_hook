//
//  ProxymanHelperHack.m
//  dylib_dobby_hook
//
//  Created by artemis on 2025/5/2.
//

#import <Foundation/Foundation.h>
#import "HackHelperProtocolDefault.h"
#import "MemoryUtils.h"

@interface ProxymanHelperHack : HackHelperProtocolDefault



@end


@implementation ProxymanHelperHack


- (NSString *)getAppName {
    return @"com.proxyman.NSProxy.HelperTool";
}

- (NSString *)getSupportAppVersion {
    return @"1.";
}
- (BOOL)hack {
    NSLogger(@"helper start");
    [MemoryUtils replaceInstanceMethod:NSClassFromString(@"HelperTool")
                      originalSelector:NSSelectorFromString(@"isValidConnectionWithCodeSign:forConnection:")
                         swizzledClass:[self class]
                      swizzledSelector:@selector(ret1)
    ];
    
    // -[HelperTool checkAuthorization:command:]
    [MemoryUtils replaceInstanceMethod:NSClassFromString(@"HelperTool")
                      originalSelector:NSSelectorFromString(@"checkAuthorization:command:")
                         swizzledClass:[self class]
                      swizzledSelector:@selector(ret0)
    ];
    
    return YES;
}

@end

