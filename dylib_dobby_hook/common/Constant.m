//
//  constant.m
//  dylib_dobby_hook
//
//  Created by artemis on 2024/1/15.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "tinyhook.h"
#import <mach-o/dyld.h>
#import <objc/runtime.h>
#if TARGET_OS_OSX
#import <Cocoa/Cocoa.h>
#endif
#import "common_ret.h"
#include <mach-o/arch.h>
#include <sys/sysctl.h>
#import "HackProtocolDefault.h"
#import "HackHelperProtocolDefault.h"
#import "Logger.h"


// 使用构造函数属性 (constructor attribute) 的方法
// 这个方法会在 main 函数执行之前自动调用
static void __attribute__ ((constructor)) initialize(void){
    // printf(">>>>>> Constant ((constructor)) initialize(void)\n");
}

@implementation Constant

NSString *const CRACKED_MSG = @"CURRENT CRACKED VERSION — NO FUCKING API. NO FUCKIN’ RESPECT. BUY THE LEGIT ONE, POSER.";

static NSString *_G_EMAIL_ADDRESS = @"X'rq ol: zneyxvyyre@ibvqz.pbz";;
static NSString *_G_EMAIL_ADDRESS_FMT = @"zneyxvyyre@ibvqz.pbz";;
static NSString *_G_DYLIB_NAME = @"libdylib_dobby_hook.dylib";

static NSString *_currentAppPath;
static NSString *_currentAppName;
static NSString *_currentAppVersion;
static NSString *_currentAppCFBundleVersion;
static BOOL _arm;
static BOOL _helper;

// 告诉编译器不生成默认的 getter 和 setter 方法
//@dynamic G_EMAIL_ADDRESS;
//@dynamic G_EMAIL_ADDRESS_FMT;
//@dynamic G_DYLIB_NAME;
//@dynamic currentAppPath;
//@dynamic currentAppName;
//@dynamic currentAppVersion;
//@dynamic currentAppCFBundleVersion;
//@dynamic arm;
//@dynamic helper;

+ (NSString *)G_EMAIL_ADDRESS {
    return love69(_G_EMAIL_ADDRESS);
}
+ (NSString *)G_EMAIL_ADDRESS_FMT {
    return love69(_G_EMAIL_ADDRESS_FMT);
}
+ (NSString *)G_DYLIB_NAME {
    return _G_DYLIB_NAME;
}

+ (NSString *)getCurrentAppName {
    return _currentAppName;
}

+ (BOOL) isFirstOpen {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *currentVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]; // 获取当前的版本号
    NSString *storedVersion = [defaults objectForKey:@"inject_appVersion"]; // 获取存储的版本号

    if (!storedVersion || ![storedVersion isEqualToString:currentVersion]) {
        // 这是第一次打开，或者是升级后第一次打开，你可以做一些初始化的操作
        [defaults setObject:currentVersion forKey:@"inject_appVersion"]; // 更新版本号
        [defaults synchronize]; // 同步到磁盘
        return true;
    }
    return false;
}

// 类的初始化方法
// 当类第一次被使用时会自动调用这个方法
+ (void)initialize {
    if (self == [Constant class]) {
        NSLogger(@"Constant initialize");
        // NSLogger(@"DobbyGetVersion: %s", DobbyGetVersion());

        NSBundle *app = [NSBundle mainBundle];
        _currentAppName = [[app bundleIdentifier] copy];
        _currentAppVersion =[ [app objectForInfoDictionaryKey:@"CFBundleShortVersionString"] copy];
        _currentAppCFBundleVersion = [[app objectForInfoDictionaryKey:@"CFBundleVersion"] copy];
        NSLogger(@"AppName is [%s],Version is [%s], myAppCFBundleVersion is [%s].", _currentAppName.UTF8String, _currentAppVersion.UTF8String, _currentAppCFBundleVersion.UTF8String);
        NSLogger(@"App Architecture is: %@", [Constant getSystemArchitecture]);
        NSLogger(@"App DebuggerAttached is: %d", [Constant isDebuggerAttached]);
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
        NSLogger(@"plistPath is %@", plistPath);
        NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];

        NSString *NSUserDefaultsPath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"Preferences/%@.plist", bundleIdentifier]];
        NSLogger(@"NSUserDefaultsPath is %@", NSUserDefaultsPath);
        NSRange range = [[Constant getSystemArchitecture] rangeOfString:@"arm" options:NSCaseInsensitiveSearch];
        _arm = range.location != NSNotFound;
        
        // 这里不用 copy 的话, clion cmake 编译的产物会内存泄漏,字符串对象乱飞...不知道为什么
        // 返回包的完整路径。
        _currentAppPath = [[app bundlePath] copy];
        NSLogger(@"[app bundlePath] %@",_currentAppPath);
        // /Library/PrivilegedHelperTools
        if ([_currentAppPath isEqualToString:@"/Library/PrivilegedHelperTools"]) {
            NSLogger(@"helper is True");
            _helper = YES;
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
    return _helper;
}

+ (BOOL)isArm {
    return _arm;
}

