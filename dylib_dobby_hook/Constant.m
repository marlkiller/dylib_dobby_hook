//
//  constant.m
//  dylib_dobby_hook
//
//  Created by artemis on 2024/1/15.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import <mach-o/dyld.h>
#import <objc/runtime.h>
#import "HackProtocol.h"
#import <Cocoa/Cocoa.h>
#include <mach-o/arch.h>


@implementation Constant

static void __attribute__ ((constructor)) initialize(void){
    NSLog(@"Constant init");    

}
+ (void)initialize {
    if (self == [Constant class]) {
        NSBundle *app = [NSBundle mainBundle];
        currentAppName = [app bundleIdentifier];
        currentAppVersion = [app objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        currentAppCFBundleVersion = [app objectForInfoDictionaryKey:@"CFBundleVersion"];
        NSLog(@"AppName is [%s],Version is [%s], myAppCFBundleVersion is [%s].", currentAppName.UTF8String, currentAppVersion.UTF8String, currentAppCFBundleVersion.UTF8String);
        NSLog(@"AppName Architecture: %@", [Constant getSystemArchitecture]);
        NSLog(@"AppName DEBUGGING : %d", [Constant isDebuggerAttached]);
    }
}
/**
 * App的唯一ID 用来过滤指定的App
 */
const NSString *currentAppName;
/**
 * app的版本号
 */
const NSString *currentAppVersion;
/**
 * 更精确的版本号 一般情况下不用到
 */
const NSString *currentAppCFBundleVersion;

+ (NSString *)getSystemArchitecture {
    const NXArchInfo *archInfo = NXGetLocalArchInfo();

    if (archInfo) {
        return [NSString stringWithUTF8String:archInfo->name];
    } else {
        return nil;
    }
}


+ (BOOL)isDebuggerAttached {
    BOOL isDebugging = NO;
    // 获取当前进程的信息
    NSProcessInfo *processInfo = [NSProcessInfo processInfo];
    // 获取进程的环境变量
    NSDictionary *environment = [processInfo environment];
    // 检查环境变量中是否有调试器相关的标志
    if (environment != nil) {
        // 根据环境变量中是否包含特定的调试器标志来判断是否处于调试模式
        if (environment[@"DYLD_INSERT_LIBRARIES"] ||
            environment[@"MallocStackLogging"] ||
            environment[@"NSZombieEnabled"] ||
            environment[@"__XDEBUGGER_PRESENT"] != nil) {
            isDebugging = YES;
        }
    }
    return isDebugging;
}


+ (intptr_t)getBaseAddr:(uint32_t)index{
    BOOL isDebugging = [Constant isDebuggerAttached];
    if(isDebugging){
        // NSLog(@"The current app running with debugging");
        // 不知道为什么
        // 如果是调试模式, 计算地址不需要 + _dyld_get_image_vmaddr_slide,否则会出错
        return 0;

    }
    return _dyld_get_image_vmaddr_slide(index);
}


+ (NSArray<Class> *)getAllHackClasses {
    NSMutableArray<Class> *hackClasses = [NSMutableArray array];
    
    int numClasses;
    Class *classes = NULL;
    numClasses = objc_getClassList(NULL, 0);
    
    if (numClasses > 0) {
        classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * numClasses);
        numClasses = objc_getClassList(classes, numClasses);
        
        for (int i = 0; i < numClasses; i++) {
            Class class = classes[i];
            
            if (class_conformsToProtocol(class, @protocol(HackProtocol))) {
                [hackClasses addObject:class];
            }
        }
        free(classes);
    }
    return hackClasses;
}


+ (void)doHack {
    NSArray<Class> *personClasses = [Constant getAllHackClasses];
    
    for (Class class in personClasses) {
        id<HackProtocol> it = [[class alloc] init];
        if ([currentAppName isEqualToString:[it getAppName]]) {
            if (![currentAppVersion hasPrefix:[it getSupportAppVersion]]){
                NSAlert *alert = [[NSAlert alloc] init];
                [alert addButtonWithTitle:@"OK"];
                alert.messageText =  [NSString stringWithFormat:@"Unsupported current appVersion !!\nSuppert appVersion: [%s]\nCurrent appVersion: [%s]",[it getSupportAppVersion].UTF8String, currentAppVersion.UTF8String];;
                [alert runModal];
                return;
            }            
            [it hack];
            return;
        }
    }
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    alert.messageText =  [NSString stringWithFormat:@"Unsupported current app: [%s]", currentAppName.UTF8String];;
    [alert runModal];
    
}
@end
