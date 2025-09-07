//
//  LiveWallpaperHack.m
//  dylib_dobby_hook
//
//  Created by ooooooio on 2025/7/4.
//

#import <Foundation/Foundation.h>
#import "MemoryUtils.h"
#import <objc/runtime.h>
#import "HackProtocolDefault.h"

@interface LiveWallpaperHack : HackProtocolDefault



@end


@implementation LiveWallpaperHack

- (NSString *)getAppName {
    return @"whbalzac.Huajian";
}

- (NSString *)getSupportAppVersion {
    return @"";
}


- (BOOL)hack {

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@YES forKey:@"kSiShiIsVipString"];
    [defaults synchronize];
    
    return YES;
}

@end
