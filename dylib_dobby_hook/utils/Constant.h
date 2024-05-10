//
//  constant.h
//  dylib_dobby_hook
//
//  Created by artemis on 2024/1/15.
//

#import <Foundation/Foundation.h>

@interface Constant : NSObject
+ (BOOL) isFirstOpen;
+ (BOOL)isArm;
+ (NSString *)getCurrentAppPath;
+ (NSString *)getCurrentAppVersion;
+ (NSString *)getCurrentAppCFBundleVersion;
+ (NSString *)getSystemArchitecture;
+ (BOOL)isDebuggerAttached;
+ (NSArray<Class> *)getAllHackClasses;
+ (void)doHack;
@end
