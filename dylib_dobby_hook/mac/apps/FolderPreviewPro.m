//
//  FolderPreviewPro.m
//  dylib_dobby_hook
//
//  Created by NKR on 2025/9/15.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "tinyhook.h"
#import "MemoryUtils.h"
#import <objc/runtime.h>
#include <sys/ptrace.h>
#import "common_ret.h"
#import "HackProtocolDefault.h"

@interface FolderPreviewPro : HackProtocolDefault

@end

@implementation FolderPreviewPro


- (NSString *)getAppName {
    return @"ltd.anybox.FolderPreview.Pro";
}

- (NSString *)getSupportAppVersion {
    return @"";
}

- (BOOL)hack {

    NSUserDefaults *groupDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"S8MRM84X6F.group.ltd.anybox.FolderPreview.Pro"];
    [groupDefaults setObject:[Constant G_EMAIL_ADDRESS] forKey:@"licenseKey"];
    [groupDefaults setBool:YES forKey:@"isLicenseValid"];
    [groupDefaults synchronize];

    return YES;
}

@end
