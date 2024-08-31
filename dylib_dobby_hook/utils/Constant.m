//
//  constant.m
//  dylib_dobby_hook
//
//  Created by artemis on 2024/1/15.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "dobby.h"
#import <mach-o/dyld.h>
#import <objc/runtime.h>
#import <Cocoa/Cocoa.h>
#import "common_ret.h"
#include <mach-o/arch.h>
#include <sys/sysctl.h>
#import "HackProtocolDefault.h"
#import "HackHelperProtocolDefault.h"

@implementation Constant

// 使用构造函数属性 (constructor attribute) 的方法
// 这个方法会在 main 函数执行之前自动调用
static void __attribute__ ((constructor)) initialize(void){
        
    NSLog(@">>>>>> Constant ((constructor)) initialize(void)");

}


static NSString *G_EMAIL_ADDRESS = @"X'rq ol: zneyxvyyre@ibvqz.pbz";;
static NSString *G_EMAIL_ADDRESS_FMT = @"zneyxvyyre@ibvqz.pbz";;
static NSString *G_DYLIB_NAME = @"libdylib_dobby_hook.dylib";

static NSString *currentAppPath;
static NSString *currentAppName;
static NSString *currentAppVersion;
static NSString *currentAppCFBundleVersion;
static BOOL arm;
static BOOL helper;

// 告诉编译器不生成默认的 getter 和 setter 方法
@dynamic G_EMAIL_ADDRESS;
@dynamic G_EMAIL_ADDRESS_FMT;
@dynamic G_DYLIB_NAME;
@dynamic currentAppPath;
@dynamic currentAppName;
@dynamic currentAppVersion;
@dynamic currentAppCFBundleVersion;
@dynamic arm;
@dynamic helper;

+ (NSString *)G_EMAIL_ADDRESS {
    return love69(G_EMAIL_ADDRESS);
}
+ (NSString *)G_EMAIL_ADDRESS_FMT {
    return love69(G_EMAIL_ADDRESS_FMT);
}
+ (NSString *)G_DYLIB_NAME {
    return G_DYLIB_NAME;
}

+ (NSString *)currentAppName {
    return currentAppName;
}

+ (BOOL) isFirstOpen {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *currentVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]; // 获取当前的版本号
    NSString *storedVersion = [defaults objectForKey:@"appVersion"]; // 获取存储的版本号

    if (!storedVersion || ![storedVersion isEqualToString:currentVersion]) {
        // 这是第一次打开，或者是升级后第一次打开，你可以做一些初始化的操作
        [defaults setObject:currentVersion forKey:@"appVersion"]; // 更新版本号
        [defaults synchronize]; // 同步到磁盘
        return true;
    }
    return false;
}

// 类的初始化方法
// 当类第一次被使用时会自动调用这个方法
+ (void)initialize {
    if (self == [Constant class]) {
        NSLog(@">>>>>> Constant initialize");
        NSLog(@">>>>>> DobbyGetVersion: %s", DobbyGetVersion());

        NSBundle *app = [NSBundle mainBundle];
        currentAppName = [[app bundleIdentifier] copy];
        currentAppVersion =[ [app objectForInfoDictionaryKey:@"CFBundleShortVersionString"] copy];
        currentAppCFBundleVersion = [[app objectForInfoDictionaryKey:@"CFBundleVersion"] copy];
        NSLog(@">>>>>> AppName is [%s],Version is [%s], myAppCFBundleVersion is [%s].", currentAppName.UTF8String, currentAppVersion.UTF8String, currentAppCFBundleVersion.UTF8String);
        NSLog(@">>>>>> App Architecture is: %@", [Constant getSystemArchitecture]);
        NSLog(@">>>>>> App DebuggerAttached is: %d", [Constant isDebuggerAttached]);
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
        NSLog(@">>>>>> plistPath is %@", plistPath);
        NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];

        NSString *NSUserDefaultsPath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"Preferences/%@.plist", bundleIdentifier]];
        NSLog(@">>>>>> NSUserDefaultsPath is %@", NSUserDefaultsPath);
        NSRange range = [[Constant getSystemArchitecture] rangeOfString:@"arm" options:NSCaseInsensitiveSearch];
        arm = range.location != NSNotFound;
        
        // 这里不用 copy 的话, clion cmake 编译的产物会内存泄漏,字符串对象乱飞...不知道为什么
        // 返回包的完整路径。
        currentAppPath = [[app bundlePath] copy];
        NSLog(@">>>>>> [app bundlePath] %@",currentAppPath);
        // /Library/PrivilegedHelperTools
        if ([currentAppPath isEqualToString:@"/Library/PrivilegedHelperTools"]) {
            helper = YES;
        }
        
        // 返回应用程序执行文件的路径。
        // NSString *executablePath = [app executablePath];
        // 根据资源文件名、文件类型和子目录返回资源的路径。
        // NSString *resourcePath = [[NSBundle mainBundle] pathForResource:@"example" ofType:@"png" inDirectory:@"Images"];
        // 返回本地化字符串。
        // NSString *localizedString = [[NSBundle mainBundle] localizedStringForKey:@"Greeting" value:@"" table:@"Greetings"];
    }
}

+ (BOOL)isHelper {
    return helper;
}

+ (BOOL)isArm {
    return arm;
}

+ (NSString *)getCurrentAppPath {
    return currentAppPath;
}
+ (NSString *)getCurrentAppVersion {
    return currentAppVersion;
}
// currentAppVersion 有时会影响计算偏移位置,
// 所以 cache 偏移用这个 currentAppCFBundleVersion
+ (NSString *)getCurrentAppCFBundleVersion {
    return currentAppCFBundleVersion;
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
    if ([self isHelper]) {
        return [self getAllSubclassesOfClass:[HackHelperProtocolDefault class]];
    }else{
        return [self getAllSubclassesOfClass:[HackProtocolDefault class]];
    }
    
}

+ (NSArray<Class> *)getAllSubclassesOfClass:(Class)parentClass {
    NSMutableArray<Class> *subclasses = [NSMutableArray array];
    
    // 获取所有已加载的类
    unsigned int numClasses = 0;
    Class *classes = objc_copyClassList(&numClasses);
    for (int i = 0; i < numClasses; i++) {
        Class currentClass = classes[i];
        if ([self isSubclassOfClass:currentClass parentClass:parentClass] &&
            currentClass != parentClass) {
            [subclasses addObject:currentClass];
        }
    }
    
    free(classes);
    return [subclasses copy];
}

+ (BOOL)isSubclassOfClass:(Class)class parentClass:(Class)parentClass {
    while (class != nil) {
        if (class == parentClass) {
            return YES;
        }
        class = class_getSuperclass(class);
    }
    return NO;
}

+ (void)doHack {
    NSArray<Class> *personClasses = [Constant getAllHackClasses];
    
    for (Class class in personClasses) {

        id<HackProtocol> it = [[class alloc] init];
        
        if ([it shouldInject:currentAppName]) {
            NSString *supportAppVersion = [it getSupportAppVersion];
            if (supportAppVersion!=nil && supportAppVersion.length>0 && ![currentAppVersion hasPrefix:supportAppVersion]){
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
