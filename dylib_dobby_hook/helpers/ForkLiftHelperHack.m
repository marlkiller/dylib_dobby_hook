//
//  ForkLiftHelperHack.m
//  dylib_dobby_hook
//
//  Created by voidm on 2024/7/27.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "MemoryUtils.h"
#import "common_ret.h"
#import <objc/runtime.h>
#include <sys/ptrace.h>
#import <CloudKit/CloudKit.h>
#import "tinyhook.h"
#import "HackHelperProtocolDefault.h"


@interface ForkLiftHelperHack : HackHelperProtocolDefault



@end


@implementation ForkLiftHelperHack

//static IMP listenerIMP;


- (NSString *)getAppName {
    return @"com.binarynights.ForkLiftHelper";
}

- (NSString *)getSupportAppVersion {
    return @"4.";
}


// Ref: https://book.hacktricks.xyz/v/cn/macos-hardening/macos-security-and-privilege-escalation/macos-proces-abuse/macos-ipc-inter-process-communication/macos-xpc/macos-xpc-authorization
- (BOOL)hk_listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {

    NSLogger(@"hk_listener");

    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:
                                           NSProtocolFromString(@"_TtP31com_binarynights_ForkLiftHelper21ForkLiftHelperProtcol_")
    ];
    newConnection.exportedObject = self;
    [newConnection resume];

    return YES;
}

 
- (BOOL)hack {
    
    //  [self hook_AllSecCode:@"J3CP9BBBN6"];
    // TODO: 可能是 dobby 的 bug, forklift helper 在 hook SecCodeCheckValidity 之后, 会导致出问题,
    // 而 将 Dobbyhook 替换成 DobbyCodePatch, 则没有问题...
    // 所以这里不用 hook_AllSecCode;    
    teamIdentifier_ori = "J3CP9BBBN6";
    tiny_hook(SecCodeCopySigningInformation, (void *)hk_SecCodeCopySigningInformation, (void *)&SecCodeCopySigningInformation_ori);
    tiny_hook(SecCodeCheckValidityWithErrors, (void *)hk_SecCodeCheckValidityWithErrors, (void *)&SecCodeCheckValidityWithErrors_ori);
    
//    Class ForkLiftHelper10HelperTool = NSClassFromString(@"_TtC31com_binarynights_ForkLiftHelper10HelperTool");
//    SEL listenerSel = NSSelectorFromString(@"listener:shouldAcceptNewConnection:");
//    Method listenerMethod = class_getInstanceMethod(ForkLiftHelper10HelperTool, listenerSel);
//    listenerIMP = method_getImplementation(listenerMethod);
//    [MemoryUtils hookInstanceMethod:ForkLiftHelper10HelperTool
//                   originalSelector:listenerSel
//                      swizzledClass:[self class]
//                   swizzledSelector:@selector(hk_listener:shouldAcceptNewConnection:)
//    ];
    return YES;
}

@end
