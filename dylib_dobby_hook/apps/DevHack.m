//
//  DevHack.m
//  dylib_dobby_hook
//
//  Created by voidm on 2024/4/4.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "tinyhook.h"
#import "MemoryUtils.h"
#import <objc/runtime.h>
#include <mach-o/dyld.h>
#import "HackProtocolDefault.h"
#include <sys/ptrace.h>
#import <AppKit/AppKit.h>
#import "common_ret.h"
#import <Cocoa/Cocoa.h>



@interface MyWindow : NSWindow
@end
@implementation MyWindow
- (instancetype)initWithContentRect:(NSRect)contentRect styleMask:(NSWindowStyleMask)styleMask backing:(NSBackingStoreType)backingStoreType defer:(BOOL)flag {
    // 指定窗口大小
    contentRect = NSMakeRect(0, 0, 800, 600);
    // 窗口标题栏
    styleMask |= NSWindowStyleMaskTitled;
    self = [super initWithContentRect:contentRect styleMask:styleMask backing:backingStoreType defer:flag];
    if (self) {
        // 设置窗口为透明
        self.backgroundColor = [NSColor clearColor];
        self.opaque = NO;
        // 设置鼠标穿透
        self.ignoresMouseEvents = NO;
        // 设置窗口级别为最高级别
        self.level = NSStatusWindowLevel;
    }
    return self;
}
- (BOOL)canBecomeKeyWindow {
    return NO;
}

@end

@interface MyView : NSView
@property (nonatomic, assign) NSPoint pointA;
@property (nonatomic, assign) NSPoint pointB;
@property (nonatomic, assign) BOOL isLine;
@end
@implementation MyView
- (void)drawRect:(NSRect)dirtyRect {
    NSBezierPath *path = [NSBezierPath bezierPath];
    if (self.isLine) {
        // 绘制线条
        [path moveToPoint:self.pointA];
        [path lineToPoint:self.pointB];
    } else {
        // 绘制矩形
        NSRect rect = NSMakeRect(self.pointA.x, self.pointA.y, self.pointB.x - self.pointA.x, self.pointB.y - self.pointA.y);
        [path appendBezierPathWithRect:rect];
    }
    // 设置绘制的颜色
    [[NSColor redColor] setStroke];
    // 设置线条的宽度
    [path setLineWidth:2.0];
    // 绘制路径
    [path stroke];
}
@end


@interface DevHack : HackProtocolDefault

//+ (NSWindow *)myWindow;
@end

@implementation DevHack

static NSWindow *myWindow = nil;

+ (void)load {
    
}

- (NSString *)getAppName {
    // >>>>>> AppName is [com.voidm.mac-app-dev-swift],Version is [1.0], myAppCFBundleVersion is [1].
    // >>>>>> AppName is [com.morecats.Minesweeper],Version is [2.1.2], myAppCFBundleVersion is [9].
    return @"com.voidm.mac-app-dev-swift";
}

- (NSString *)getSupportAppVersion {
    return @"";
}


// 菜单点击事件
+ (void)mem_event:(id)sender {
    NSLogger(@">>>>> mem_event");
    // [[Minesweeper+815D8] + 40]
    // mov        rbx, qword [qword_1000815d0]
    // mov        qword [rbx+0x40], rcx
    
    // 读写内存
    uintptr_t *ptr = (void *)0x1000815d0; // 读取基址的内容,转为指针
    void * addressPtr = (void *) *ptr;
    [MemoryUtils readIntAtAddress:(addressPtr+0x40)];
    [MemoryUtils writeInt:(int)1 toAddress:(addressPtr+0x40)];
    
    // 读写内存
//    uintptr_t *ret2 = (uintptr_t *)(addressPtr + 0x40);
//    uintptr_t value = *ret2;
//    NSLogger(@"byteValue :%lu",value);
//    *ret2 = 1;
//    value = *ret2;
//    NSLogger(@"byteValue :%lu",value);
    
    NSLogger(@"mem_event over");

}

