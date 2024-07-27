//
//  DownieHack.m
//  dylib_dobby_hook
//
//  Created by 马治武 on 2024/4/3.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "dobby.h"
#import "MemoryUtils.h"
#import <objc/runtime.h>
#include <mach-o/dyld.h>
#import <Cocoa/Cocoa.h>
#import "HackProtocolDefault.h"
#import "common_ret.h"

@interface PaddleBaseHack : HackProtocolDefault

@end

@implementation PaddleBaseHack

- (NSString *)getAppName {
    return @"com.charliemonroe.";
}

- (NSString *)getSupportAppVersion {
    // downie 4.7.8
    // permute 3.11.8
    return @"";
}
- (NSNumber *) hook_trialDaysRemaining {
    NSLog(@">>>>>> called hook_trialDaysRemaining");
    return @9;
}

- (void) hook_viewDidLoad {
    NSLog(@">>>>>> called hook_viewDidLoad");
    [self valueForKey:@"window"];
    return ;
}
- (void) hook_windowDidLoad {
    NSLog(@">>>>>> called hook_windowDidLoad");
//    [0]    _TtC9Licensing27CMLicensingWindowController
    NSWindow *window = [self valueForKey:@"window"];
//    viewController    _TtC9Licensing25CMLicensingViewController
//    NSViewController *viewController = window.contentViewController;
    NSRect frame = NSMakeRect(0, 0, 0, 0);
    [window setFrame:frame display:YES];
    return ;
}

- (NSNumber *) hook_trialLength2 {
    NSLog(@">>>>>> called hook_trialLength2");
    return @9;
}


//- (BOOL) hook_isLicensed{
//    NSLog(@">>>>>> called hook_isLicensed");
//    return YES;
//}
//
//- (BOOL) hook_activated{
//    NSLog(@">>>>>> called hook_activated");
//    return YES;
//}


- (NSDate *) hook_activationDate{
    NSLog(@">>>>>> called hook_activationDate");
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setYear:2099];
    [components setMonth:1]; // January
    [components setDay:1];
    [components setHour:0];
    [components setMinute:0];
    [components setSecond:0];
    NSDate *date = [calendar dateFromComponents:components];
    return date;
}
- (NSString *) hook_licenseCode{
    NSLog(@">>>>>> called hook_licenseCode");
    NSUUID *uuid = [NSUUID UUID];
    return [uuid UUIDString];
//    return @"B7EE3D3C-B7EE3D3C-B7EE3D3C-B7EE3D3C-B7EE3D3C";
}

- (NSString *) hook_activationEmail{
    NSLog(@">>>>>> called hook_activationEmail");
    return [Constant G_EMAIL_ADDRESS];
}

//- (void) hook_verifyActivationDetailsWithCompletion:(id) arg1{
//    NSLog(@">>>>>> called hook_verifyActivationDetailsWithCompletion");
//    return;
//}

