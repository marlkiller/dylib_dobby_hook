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

@implementation Constant

static void __attribute__ ((constructor)) initialize(void){
    NSLog(@"Constant init");    
    NSBundle *app = [NSBundle mainBundle];
    appName = [app bundleIdentifier];
    appVersion = [app objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    appCFBundleVersion = [app objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSLog(@"AppName is [%s],Version is [%s], myAppCFBundleVersion is [%s].", appName.UTF8String, appVersion.UTF8String, appCFBundleVersion.UTF8String);
    
}

/**
 * App的唯一ID 用来过滤指定的App
 */
const NSString *appName;
/**
 * app的版本号
 */
const NSString *appVersion;
/**
 * 更精确的版本号 一般情况下不用到
 */
const NSString *appCFBundleVersion;


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
        NSLog(@"The current app running with debugging");
#if defined(__arm64__) || defined(__aarch64__)
        // 不知道为什么
        // arm 环境下,如果是调试模式, 计算地址不需要 + _dyld_get_image_vmaddr_slide,否则会出错
        return 0;
#endif
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
        NSString *appName = [it getAppName];
        if ([appName isEqualToString:appName]) {
            // TODO 执行其他操作 ,比如 checkVersion
            [it hack];
            break;
        }
    }
}
@end
