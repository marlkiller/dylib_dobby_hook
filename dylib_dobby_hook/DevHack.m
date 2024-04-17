//
//  DevHack.m
//  dylib_dobby_hook
//
//  Created by 马治武 on 2024/4/4.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "dobby.h"
#import "MemoryUtils.h"
#import <objc/runtime.h>
#include <mach-o/dyld.h>
#import "HackProtocol.h"
#include <sys/ptrace.h>
#import <AppKit/AppKit.h>
#import "common_ret.h"



@interface DevHack : NSObject <HackProtocol>

@end

@implementation DevHack


+ (void)load {
    
}


- (NSString *)getAppName {
    // >>>>>> AppName is [com.voidm.mac-app-dev-swift],Version is [1.0], myAppCFBundleVersion is [1].
    return @"com.voidm.mac-app-dev-";
}

- (NSString *)getSupportAppVersion {
    return @"";
}


// 菜单点击事件
+ (void)clickEvent2:(id)sender {
    NSLog(@">>>>> clickEvent");
    exit(0);
}

- (BOOL)hack {
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 在这里执行你的代码
        NSLog(@">>>>>> 代码延迟执行了 5 秒");
        NSLog(@">>>>>> 添加自定义菜单");
        
        NSMenu *mainMenu = [NSApplication sharedApplication].mainMenu;
        // 创建一个与独立的菜单项
        NSMenuItem *newMenuItem = [[NSMenuItem alloc] initWithTitle:@"menu_new" action:nil keyEquivalent:@""];
        NSMenuItem *subMenuItem1 = [[NSMenuItem alloc] initWithTitle:@"menu_new_1" action:NSSelectorFromString(@"clickEvent2:") keyEquivalent:@""];
        [subMenuItem1 setTarget:self.class];
        NSMenuItem *subMenuItem2 = [[NSMenuItem alloc] initWithTitle:@"menu_new_2" action:@selector(clickEvent2:) keyEquivalent:@""];
        [subMenuItem2 setTarget:DevHack.class];
        // 创建一个子菜单并将子菜单项添加进去
        NSMenu *newMenu = [[NSMenu alloc] initWithTitle:@"New Menu [HOOK]"];
        [newMenu addItem:subMenuItem1];
        [newMenu addItem:subMenuItem2];
        // 将子菜单添加到父菜单项
        [newMenuItem setSubmenu:newMenu];
        [mainMenu addItem:newMenuItem];
    });
    
        
    Class WinControllerClass = NSClassFromString(@"mac_app_dev_swift.ViewController");
    SEL viewDidLoadSeletor = NSSelectorFromString(@"viewDidLoad");
    Method originalMethod = class_getInstanceMethod(WinControllerClass, viewDidLoadSeletor);
    // 获取 viewDidLoad 方法的函数地址
    IMP originalMethodIMP = method_getImplementation(originalMethod);
    methodPointer = (MethodPointer)originalMethodIMP;
    
//    [MemoryUtils hookInstanceMethod:
//         objc_getClass("mac_app_dev_swift.ViewController")
//                   originalSelector:NSSelectorFromString(@"viewDidLoad")
//                      swizzledClass:[self class]
//                   swizzledSelector:NSSelectorFromString(@"hk_viewDidLoad")
//    ];
    
        
//    DobbyHook((void *)viewDidLoadImp, (void *)my_viewDidLoad, (void *)&viewDidLoadImp_ori);
    
    
    
    NSString *searchFilePath = [[Constant getCurrentAppPath] stringByAppendingString:@"/Contents/MacOS/mac_app_dev_swift"];
    uintptr_t fileOffset =[MemoryUtils getCurrentArchFileOffset: searchFilePath];
    int imageIndex = [MemoryUtils indexForImageWithName:@"mac_app_dev_swift"];
    
    // printHello()
    NSString *printHelloCode = @"55 48 89 E5 48 8D 3D ?? ?? ?? ?? B0 00 E8 4C 2B 00 00 5D C3";
    uintptr_t globalOffset = [[MemoryUtils searchMachineCodeOffsets:(NSString *)searchFilePath machineCode:(NSString *)printHelloCode count:(int)1][0] unsignedIntegerValue];
    intptr_t _printHelloPt = [MemoryUtils getPtrFromGlobalOffset:imageIndex targetFunctionOffset:(uintptr_t)globalOffset reduceOffset:(uintptr_t)fileOffset];
    NSLog(@">>>>>> _printHelloPt %ld",_printHelloPt);
    // 将函数地址转换为函数指针类型
    CPrintHelloPointer printHelloFun = (CPrintHelloPointer)_printHelloPt;
      // 调用函数
    printHelloFun();
    
    
    // int printOne()
    NSString *intRetOneCode = @"55 48 89 E5 48 8D 3D ?? ?? ?? ?? B0 00 E8 2C 2B 00 00 B8 01 00 00 00 5D C3";
    globalOffset = [[MemoryUtils searchMachineCodeOffsets:(NSString *)searchFilePath machineCode:(NSString *)intRetOneCode count:(int)1][0] unsignedIntegerValue];
    intptr_t _intRetOneCodePt = [MemoryUtils getPtrFromGlobalOffset:imageIndex targetFunctionOffset:(uintptr_t)globalOffset reduceOffset:(uintptr_t)fileOffset];
    NSLog(@">>>>>> _intRetOneCodePt %ld",_intRetOneCodePt);
    // 将函数地址转换为函数指针类型
    CRetOnePointer retOneFun = (CRetOnePointer)_intRetOneCodePt;
      // 调用函数
    int ret = retOneFun();
    NSLog(@">>>>>> retOneFun ret %d",ret);
    
    // int addMethod(int, int)
    NSString *intAddMethodCode = @"55 48 89 E5 48 83 EC 10 89 7D FC 89 75 F8 48 8D 3D ?? ?? ?? ?? B0 00 E8 02 2B 00 00 8B 45 FC 03 45 F8 48 83 C4 10 5D C3";
    globalOffset = [[MemoryUtils searchMachineCodeOffsets:(NSString *)searchFilePath machineCode:(NSString *)intAddMethodCode count:(int)1][0] unsignedIntegerValue];
    intptr_t _intAddMethodCodePt = [MemoryUtils getPtrFromGlobalOffset:imageIndex targetFunctionOffset:(uintptr_t)globalOffset reduceOffset:(uintptr_t)fileOffset];
    NSLog(@">>>>>> _intAddMethodCodePt %ld",_intAddMethodCodePt);
    // 将函数地址转换为函数指针类型
    CRetAddMethodPointer retAddMethod = (CRetAddMethodPointer)_intAddMethodCodePt;
    // 调用函数
    int ret2 = retAddMethod(1,2);
    NSLog(@">>>>>> retAddMethod ret %d",ret2);
    
    // 使用 void * 类型作为通用指针
    // void *functionAddress = (void *)_intAddMethodCodePt;
    // int result = ((int (*)(int, int))functionAddress)(10, 20);

    
