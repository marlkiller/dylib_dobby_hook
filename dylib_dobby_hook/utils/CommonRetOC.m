//
//  CommonRetOC.m
//  dylib_dobby_hook
//
//  Created by voidm on 2024/7/27.
//

#import <Foundation/Foundation.h>
#import "CommonRetOC.h"
#import <CloudKit/CloudKit.h>
#import "MockCKContainer.h"
#import "MockUbiquitousKeyValueStore.h"
#import "URLSessionHook.h"
#import "common_ret.h"
#import "Logger.h"

@implementation CommonRetOC

- (void)ret {
    NSLogger(@"called - ret");
}
- (void)ret_ {
    NSLogger(@"called - ret_");
}
- (void)ret__ {
    NSLogger(@"called - ret__");
}

- (int)ret1 {
    NSLogger(@"called - ret1");
    return 1;
}
- (int)ret0 {
    NSLogger(@"called - ret0");
    return 0;
}
+ (int)ret1 {
    NSLogger(@"called + ret1");
    return 1;
}
+ (int)ret0 {
    NSLogger(@"called + ret0");
    return 0;
}
+ (void)ret {
    NSLogger(@"called + ret");
}


- (NSString *)getAppName { 
    return @"";
}

- (NSString *)getSupportAppVersion { 
    return @"";
}

- (void)firstLaunch {}

- (BOOL)shouldInject:(NSString *)target {
    NSString *appName = [self getAppName];
    return [target hasPrefix:appName];
}



- (BOOL)hack { 
    return NO;
}





+ (id)hook_defaultStore{
     NSLogger(@"hook_defaultStore");
     return [MockUbiquitousKeyValueStore defaultStore];
//    return class_createInstance([NSUbiquitousKeyValueStore class], 0);
}


- (id) hook_ubiquityIdentityToken {
    NSLogger(@"hook_ubiquityIdentityToken");
    return NULL;
}

- (id)hook_URLForUbiquityContainerIdentifier:(nullable NSString *)containerIdentifier{
    NSLogger(@"hook_URLForUbiquityContainerIdentifier containerIdentifier = %@",containerIdentifier);
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    NSURL *url = [[defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
    url = [url URLByAppendingPathComponent:containerIdentifier];
    
    BOOL isDirectory;
    if (![defaultManager fileExistsAtPath:[url path] isDirectory:&isDirectory] || !isDirectory) {
        NSError *error = nil;
        BOOL success = [defaultManager createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:&error];
        if (!success) {
            NSLogger(@"Failed to create directory: %@", error.localizedDescription);
        }
    } else {
        NSLogger(@"Directory already exists.");
    }
    return url;
}


+ (id)hook_containerWithIdentifier:identifier {
    NSLogger(@"hook_containerWithIdentifier identifier = %@",identifier);
    // [CKContainer containerWithIdentifier:identifier];
    return [MockCKContainer containerWithIdentifier:identifier];

}
+ (id)hook_defaultContainer {
    NSLogger(@"hook_defaultContainer");
    // [CKContainer defaultContainer];
    return [MockCKContainer defaultContainer];

}

#if TARGET_OS_OSX
- (void)hook_AllSecItem{
    NSLogger(@"hook_AllSecItem");
    tiny_hook(SecItemAdd, hk_SecItemAdd,  (void *)&SecItemAdd_ori);
    tiny_hook(SecItemUpdate, hk_SecItemUpdate, (void *)&SecItemUpdate_ori);
    tiny_hook(SecItemDelete, hk_SecItemDelete, (void *)&SecItemDelete_ori);
    tiny_hook(SecItemCopyMatching, hk_SecItemCopyMatching,(void *)&SecItemCopyMatching_ori);
}

#else
- (void)hook_AllSecItem{
    NSLogger(@"hook_AllSecItem");
}
#endif

- (void)hook_AllCloudKit{
    NSLogger(@"hook_AllCloudKit");
    [MemoryUtils hookClassMethod:
            NSClassFromString(@"NSUbiquitousKeyValueStore")
                originalSelector:NSSelectorFromString(@"defaultStore")
                   swizzledClass:[self class]
                swizzledSelector:@selector(hook_defaultStore)];

    [MemoryUtils hookClassMethod:
            NSClassFromString(@"CKContainer")
                originalSelector:NSSelectorFromString(@"containerWithIdentifier:")
                   swizzledClass:[self class]
                swizzledSelector:@selector(hook_containerWithIdentifier:)];
    [MemoryUtils hookClassMethod:
            NSClassFromString(@"CKContainer")
                originalSelector:NSSelectorFromString(@"defaultContainer")
                   swizzledClass:[self class]
                swizzledSelector:@selector(hook_defaultContainer)

    ];
}

#if TARGET_OS_OSX
- (void)hook_AllSecCode:teamIdentifier{
    static dispatch_once_t onceToken;
    static BOOL hasHooked = NO;
    if (hasHooked) {
        NSLogger(@"[Warning] hook_AllSecCode called multiple times! Skip hooking. teamIdentifier = %@", teamIdentifier);
        return;
    }
    dispatch_once(&onceToken, ^{
        hasHooked = YES;
        NSLogger(@"[Hook] hook_AllSecCode first time. teamIdentifier = %@", teamIdentifier);
        G_TEAM_IDENTITY_ORI = [teamIdentifier UTF8String];
    //    Security`SecStaticCodeCheckValidity:
    //        0x7ff8106bc4aa <+0>: pushq  %rbp
    //        0x7ff8106bc4ab <+1>: movq   %rsp, %rbp
    //        0x7ff8106bc4ae <+4>: xorl   %ecx, %ecx
    //        0x7ff8106bc4b0 <+6>: popq   %rbp
    //        0x7ff8106bc4b1 <+7>: jmp    0x7ff8106bc4b6            ; SecStaticCodeCheckValidityWithErrors
//        tiny_hook(SecCodeCheckValidity, (void *)hk_SecCodeCheckValidity, (void *)&SecCodeCheckValidity_ori);
//        tiny_hook(SecStaticCodeCheckValidity, (void *)hk_SecStaticCodeCheckValidity, (void *)&SecStaticCodeCheckValidity_ori);
        tiny_hook(SecCodeCheckValidityWithErrors, (void *)hk_SecCodeCheckValidityWithErrors, (void *)&SecCodeCheckValidityWithErrors_ori);
        tiny_hook(SecCodeCopySigningInformation, (void *)hk_SecCodeCopySigningInformation, (void *)&SecCodeCopySigningInformation_ori);
        tiny_hook(SecStaticCodeCheckValidityWithErrors, (void *)hk_SecStaticCodeCheckValidityWithErrors, (void *)&SecStaticCodeCheckValidityWithErrors_ori);
    });
    
//    TODO:Is it needed?
//    SecTaskValidateForRequirement
//    SecRequirementEvaluate
}
#else
- (void)hook_AllSecCode:teamIdentifier{
    
}
#endif


- (void)record_NSURL:filter{
    [URLSessionHook record_NSURL:filter];
};


@end
