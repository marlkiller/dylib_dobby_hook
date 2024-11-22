//
//  DownieHack.m
//  dylib_dobby_hook
//
//  Created by voidm on 2024/4/3.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "tinyhook.h"
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
    
    // double check
    if ([[Constant getCurrentAppName] containsString:@"com.bjango.istatmenus"]) {
        return false;
    }
    if ([[Constant getCurrentAppName] containsString:@"codes.rambo.AirBuddy"]) {
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
    NSLogger(@"called hook_trialDaysRemaining");
    return @9;
}

- (void) hook_viewDidLoad {
    NSLogger(@"called hook_viewDidLoad");
    [self valueForKey:@"window"];
    return ;
}
- (void) hook_windowDidLoad {
    NSLogger(@"called hook_windowDidLoad");
//    [0]    _TtC9Licensing27CMLicensingWindowController
    NSWindow *window = [self valueForKey:@"window"];
//    viewController    _TtC9Licensing25CMLicensingViewController
//    NSViewController *viewController = window.contentViewController;
    NSRect frame = NSMakeRect(0, 0, 0, 0);
    [window setFrame:frame display:YES];
    return ;
}

- (NSNumber *) hook_trialLength2 {
    NSLogger(@"called hook_trialLength2");
    return @9;
}


//- (BOOL) hook_isLicensed{
//    NSLogger(@"called hook_isLicensed");
//    return YES;
//}
//
//- (BOOL) hook_activated{
//    NSLogger(@"called hook_activated");
//    return YES;
//}


- (NSDate *) hook_activationDate{
    NSLogger(@"called hook_activationDate");
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
    NSLogger(@"called hook_licenseCode");
    static NSString *uuidString = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        uuidString = [[NSUUID UUID] UUIDString];
        NSLogger(@"UUID initialized: %@", uuidString);

    });
    return uuidString;
//    return @"B7EE3D3C-B7EE3D3C-B7EE3D3C-B7EE3D3C-B7EE3D3C";
}

- (NSString *) hook_activationEmail{
    NSLogger(@"called hook_activationEmail");
    return [Constant G_EMAIL_ADDRESS];
}


//- (id)hook_initWithProductID:(NSString *)productID andLicenseController:(id)licenseController {
//    NSLogger(@"called hook_initWithProductID");
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
        }else if([urlString containsString:@"/3.2/product/data"]) {
            // https://v3.paddleapi.com/3.2/product/data
            respBody =@{
                @"success": @YES,
                @"response": @{},
                @"signature": @""
            };
        } else {
            NSLogger(@"[hook_dataTaskWithRequest] Allow to pass url: %@",url);
            return ((id(*)(id, SEL,id,id))dataTaskWithRequestIMP)(self, _cmd,request,completionHandler);

        }
        NSLogger(@"[hook_dataTaskWithRequest] Intercept url: %@, request body: %@, response body: %@",url, reqBody,respBody);
        if (completionHandler) {
            wrapper(nil,respBody);
        }        
        return dummyTask;
;
    }
    NSLogger(@"[hook_dataTaskWithRequest] Allow to pass url: %@",url);
    return ((id(*)(id, SEL,id,id))dataTaskWithRequestIMP)(self, _cmd,request,completionHandler);
}

- (BOOL)hack {
        
    if ([[Constant getCurrentAppName] containsString:@"mindmac"]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:@"Basic" forKey:@"licenseType"];
        [defaults setObject:@YES forKey:@"licenseStatusChanged"];
        [defaults synchronize];
    }
//    license eg: B7EE3D3C-B7EE3D3C-B7EE3D3C-B7EE3D3C-B7EE3D3C
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
    
    return YES;
}
@end