+ (NSString *)getCurrentAppPath {
    return _currentAppPath;
}
+ (NSString *)getCurrentAppVersion {
    return _currentAppVersion;
}
// currentAppVersion 有时会影响计算偏移位置,
// 所以 cache 偏移用这个 currentAppCFBundleVersion
+ (NSString *)getCurrentAppCFBundleVersion {
    return _currentAppCFBundleVersion;
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
    int                 junk;
    int                 mib[4];
    struct kinfo_proc   info;
    size_t              size;

    info.kp_proc.p_flag = 0;

    mib[0] = CTL_KERN;
    mib[1] = KERN_PROC;
    mib[2] = KERN_PROC_PID;
    mib[3] = getpid();

    size = sizeof(info);
    junk = sysctl(mib, sizeof(mib) / sizeof(*mib), &info, &size, NULL, 0);
    assert(junk == 0);

    // If P_TRACED flag set, debugger running
    return ( (info.kp_proc.p_flag & P_TRACED) != 0 );
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


#if TARGET_OS_OSX
BOOL canShowAlert(void) {
    NSString *path = [[[NSProcessInfo processInfo] arguments] firstObject];
    
    // 检查路径
    if ([path hasPrefix:@"/System/Library/"] || [path hasPrefix:@"/usr/bin/"]) {
        NSLogger(@"Path starts with /usr/bin/, UI alert not allowed.");
        return NO;
    }
    
    if ([Constant isHelper]) {
        NSLogger(@"Process is a helper, UI alert not allowed.");
        return NO;
    }
//    NSApplicationActivationPolicyRegular： 普通应用，能在 Dock 中显示，接受用户输入。例如：Safari、Mail。
//    NSApplicationActivationPolicyAccessory： 辅助应用，不在 Dock 中显示，但可以在菜单栏中显示图标。通常用于后台工具。
//    NSApplicationActivationPolicyProhibited： 被禁止激活的应用，不显示在 Dock 中，也无法接受输入。常用于后台服务。
    NSApplicationActivationPolicy policy = [NSRunningApplication currentApplication].activationPolicy;
    BOOL isForeground = (policy == NSApplicationActivationPolicyRegular || policy == NSApplicationActivationPolicyAccessory);
    NSLogger(@"Is current application canShowAlert: %@", isForeground ? @"YES" : @"NO");
    return isForeground;
}
#else
BOOL canShowAlert(void) {
    return NO;
}
#endif

/// Initialize behavior based on environment variables.
///
/// This function checks for specific environment variables to enable
/// optional runtime features and pass configuration values to components
/// such as URLSessionHook or AppInspector.
///
/// Supported environment variables:
///
/// - URLSESSION_HOOK_ENABLE:
///     If set to "1", enables URLSession hook by invoking
///     +[URLSessionHook record_NSURL:].
///
/// - NSURLSESSION_MAX_BODY_LEN:
///     Optional. Integer value to override the default max body length captured.
///
/// - NSURLSESSION_FILTER:
///     Optional. A string passed to +[URLSessionHook record_NSURL:] for filtering logic.
///
/// - APPINSPECTOR_ENABLE:
///     If set to "1", invokes +[AppInspector showInspector] at startup
///     to display the inspector window.
///
void initEnv(void){
    NSDictionary *env = [[NSProcessInfo processInfo] environment];

    // URLSessionHook
    NSString *enableHook = env[@"URLSESSION_HOOK_ENABLE"];
    if ([enableHook isEqualToString:@"1"]) {
        Class cls = NSClassFromString(@"URLSessionHook");

        NSString *maxBodyLenStr = env[@"NSURLSESSION_MAX_BODY_LEN"];
        if (maxBodyLenStr) {
            SEL sel = NSSelectorFromString(@"setMaxBodyLength:");
            if (cls && [cls respondsToSelector:sel]) {
                ((void (*)(id, SEL, NSUInteger))objc_msgSend)(cls, sel, maxBodyLenStr.integerValue);
            }
        }

        NSString *filterStr = env[@"NSURLSESSION_FILTER"];
        if (filterStr &&
            [[filterStr stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] length] == 0) {
            filterStr = nil;
        }
        SEL sel = NSSelectorFromString(@"record_NSURL:");
        if (cls && [cls respondsToSelector:sel]) {
            ((void (*)(id, SEL, id))objc_msgSend)(cls, sel, filterStr);
        }
    }

    // AppInspector
    NSString *enableInspector = env[@"APPINSPECTOR_ENABLE"];
    if ([enableInspector isEqualToString:@"1"]) {
        Class inspectorCls = NSClassFromString(@"AppInspector");
        SEL showSel = NSSelectorFromString(@"showInspector");
        if (inspectorCls && [inspectorCls respondsToSelector:showSel]) {
            ((void (*)(id, SEL))objc_msgSend)(inspectorCls, showSel);
        }
    }
}
+ (void)doHack {
    
    @try {
        
        initEnv();
        
        NSArray<Class> *hackClasses = [Constant getAllHackClasses];
        NSLogger(@"Initiating doHack operation...");
        for (Class class in hackClasses) {
            NSLogger(@"Processing class - %@", NSStringFromClass(class));
            id<HackProtocol> it = [[class alloc] init];
            if ([it shouldInject:_currentAppName]) {
                NSString *supportAppVersion = [it getSupportAppVersion];
                if (supportAppVersion==NULL ||
                    supportAppVersion.length==0 ||
                    _currentAppVersion==NULL  ||
                    (_currentAppVersion!=NULL && [_currentAppVersion hasPrefix:supportAppVersion]) ) {
                    if ([Constant isFirstOpen] && canShowAlert()) {
                        [it firstLaunch];
                    }
                    [it hack];
                    return;

                }else{
                    NSLogger(@"[ERROR] Unsupported current appVersion !! Suppert appVersion: [%@] Current appVersion: [%@]",
                          [it getSupportAppVersion], _currentAppVersion);
                }
            }
        }
        NSLogger(@"[ERROR] Unsupported current app: [%@]",_currentAppName);
    } @catch (NSException *exception) {
        NSLogger(@"[Caught exception]: %@", exception);
    }
}
@end
