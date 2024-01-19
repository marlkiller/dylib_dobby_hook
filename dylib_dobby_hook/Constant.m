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
#include <sys/sysctl.h>


@implementation Constant

static void __attribute__ ((constructor)) initialize(void){
    NSLog(@">>>>>> Constant init");    

}
+ (void)initialize {
    if (self == [Constant class]) {
        NSBundle *app = [NSBundle mainBundle];
        currentAppName = [app bundleIdentifier];
        currentAppVersion = [app objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        currentAppCFBundleVersion = [app objectForInfoDictionaryKey:@"CFBundleVersion"];
        NSLog(@">>>>>> AppName is [%s],Version is [%s], myAppCFBundleVersion is [%s].", currentAppName.UTF8String, currentAppVersion.UTF8String, currentAppCFBundleVersion.UTF8String);
        NSLog(@">>>>>> AppName Architecture: %@", [Constant getSystemArchitecture]);
        NSLog(@">>>>>> AppName DEBUGGING : %d", [Constant isDebuggerAttached]);
        NSRange range = [[Constant getSystemArchitecture] rangeOfString:@"arm" options:NSCaseInsensitiveSearch];
        isArm = range.location != NSNotFound;
        
        // 返回包的完整路径。
        currentAppPath = [app bundlePath];
        // 返回应用程序执行文件的路径。
        // NSString *executablePath = [app executablePath];
        // 根据资源文件名、文件类型和子目录返回资源的路径。
        // NSString *resourcePath = [[NSBundle mainBundle] pathForResource:@"example" ofType:@"png" inDirectory:@"Images"];
        // 返回本地化字符串。
        // NSString *localizedString = [[NSBundle mainBundle] localizedStringForKey:@"Greeting" value:@"" table:@"Greetings"];
        
    }
}

NSString *currentAppPath;
NSString *currentAppName;
NSString *currentAppVersion;
NSString *currentAppCFBundleVersion;
bool isArm;


+ (BOOL)isArm {
    return isArm;
}

+ (NSString *)getCurrentAppPath {
    return currentAppPath;
}

+ (NSString *)getSystemArchitecture {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *machineString = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
    free(machine);    
    return machineString;
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