+ (void)draw_event:(id)sender {
    NSLogger(@">>>>> draw_event");
      
    // 创建一个 NSApplication 实例
    if (myWindow==nil) {
        NSApplication *application = [NSApplication sharedApplication];
        // 创建一个 NSWindow 实例
        NSRect windowRect = NSMakeRect(0, 0, NSScreen.mainScreen.frame.size.width, NSScreen.mainScreen.frame.size.height);
        myWindow = [[MyWindow alloc] initWithContentRect:windowRect styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:NO];
        // 创建一个 MyView 实例，并将其添加到窗口中
        MyView *line = [[MyView alloc] initWithFrame:myWindow.contentView.bounds];
        // 设置绘制参数
        line.pointA = NSMakePoint(50, 50);
        line.pointB = NSMakePoint(200, 200);
        line.isLine = YES;
        [myWindow.contentView addSubview:line];
        // 创建一个 MyView 实例，并将其添加到窗口中
        MyView *rect = [[MyView alloc] initWithFrame:myWindow.contentView.bounds];
        // 设置绘制参数
        rect.pointA = NSMakePoint(300, 300);
        rect.pointB = NSMakePoint(400, 500);
        rect.isLine = NO;
        [myWindow.contentView addSubview:rect];
        // 显示窗口
        [myWindow makeKeyAndOrderFront:nil];
        
        // TODO 这里 MACOS 似乎没办法 HOOK 窗口的循环消息, 动态绘制矩形后面看看能否借助 IMGUI 来实现
        
        // 运行主事件循环
        [application run];
    }else {
        if ([myWindow isVisible]) {
           [myWindow orderOut:nil];
        } else {
           [myWindow makeKeyAndOrderFront:nil];
           // [NSApp activateIgnoringOtherApps:YES];
        }
    }
    NSLogger(@"draw_event over");
}

