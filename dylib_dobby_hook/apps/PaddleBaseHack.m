//
//  DownieHack.m
//  dylib_dobby_hook
//
//  Created by voidm on 2024/4/3.
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
#import "URLSessionHook.h"
#import "EncryptionUtils.h"



@interface PaddleBaseHack : HackProtocolDefault

@end

@implementation PaddleBaseHack

IMP initWithProductIDIMP;
IMP dataTaskWithRequestIMP;

- (BOOL)shouldInject:(NSString *)target {
    
//    Movist Pro
//    Downie 4
//    Fork
//    BetterMouse
//    Permute 3
    
    
    if ([[Constant getCurrentAppName] containsString:@"com.bjango.istatmenus"]) {
        // double check
        return false;
    }
    
    int paddleIndex = [MemoryUtils indexForImageWithName:@"Paddle"];
    if (paddleIndex > 0) {
        return true;
    }
    return false;
}

//- (NSString *)getAppName {
//    return @"com.charliemonroe.";
//}
//

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
    static NSString *uuidString = nil;
    if (!uuidString) {
        NSUUID *uuid = [NSUUID UUID];
        uuidString = [uuid UUIDString];
        NSLog(@">>>>>> UUID initialized: %@", uuidString);
    }
    return uuidString.copy;
//    return @"B7EE3D3C-B7EE3D3C-B7EE3D3C-B7EE3D3C-B7EE3D3C";
}

- (NSString *) hook_activationEmail{
    NSLog(@">>>>>> called hook_activationEmail");
    return [Constant G_EMAIL_ADDRESS];
}


//- (id)hook_initWithProductID:(NSString *)productID andLicenseController:(id)licenseController {
//    NSLog(@">>>>>> called hook_initWithProductID");
//    id ret =  ((id(*)(id, SEL, id,id))initWithProductIDIMP)(self, _cmd, productID,licenseController);
//    return ret;
//}

- (id) hook_dataTaskWithRequest:(NSMutableURLRequest*)request completionHandler:(NSCompletionHandler)completionHandler{
    
    NSURL *url = [request URL];
    NSString *urlString = [url absoluteString];
    if ([urlString containsString:@"v3.paddleapi.com"] && completionHandler) {
        URLSessionHook *dummyTask = [[URLSessionHook alloc] init];
        // 在 Objective-C 中，completionHandler 是一种常见的异步编程模式，它通常用于在一个操作完成后执行一些额外的代码或处理结果。
        __auto_type wrapper = ^(NSError *error, NSDictionary *data) {
            __auto_type resp = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:200 HTTPVersion:@"1.1" headerFields:@{}];
            NSData *body = [NSJSONSerialization dataWithJSONObject:data options:0 error: &error];
            completionHandler(body, resp,error);
        };
        NSDictionary *respBody;
        NSString *reqBody = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding];
        NSString *productId = [EncryptionUtils  getTextBetween:@"product_id=" and:@"&" inString:reqBody];
        
        if ([urlString containsString:@"/3.2/license/activate"]) {
            respBody = @{
                @"success": @YES,
                @"response": @{
                        @"activation_id": [Constant G_EMAIL_ADDRESS],
                        @"allowed_uses": @"10",
                        @"expires": @NO,
                        @"expiry_date": @"2500-12-30",
                        @"product_id": productId,
                        @"times_used": @"1",
                        @"type": @"activation_license",
                        @"user_id": @""
                },
                @"signature": @""
            };
        } else if([urlString containsString:@"/3.2/license/deactivate"]) {
            respBody =@{
                @"success": @YES,
                @"response": @{},
                @"signature": @""
            };
        } else {
            NSLog(@">>>>>> [hook_dataTaskWithRequest] Allow to pass url: %@",url);
            return ((id(*)(id, SEL,id,id))dataTaskWithRequestIMP)(self, _cmd,request,completionHandler);

        }
        NSLog(@">>>>>> [hook_dataTaskWithRequest] Intercept url: %@, request body: %@, response body: %@",url, reqBody,respBody);
        if (completionHandler) {
            wrapper(nil,respBody);
        }        
        return dummyTask;
;
    }
    NSLog(@">>>>>> [hook_dataTaskWithRequest] Allow to pass url: %@",url);
    return ((id(*)(id, SEL,id,id))dataTaskWithRequestIMP)(self, _cmd,request,completionHandler);
}

- (BOOL)hack {
    
    if ([[Constant getCurrentAppName] containsString:@"codes.rambo.AirBuddy"]) {
        NSUserDefaults *defaults  = [NSUserDefaults standardUserDefaults];
            [defaults setBool:true forKey:@"AMSkipOnboarding"];
            [defaults synchronize];
    }
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
    
//    license HOOK
//    -[PADProduct activated]:    
    [MemoryUtils replaceInstanceMethod:
         objc_getClass("PADProduct")
                   originalSelector:NSSelectorFromString(@"activated")
                      swizzledClass:[self class]
                   swizzledSelector:@selector(ret1)

    ];
    
    // -[PADProduct initWithProductID:andLicenseController:]
//    initWithProductIDIMP = [MemoryUtils replaceInstanceMethod:
//         objc_getClass("PADProduct")
//                   originalSelector:NSSelectorFromString(@"initWithProductID:andLicenseController:")
//                      swizzledClass:[self class]
//                      swizzledSelector:@selector(hook_initWithProductID:andLicenseController:)
//
//    ];
//        
   
    // shouldTrackTrialStartDate
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
    
    dataTaskWithRequestIMP = [MemoryUtils hookInstanceMethod:
                                  NSClassFromString(@"NSURLSession")
                   originalSelector:NSSelectorFromString(@"dataTaskWithRequest:completionHandler:")
                      swizzledClass:[self class]
                   swizzledSelector:NSSelectorFromString(@"hook_dataTaskWithRequest:completionHandler:")
    ];
    
    if ([[Constant getCurrentAppName] containsString:@"mindmac"]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:@"Basic" forKey:@"licenseType"];
        [defaults setObject:@YES forKey:@"licenseStatusChanged"];
        [defaults synchronize];
    }
    
    
    return YES;
}
@end