//    ret1();

    return YES;
}
typedef void (*CPrintHelloPointer)(void);
typedef int (*CRetOnePointer)(void);
typedef int (*CRetAddMethodPointer)(int a,int b);



typedef void (*MethodPointer)(id, SEL);
MethodPointer methodPointer = NULL;

// 通过 swizzled 来 hook viewDidLoad
- (void)hk_viewDidLoad {
    //    在这里实现你的逻辑
    // Hook 前 获取 IMP KD_MD5IMPGlobal
    // IMP KD_MD5IMPGlobal = nil;
    // Class NSStringClz = NSClassFromString(@"NSString");
    // SEL KD_MD5Seleter = NSSelectorFromString(@"KD_MD5");
    // Method KD_MD5lMethod = class_getInstanceMethod(NSStringClz, KD_MD5Seleter);
    // IMP KD_MD5IMP = method_getImplementation(KD_MD5lMethod);
    // NSString *ret = ((NSString *(*)(id, SEL))KD_MD5IMP)(self, @selector(KD_MD5));
    NSLog(@">>>>>> my_viewDidLoad is called with self: %@ and selector: %@", self, NSStringFromSelector(_cmd));
    methodPointer(self,_cmd);
}


// 通过 DobbyHook 来 hook viewDidLoad
int (*viewDidLoadImp_ori)(void);
void my_viewDidLoad(id self, SEL _cmd) {
    // self：指向当前对象实例的指针。在实例方法中，self 指向调用该方法的对象实例。在类方法中，self 指向类本身。
    // _cmd：当前方法的选择器，即方法名。_cmd 在编译时会被转换成一个 SEL 类型的参数
    NSLog(@">>>>>> viewDidAppear is hooked!");
    ((void(*)(id, SEL))viewDidLoadImp_ori)(self, _cmd);
}


//// 调用类方法
//Class SGEEventCenterClass = NSClassFromString(@"SGEEventCenter");
//if (SGEEventCenterClass) {
//    SEL selector = NSSelectorFromString(@"raiseEvent:content:type:");
//    if ([SGEEventCenterClass respondsToSelector:selector]) {
//        NSMethodSignature *methodSignature = [SGEEventCenterClass methodSignatureForSelector:selector];
//        if (methodSignature) {
//            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
//            // 如果是调用实例方法,需要 set target 一个实例对象
//            // [invocation setTarget:[[SGEEventCenterClass alloc] init]];
//            [invocation setTarget:SGEEventCenterClass];
//            [invocation setSelector:selector];
//            NSString *param1 = @"5";
//            NSString *param2 = @"自定义消息5";
//            NSInteger param3 = 0;
//            [invocation setArgument:&param1 atIndex:2];
//            [invocation setArgument:&param2 atIndex:3];
//            [invocation setArgument:&param3 atIndex:4];
//            [invocation invoke];
//        }
//    }
//}

//// 调用类方法
////    Class cls = NSClassFromString(@"SGMEnterpriseSettings");
////    [cls setUserID:@"this is user id"];
//
//// 调用实例方法
//id ret = [[NSClassFromString(@"SGMEnterpriseSettings") alloc] init];
//// 函数有 多个参数
////    [ret performSelector:@selector(setUserID:andAnotherParam:)
////                   withObject:@"this is user id"
////                   withObject:@"this is another param"];
//// id ret = class_createInstance(objc_getClass("SGMEnterpriseSettings"), 0);
//[ret performSelector:NSSelectorFromString(@"setUserID:") withObject:@"this is user id"];
//[ret performSelector:NSSelectorFromString(@"setCompanyName:") withObject:@"this is cp name"];
//[ret performSelector:NSSelectorFromString(@"setCompanyID:") withObject:@"this is cp id"];
@end
