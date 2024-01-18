//
//  constant.h
//  dylib_dobby_hook
//
//  Created by artemis on 2024/1/15.
//

#import <Foundation/Foundation.h>

@interface Constant : NSObject
+ (BOOL)isArm;
+ (NSString *)getCurrentAppPath;
+ (NSString *)getSystemArchitecture;
+ (BOOL)isDebuggerAttached;
+ (NSArray<Class> *)getAllHackClasses;
+ (void)doHack;
@end
