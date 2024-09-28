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


@implementation CommonRetOC

- (void)ret {
    NSLog(@">>>>>> called - ret");
}
- (void)ret_ {
    NSLog(@">>>>>> called - ret_");
}
- (void)ret__ {
    NSLog(@">>>>>> called - ret__");
}

- (int)ret1 {
    NSLog(@">>>>>> called - ret1");
    return 1;
}
- (int)ret0 {
    NSLog(@">>>>>> called - ret0");
    return 0;
}
+ (int)ret1 {
    NSLog(@">>>>>> called + ret1");
    return 1;
}
+ (int)ret0 {
    NSLog(@">>>>>> called + ret0");
    return 0;
}
+ (void)ret {
    NSLog(@">>>>>> called + ret");
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
    NSLog(@">>>>>> hook_defaultStore");
    return [NSUserDefaults standardUserDefaults];
}

- (id)hook_NSFileManager:(nullable NSString *)containerIdentifier{
    NSLog(@">>>>>> hook_NSFileManager containerIdentifier = %@",containerIdentifier);
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    NSURL *url = [[defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
    url = [url URLByAppendingPathComponent:containerIdentifier];
    
    BOOL isDirectory;
    if (![defaultManager fileExistsAtPath:[url path] isDirectory:&isDirectory] || !isDirectory) {
        NSError *error = nil;
        BOOL success = [defaultManager createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:&error];
        if (!success) {
            NSLog(@">>>>>> Failed to create directory: %@", error.localizedDescription);
        }
    } else {
        NSLog(@">>>>>> Directory already exists.");
    }
    return url;
}


+ (id)hook_containerWithIdentifier:identifier {
    NSLog(@">>>>>> hook_containerWithIdentifier identifier = %@",identifier);
    // [CKContainer containerWithIdentifier:identifier];
    return [MockCKContainer containerWithIdentifier:identifier];

}
+ (id)hook_defaultContainer {
    NSLog(@">>>>>> hook_defaultContainer");
    // [CKContainer defaultContainer];
    return [MockCKContainer defaultContainer];

}



// TODO: 监听进程并执行线程注入
- (void)startMonitorInjection:processName {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        while (true) {
            @autoreleasepool {
//                pid_t pid = [EncryptionUtils getProcessIDByName:processName];
//                kern_return_t result = inject_dylib(pid, nil);
//                if (result == KERN_SUCCESS) {
//                    NSLog(@">>>>>> Successfully injected dylib into process %d", pid);
//                    return;
//                } else {
//                    NSLog(@">>>>>> Failed to inject dylib into process %d", pid);
//                }
            }
            [NSThread sleepForTimeInterval:5.0];  // 每 5 秒检查一次
        }
    });
}

@end
