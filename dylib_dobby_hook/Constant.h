//
//  constant.h
//  dylib_dobby_hook
//
//  Created by artemis on 2024/1/15.
//

#import <Foundation/Foundation.h>

@interface Constant : NSObject
+ (NSString *)getSystemArchitecture;
+ (BOOL)isDebuggerAttached;
+ (intptr_t)getBaseAddr:(uint32_t)index;
+ (NSArray<Class> *)getAllHackClasses;
+ (void)doHack;
@end