- (BOOL)hack {
    
//    手动定时监测菜单
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        while (true) {
//            // 每 5 秒执行一次
//            sleep(5);
//            NSLogger(@"allWindows");
//            // 在主线程上异步执行窗口信息获取和日志记录
//            dispatch_async(dispatch_get_main_queue(), ^{
//                NSArray<NSWindow *> *allWindows = [NSApplication sharedApplication].windows;
//                // 遍历所有窗口，打印窗口信息
//                for (NSWindow *window in allWindows) {
//                    NSViewController *viewController = window.contentViewController;
//                    NSLogger(@"窗口类名: %@, 关联视图控制器: %@", NSStringFromClass([window class]), viewController ? viewController : @"无");
//                }
//            });
//        }
//    });
    
//    -[_TtC13App_Cleaner_822BaseFeaturesController onAppDidFinishLaunching]:
    
    

    
    
//    添加菜单
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        // 在这里执行你的代码
//        NSLogger(@"代码延迟执行了 1 秒");
//        NSLogger(@"添加自定义菜单");
//        
//        NSMenu *mainMenu = [NSApplication sharedApplication].mainMenu;
//        // 创建一个与独立的菜单项
//        NSMenuItem *newMenuItem = [[NSMenuItem alloc] initWithTitle:@"menu_new" action:nil keyEquivalent:@""];
//        NSMenuItem *subMenuItem1 = [[NSMenuItem alloc] initWithTitle:@"mem_event" action:NSSelectorFromString(@"mem_event:") keyEquivalent:@""];
//        [subMenuItem1 setTarget:self.class];
//        NSMenuItem *subMenuItem2 = [[NSMenuItem alloc] initWithTitle:@"draw_event" action:@selector(draw_event:) keyEquivalent:@""];
//        [subMenuItem2 setTarget:DevHack.class];
//        // 创建一个子菜单并将子菜单项添加进去
//        NSMenu *newMenu = [[NSMenu alloc] initWithTitle:@"New Menu [HOOK]"];
//        [newMenu addItem:subMenuItem1];
//        [newMenu addItem:subMenuItem2];
//        // 将子菜单添加到父菜单项
//        [newMenuItem setSubmenu:newMenu];
//        [mainMenu addItem:newMenuItem];
//    });
    
    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        // 在这里执行你的代码
//        NSLogger(@">>>>>>> 代码延迟执行了10秒");
//        // 获取当前应用程序的所有窗口
//        NSArray<NSWindow *> *allWindows = [NSApplication sharedApplication].windows;
//
//        NSString *viewControllerClassName = @"Licensing.CMLicensingViewController";
//        Class viewControllerClass = NSClassFromString(viewControllerClassName);
//
//        // 遍历所有窗口，查找目标窗口
//        for (NSWindow *window in allWindows) {
//            NSLogger(@"Window class name: %@", NSStringFromClass([window class]));
//            //            [window orderOut:nil]; // 隐藏窗口
//            NSViewController *viewController = window.contentViewController;
//            if (viewController != nil) {
//                // 窗口关联了一个视图控制器
//                NSLogger(@"Window is associated with view controller: %@", viewController);
//                if ([viewController isKindOfClass:viewControllerClass]) {
//                    NSLogger(@"Window is associated with view controller: %@", viewController);
//                    // 隐藏窗口
//                    // [window orderOut:nil];
//                    // 或者销毁窗口
//                    // [window close];
//                }
//            } else {
//                // 窗口没有关联视图控制器
//                NSLogger(@"Window is not associated with any view controller");
//            }
//        }
//    });
//    Class WinControllerClass = NSClassFromString(@"mac_app_dev_swift.ViewController");
//    SEL viewDidLoadSeletor = NSSelectorFromString(@"viewDidLoad");
//    Method originalMethod = class_getInstanceMethod(WinControllerClass, viewDidLoadSeletor);
//    // 获取 viewDidLoad 方法的函数地址
//    originalMethodIMP = method_getImplementation(originalMethod);
//    methodPointer = (MethodPointer)originalMethodIMP;
//    
//    [MemoryUtils hookInstanceMethod:
//         objc_getClass("mac_app_dev_swift.ViewController")
//                   originalSelector:NSSelectorFromString(@"viewDidLoad")
//                      swizzledClass:[self class]
//                   swizzledSelector:NSSelectorFromString(@"hk_viewDidLoad")
//    ];
    
        
////    tiny_hook((void *)viewDidLoadImp, (void *)my_viewDidLoad, (void *)&viewDidLoadImp_ori);
//    
//    
//    
//    NSString *searchFilePath = [[Constant getCurrentAppPath] stringByAppendingString:@"/Contents/MacOS/mac_app_dev_swift"];
//    uintptr_t fileOffset =[MemoryUtils getCurrentArchFileOffset: searchFilePath];
//    int imageIndex = [MemoryUtils indexForImageWithName:@"mac_app_dev_swift"];
//    
//    // printHello()
//    NSString *printHelloCode = @"55 48 89 E5 48 8D 3D ?? ?? ?? ?? B0 00 E8 4C 2B 00 00 5D C3";
//    uintptr_t globalOffset = [[MemoryUtils searchMachineCodeOffsets:(NSString *)searchFilePath machineCode:(NSString *)printHelloCode count:(int)1][0] unsignedIntegerValue];
//    intptr_t _printHelloPt = [MemoryUtils getPtrFromGlobalOffset:imageIndex targetFunctionOffset:(uintptr_t)globalOffset reduceOffset:(uintptr_t)fileOffset];
//    NSLogger(@"_printHelloPt %ld",_printHelloPt);
//    // 将函数地址转换为函数指针类型
//    CPrintHelloPointer printHelloFun = (CPrintHelloPointer)_printHelloPt;
//      // 调用函数
//    printHelloFun();
//    
//    
//    // int printOne()
//    NSString *intRetOneCode = @"55 48 89 E5 48 8D 3D ?? ?? ?? ?? B0 00 E8 2C 2B 00 00 B8 01 00 00 00 5D C3";
//    globalOffset = [[MemoryUtils searchMachineCodeOffsets:(NSString *)searchFilePath machineCode:(NSString *)intRetOneCode count:(int)1][0] unsignedIntegerValue];
//    intptr_t _intRetOneCodePt = [MemoryUtils getPtrFromGlobalOffset:imageIndex targetFunctionOffset:(uintptr_t)globalOffset reduceOffset:(uintptr_t)fileOffset];
//    NSLogger(@"_intRetOneCodePt %ld",_intRetOneCodePt);
//    // 将函数地址转换为函数指针类型
//    CRetOnePointer retOneFun = (CRetOnePointer)_intRetOneCodePt;
//      // 调用函数
//    int ret = retOneFun();
//    NSLogger(@"retOneFun ret %d",ret);
//    
//    // int addMethod(int, int)
//    NSString *intAddMethodCode = @"55 48 89 E5 48 83 EC 10 89 7D FC 89 75 F8 48 8D 3D ?? ?? ?? ?? B0 00 E8 02 2B 00 00 8B 45 FC 03 45 F8 48 83 C4 10 5D C3";
//    globalOffset = [[MemoryUtils searchMachineCodeOffsets:(NSString *)searchFilePath machineCode:(NSString *)intAddMethodCode count:(int)1][0] unsignedIntegerValue];
//    intptr_t _intAddMethodCodePt = [MemoryUtils getPtrFromGlobalOffset:imageIndex targetFunctionOffset:(uintptr_t)globalOffset reduceOffset:(uintptr_t)fileOffset];
//    NSLogger(@"_intAddMethodCodePt %ld",_intAddMethodCodePt);
//    // 将函数地址转换为函数指针类型
//    CRetAddMethodPointer retAddMethod = (CRetAddMethodPointer)_intAddMethodCodePt;
//    // 调用函数
//    int ret2 = retAddMethod(1,2);
//    NSLogger(@"retAddMethod ret %d",ret2);
//    
//    // 使用 void * 类型作为通用指针
//    // void *functionAddress = (void *)_intAddMethodCodePt;
//    // int result = ((int (*)(int, int))functionAddress)(10, 20);
////    ret1();

    return YES;
}
typedef void (*CPrintHelloPointer)(void);
typedef int (*CRetOnePointer)(void);
typedef int (*CRetAddMethodPointer)(int a,int b);



typedef void (*MethodPointer)(id, SEL);
MethodPointer methodPointer = NULL;
IMP originalMethodIMP = nil;
// 通过 swizzled 来 hook viewDidLoad
- (void)hk_viewDidLoad {
    // NSString *ret = ((NSString *(*)(id, SEL))KD_MD5IMP)(self, @selector(KD_MD5));
    NSLogger(@"my_viewDidLoad is called with self: %@ and selector: %@", self, NSStringFromSelector(_cmd));
    ((void *(*)(id, SEL))originalMethodIMP)(self, _cmd);
    // methodPointer(self,_cmd);
}


// 通过 tiny_hook 来 hook viewDidLoad
int (*viewDidLoadImp_ori)(void);
void my_viewDidLoad(id self, SEL _cmd) {
    // self：指向当前对象实例的指针。在实例方法中，self 指向调用该方法的对象实例。在类方法中，self 指向类本身。
    // _cmd：当前方法的选择器，即方法名。_cmd 在编译时会被转换成一个 SEL 类型的参数
    // int (*hook_device_id_ori)(uint64_t arg0, uint64_t arg1, uint64_t arg2, uint64_t arg3, uint64_t arg4);
    // return hook_device_id_ori(arg0,arg1,arg2,arg3,arg4);

    NSLogger(@"viewDidAppear is hooked!");
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
//            // 获取返回值
//            NSString *returnValue;
//            [invocation getReturnValue:&returnValue];
//
//id (*sharedInstanceMethod)(id, SEL) = (id (*)(id, SEL))objc_msgSend;
//id ret = sharedInstanceMethod(AppDelegateClz, selector);
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

// FUCK 指针 START
void fuckPoint(void){
        
    // 一级指针:
    // 0x123: 1
//    intptr_t *a = (void *)0x123;
//    int aValue = (int)*a;
    
    // 获取变量的指针
//    intptr_t* addressOfA =(void *) &aValue;
    
    // 二级指针:
    // 0x123: 0x456
    // 0x456: 2
//    intptr_t* a2 = (void *)0x123;
//    intptr_t* b2 = (void *)*a2;
//    int value = (int)*b2;

}
// FUCK 指针 END

@end
