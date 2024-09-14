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
#import "dobby.h"
#import "HackHelperProtocolDefault.h"


@interface ForkLiftHelperHack : HackHelperProtocolDefault



@end


@implementation ForkLiftHelperHack

static IMP listenerIMP;


- (NSString *)getAppName {
    return @"com.binarynights.ForkLiftHelper";
}

- (NSString *)getSupportAppVersion {
    return @"4.";
}


- (BOOL)hk_listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {

    NSLog(@">>>>>> hk_listener");

    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:
                                           NSProtocolFromString(@"_TtP31com_binarynights_ForkLiftHelper21ForkLiftHelperProtcol_")
    ];
    newConnection.exportedObject = self;
    [newConnection resume];

    return YES;
}


OSStatus hk_SecCodeCopySigningInformation_forklift(SecCodeRef codeRef, SecCSFlags flags, CFDictionaryRef *signingInfo) {

    OSStatus status = SecCodeCopySigningInformation_ori(codeRef, flags, signingInfo);
    NSLog(@">>>>>> hk_SecCodeCopySigningInformation_ori status = %d",  status);

    CFMutableDictionaryRef fakeDict = CFDictionaryCreateMutableCopy(NULL, 0, *signingInfo);

    SInt32 number = (SInt32) 65536;
    CFNumberRef flagsVal = CFNumberCreate(NULL, kCFNumberSInt32Type, &number);
    if (flagsVal) {
        CFDictionarySetValue(fakeDict,  kSecCodeInfoFlags, flagsVal);
        CFRelease(flagsVal);
    }
   
    CFStringRef teamId = CFStringCreateWithCString(NULL, "J3CP9BBBN6", kCFStringEncodingUTF8);
    if (teamId) {
        CFDictionarySetValue(fakeDict,  kSecCodeInfoTeamIdentifier, teamId);
        CFRelease(teamId);
    }
    
    
    NSDictionary *entitlementsDict = @{
        @"com.apple.security.cs.allow-dyld-environment-variables": @0,
        @"com.apple.security.cs.allow-jit": @1,
        @"com.apple.security.cs.allow-unsigned-executable-memory": @1,
        @"com.apple.security.cs.disable-executable-page-protection": @1,
        @"com.apple.security.cs.disable-library-validation": @0,
        @"com.apple.security.get-task-allow": @1
    };
    CFDictionarySetValue(fakeDict,  kSecCodeInfoEntitlementsDict, (__bridge const void *)(entitlementsDict));

    CFRelease(*signingInfo);
    *signingInfo = fakeDict;
    
    NSLog(@">>>>>> hk_SecCodeCopySigningInformation_ori kSecCodeInfoFlags = %@", (CFNumberRef)CFDictionaryGetValue(*signingInfo, kSecCodeInfoFlags));
    NSLog(@">>>>>> hk_SecCodeCopySigningInformation_ori entitlementsDict = %@", (CFDictionaryRef)CFDictionaryGetValue(*signingInfo, kSecCodeInfoEntitlementsDict));
    NSLog(@">>>>>> hk_SecCodeCopySigningInformation_ori kSecCodeInfoTeamIdentifier = %@", (CFDictionaryRef)CFDictionaryGetValue(*signingInfo, kSecCodeInfoTeamIdentifier));

    return errSecSuccess;
}
 
- (BOOL)hack {
     DobbyHook(SecCodeCopySigningInformation, (void *)hk_SecCodeCopySigningInformation_forklift, (void *)&SecCodeCopySigningInformation_ori);
     DobbyHook(SecCodeCheckValidityWithErrors, (void *)hk_SecCodeCheckValidityWithErrors, (void *)&SecCodeCheckValidityWithErrors_ori); 
    
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
