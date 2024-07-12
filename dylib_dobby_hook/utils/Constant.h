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

@property (class, nonatomic, strong) NSString *currentAppPath;
@property (class, nonatomic, strong) NSString *currentAppName;
@property (class, nonatomic, strong) NSString *currentAppVersion;
@property (class, nonatomic, strong) NSString *currentAppCFBundleVersion;
@property (class, nonatomic, assign) BOOL arm;



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
