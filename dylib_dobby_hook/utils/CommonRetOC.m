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



- (BOOL)shouldInject:(NSString *)target {
    NSString *appName = [self getAppName];
    return [target hasPrefix:appName];
}



- (BOOL)hack { 
    return NO;
}





+ (id)hook_defaultStore{
    NSLogger(@"hook_defaultStore");
    // return [NSUserDefaults standardUserDefaults];
    return NULL;
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


- (void)hook_AllSecItem{
    NSLogger(@"hook_AllSecItem");
    tiny_hook(SecItemAdd, hk_SecItemAdd, NULL);
    tiny_hook(SecItemUpdate, hk_SecItemUpdate, NULL);
    tiny_hook(SecItemDelete, hk_SecItemDelete, NULL);
    tiny_hook(SecItemCopyMatching, hk_SecItemCopyMatching, NULL);
}

- (void)hook_AllSecCode:teamIdentifier{
    NSLogger(@"teamIdentifier = %@",teamIdentifier);
    teamIdentifier_ori = [teamIdentifier UTF8String];
    tiny_hook(SecCodeCheckValidity, (void *)hk_SecCodeCheckValidity, (void *)&SecCodeCheckValidity_ori);
    tiny_hook(SecCodeCheckValidityWithErrors, (void *)hk_SecCodeCheckValidityWithErrors, (void *)&SecCodeCheckValidityWithErrors_ori);
    tiny_hook(SecCodeCopySigningInformation, (void *)hk_SecCodeCopySigningInformation, (void *)&SecCodeCopySigningInformation_ori);
    tiny_hook(SecStaticCodeCheckValidity, (void *)hk_SecStaticCodeCheckValidity, (void *)&SecStaticCodeCheckValidity_ori);
    tiny_hook(SecStaticCodeCheckValidityWithErrors, (void *)hk_SecStaticCodeCheckValidityWithErrors, (void *)&SecStaticCodeCheckValidityWithErrors_ori);
//    TODO:Is it needed?
//    SecTaskValidateForRequirement
//    SecRequirementEvaluate
}


// TODO: 监听进程并执行线程注入
- (void)startMonitorInjection:processName {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        while (true) {
            @autoreleasepool {
//                pid_t pid = [EncryptionUtils getProcessIDByName:processName];
//                kern_return_t result = inject_dylib(pid, nil);
//                if (result == KERN_SUCCESS) {
//                    NSLogger(@"Successfully injected dylib into process %d", pid);
//                    return;
//                } else {
//                    NSLogger(@"Failed to inject dylib into process %d", pid);
//                }
            }
            [NSThread sleepForTimeInterval:5.0];
        }
    });
}

@end
