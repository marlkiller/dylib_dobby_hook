//
//  loveReadHack.m
//  dylib_dobby_hook_ios
//
//  Created by Gold on 2026/1/15.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "tinyhook.h"
#import "MemoryUtils.h"
#import "HackProtocolDefault.h"
#import "common_ret.h"

@interface loveReadHack : HackProtocolDefault

@end

@implementation loveReadHack

#pragma mark - App Information

/// 返回目标应用的Bundle ID
- (NSString *)getAppName {
    return @"com.xyStudio.loveRead";
}

/// 返回支持的应用版本（空字符串表示支持所有版本）
- (NSString *)getSupportAppVersion {
    return @"";
}

#pragma mark - Hook Implementation

/// 保存原始方法实现的指针
static IMP hookNSUserDefaultsBoolForKeyIMP;

/// Hook后的boolForKey:方法实现
/// @param defaultName UserDefaults的key
/// @return 如果是"isSuperVip"则返回YES，否则调用原始实现
- (BOOL)swizzled_boolForKey:(NSString *)defaultName {
    // 拦截VIP状态检查，始终返回YES
    if ([defaultName isEqualToString:@"isSuperVip"]) {
        return YES;
    }
    
    // 调用原始实现
    return ((BOOL(*)(id, SEL, NSString *))hookNSUserDefaultsBoolForKeyIMP)(self, _cmd, defaultName);
}

#pragma mark - Main Hack Entry

/// 执行Hook操作
/// @return 返回YES表示Hook成功
- (BOOL)hack {
    // Method 1: 直接修改UserDefaults（已注释）
    // 优点：简单直接
    // 缺点：可能被应用检测到，且需要持久化
    // [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isSuperVip"];
    // [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Method 2: Hook boolForKey:方法（当前使用）
    // 优点：更隐蔽，拦截所有读取操作
    // 缺点：需要更复杂的实现
    hookNSUserDefaultsBoolForKeyIMP = [MemoryUtils hookInstanceMethod:objc_getClass("NSUserDefaults")
                                                      originalSelector:NSSelectorFromString(@"boolForKey:")
                                                         swizzledClass:[self class]
                                                       swizzledSelector:@selector(swizzled_boolForKey:)];
    
    return YES;
}

@end