- (BOOL)hack {
//    license eg: B7EE3D3C-B7EE3D3C-B7EE3D3C-B7EE3D3C-B7EE3D3C
    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        // 在这里执行你的代码
//        NSLog(@">>>>>>> 代码延迟执行了10秒");
//        // 获取当前应用程序的所有窗口
//        NSArray<NSWindow *> *allWindows = [NSApplication sharedApplication].windows;
//        
//        NSString *viewControllerClassName = @"Licensing.CMLicensingViewController";
//        Class viewControllerClass = NSClassFromString(viewControllerClassName);
//        
//        // 遍历所有窗口，查找目标窗口
//        for (NSWindow *window in allWindows) {
//            NSLog(@">>>>>> Window class name: %@", NSStringFromClass([window class]));
//            //            [window orderOut:nil]; // 隐藏窗口
//            NSViewController *viewController = window.contentViewController;
//            if (viewController != nil) {
//                // 窗口关联了一个视图控制器
//                NSLog(@"Window is associated with view controller: %@", viewController);
//                if ([viewController isKindOfClass:viewControllerClass]) {
//                    NSLog(@"Window is associated with view controller: %@", viewController);
//                    // 隐藏窗口
//                    // [window orderOut:nil];
//                    // 或者销毁窗口
//                    // [window close];
//                }
//            } else {
//                // 窗口没有关联视图控制器
//                NSLog(@"Window is not associated with any view controller");
//            }
//        }
//    });
    
    
//    boom 爆破
//    // -[_TtC9Licensing27CMLicensingWindowController windowDidLoad]:        // -[Licensing.CMLicensingWindowController windowDidLoad]
//    [MemoryUtils hookInstanceMethod:
//         objc_getClass("Licensing.CMLicensingWindowController")
//                   originalSelector:NSSelectorFromString(@"windowDidLoad")
//                      swizzledClass:[self class]
//                   swizzledSelector:NSSelectorFromString(@"hook_windowDidLoad")
//    ];
//    //  viewDidLoad
//    [MemoryUtils hookInstanceMethod:
//         objc_getClass("Licensing.CMLicensingViewController")
//                   originalSelector:NSSelectorFromString(@"viewDidLoad")
//                      swizzledClass:[self class]
//                   swizzledSelector:NSSelectorFromString(@"hook_viewDidLoad")
//    ];
//    
//    [MemoryUtils hookInstanceMethod:
//         objc_getClass("PADProduct")
//                   originalSelector:NSSelectorFromString(@"trialLength")
//                      swizzledClass:[self class]
//                   swizzledSelector:NSSelectorFromString(@"hook_trialLength2")
//     
//    ];
//    //    trialDaysRemaining
//    [MemoryUtils hookInstanceMethod:
//         objc_getClass("PADProduct")
//                   originalSelector:NSSelectorFromString(@"trialDaysRemaining")
//                      swizzledClass:[self class]
//                   swizzledSelector:NSSelectorFromString(@"hook_trialDaysRemaining")
//     
//    ];
    
    
    
    
//    license HOOK
//    -[PADProduct activated]:    
    [MemoryUtils hookInstanceMethod:
         objc_getClass("PADProduct")
                   originalSelector:NSSelectorFromString(@"activated")
                      swizzledClass:[self class]
                   swizzledSelector:@selector(ret1)

    ];
    
    [MemoryUtils hookInstanceMethod:
         objc_getClass("PADProduct")
                   originalSelector:NSSelectorFromString(@"activationDate")
                      swizzledClass:[self class]
                   swizzledSelector:NSSelectorFromString(@"hook_activationDate")

    ];
    [MemoryUtils hookInstanceMethod:
         objc_getClass("PADProduct")
                   originalSelector:NSSelectorFromString(@"licenseCode")
                      swizzledClass:[self class]
                   swizzledSelector:NSSelectorFromString(@"hook_licenseCode")

    ];
    [MemoryUtils hookInstanceMethod:
         objc_getClass("PADProduct")
                   originalSelector:NSSelectorFromString(@"activationEmail")
                      swizzledClass:[self class]
                   swizzledSelector:NSSelectorFromString(@"hook_activationEmail")

    ];
    [MemoryUtils hookInstanceMethod:
         objc_getClass("PADProduct")
                   originalSelector:NSSelectorFromString(@"verifyActivationDetailsWithCompletion:")
                      swizzledClass:[self class]
                   swizzledSelector:@selector(ret)

    ];
    
//            // Licensing.CMLicensing.numberOfTrialDays.getter
//            // 反射创建类实例
//            Class Dcls=NSClassFromString(@"Licensing.CMLicensingViewController");
//            id dobj=[[Dcls alloc] init];
//        
//            // 反射创建无类实例(也叫类对象)
//            Class currentClass=objc_getMetaClass("Licensing.CMLicensingViewController");
//            // id dclsobj=[[currentClass alloc] init];
//        
//            // 获取类的方法列表
//            unsigned int classMethodCount;
//            Method *classMethods = class_copyMethodList(currentClass, &classMethodCount);
//            NSLog(@"Class Methods:");
//            for (unsigned int i = 0; i < classMethodCount; i++) {
//                SEL selector = method_getName(classMethods[i]);
//                NSLog(@"- %@", NSStringFromSelector(selector));
//            }
//            free(classMethods);
//        
//            // 获取类的属性列表
//            unsigned int classPropertyCount;
//            objc_property_t *classProperties = class_copyPropertyList(currentClass, &classPropertyCount);
//            NSLog(@"Class Properties:");
//            for (unsigned int i = 0; i < classPropertyCount; i++) {
//                const char *propertyName = property_getName(classProperties[i]);
//                NSLog(@"- %s", propertyName);
//            }
//            free(classProperties);
//        
//            // 获取实例的方法列表
//            unsigned int instanceMethodCount;
//            Method *instanceMethods = class_copyMethodList(Dcls, &instanceMethodCount);
//            NSLog(@"Instance Methods:");
//            for (unsigned int i = 0; i < instanceMethodCount; i++) {
//                SEL selector = method_getName(instanceMethods[i]);
//                NSLog(@"- %@", NSStringFromSelector(selector));
//            }
//            free(instanceMethods);
//        
//            // 获取实例的属性列表
//            unsigned int instancePropertyCount;
//            objc_property_t *instanceProperties = class_copyPropertyList(Dcls, &instancePropertyCount);
//            NSLog(@"Instance Properties:");
//            for (unsigned int i = 0; i < instancePropertyCount; i++) {
//                const char *propertyName = property_getName(instanceProperties[i]);
//                NSLog(@"- %s", propertyName);
//            }
//            free(instanceProperties);
    return YES;
}
@end
