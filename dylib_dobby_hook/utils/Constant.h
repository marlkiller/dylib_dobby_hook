//
//  constant.h
//  dylib_dobby_hook
//
//  Created by artemis on 2024/1/15.
//

#import <Foundation/Foundation.h>

@interface Constant : NSObject

@property (class, nonatomic, strong) NSString *G_EMAIL_ADDRESS;
@property (class, nonatomic, strong) NSString *G_EMAIL_ADDRESS_FMT;
@property (class, nonatomic, strong) NSString *G_DYLIB_NAME;

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
