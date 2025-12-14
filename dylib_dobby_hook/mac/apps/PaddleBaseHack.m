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

//static IMP initWithProductIDIMP;
static IMP dataTaskWithRequestIMP;
static IMP _dataTaskWithRequestIMP;

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
    if ([[Constant getCurrentAppName] containsString:@"com.readdle.PDFExpert-Mac"]) {
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

static NSString* licenseCode = @"B7EE3D3C-B7EE3D3C-B7EE3D3C-B7EE3D3C-B7EE3D3C";
- (NSString *) hook_licenseCode{
    NSLogger(@"called hook_licenseCode");
//    static NSString *uuidString = nil;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        uuidString = [[NSUUID UUID] UUIDString];
//        NSLogger(@"UUID initialized: %@", uuidString);
//
//    });
//    return uuidString;
    return licenseCode;
}

- (NSString *) hook_activationEmail{
    NSLogger(@"called hook_activationEmail");
    return [Constant G_EMAIL_ADDRESS];
}

- (NSString *) hk_productName{
    NSLogger(@"called hk_productName");
    return @"Panamera GTS 4";
}

//- (id)hook_initWithProductID:(NSString *)productID andLicenseController:(id)licenseController {
//    NSLogger(@"called hook_initWithProductID");
//    id ret =  ((id(*)(id, SEL, id,id))initWithProductIDIMP)(self, _cmd, productID,licenseController);
//    return ret;
//}

- (id) hook_dataTaskWithRequest:(NSMutableURLRequest*)request completionHandler:(NSCompletionHandler)completionHandler{
    
    NSURL *url = [request URL];
    NSString *urlString = [url absoluteString];
    NSDictionary *respBody;
    NSString *reqBody = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding];
    if ([urlString containsString:@"v3.paddleapi.com"] && completionHandler) {
        URLSessionHook *dummyTask = [[URLSessionHook alloc] init];
        // 在 Objective-C 中，completionHandler 是一种常见的异步编程模式，它通常用于在一个操作完成后执行一些额外的代码或处理结果。
        __auto_type wrapper = ^(NSError *error, NSDictionary *data) {
            __auto_type resp = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:200 HTTPVersion:@"1.1" headerFields:@{}];
            NSData *body = [NSJSONSerialization dataWithJSONObject:data options:0 error: &error];
            completionHandler(body, resp,error);
        };
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
            respBody = @{
                @"success" : @YES,
                @"response" : @ {
                    @"product_id" : productId,
                    @"times_used" : @1,
                    @"type" : @"activation_license",
                    @"allowed_uses" : @999,
                    @"activation_id" : [Constant G_EMAIL_ADDRESS],
                    @"expiry_date" : @"2026-12-31",
                    @"expires" : @NO
                },
                @"signature" : @""
            };
        } else if ([urlString containsString:@"/3.2/license/activations"]) {
            respBody = @{
                @"success" : @YES,
                @"response" : @[
                    @{
                        @"activation_id" : [Constant G_EMAIL_ADDRESS],
                        @"uuid" : licenseCode,
                        @"activated" : @"2033-10-27 10:00:00"
                    }
                ],
                @"signature" : @""
            };
        } else if ([urlString containsString:@"/3.2/product/data"]) {
            respBody = @{
                @"success" : @YES,
                @"response": @{
                    @"product_id": productId,
                    @"product_name": @"Panamera GTS 4",
                    @"user": @{
                        @"user_id": @123456,
                        @"email": [Constant G_EMAIL_ADDRESS_FMT],
                        @"name":[Constant G_EMAIL_ADDRESS_FMT]
                    },
                    @"license": @{
                        @"license_code": licenseCode,
                        @"uses": @1,
                        @"allowed_uses": @5,
                        @"type" : @"activation_license",
                        @"generated_at": @"2023-10-27 10:00:00",
                        @"expires_at": @"2033-10-27 10:00:00",
                        @"is_subscription": @YES,
                        @"is_trial": @NO
                    }
                },
                @"signature" : @""
            };
        } else {
            NSLogger(@"[hook_dataTaskWithRequest] Allow to pass url: %@, reqBody = %@",url,reqBody);
            return ((id(*)(id, SEL,id,id))dataTaskWithRequestIMP)(self, _cmd,request,completionHandler);
        }
        NSLogger(@"[hook_dataTaskWithRequest] Intercept url: %@, request body: %@, response body: %@",url, reqBody,respBody);
        if (completionHandler) {
            wrapper(nil,respBody);
        }
        return dummyTask;
 
    }
    NSLogger(@"[hook_dataTaskWithRequest] Allow to pass url: %@, reqBody = %@",url,reqBody);
    return ((id(*)(id, SEL,id,id))dataTaskWithRequestIMP)(self, _cmd,request,completionHandler);
}




- (id)hook__dataTaskWithRequest:(NSURLRequest *)request
                       delegate:(id)delegate
             completionHandler:(NSCompletionHandler)completionHandler {
    NSURL *url = [request URL];
    NSString *urlString = [url absoluteString];
    if ([urlString containsString:@"licensing.charliemonroe.net"] && completionHandler) {
        URLSessionHook *dummyTask = [[URLSessionHook alloc] init];

        __auto_type wrapper = ^(NSError *error, NSDictionary *data) {
            __auto_type resp = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:200 HTTPVersion:@"1.1" headerFields:@{}];
            NSData *body = [NSJSONSerialization dataWithJSONObject:data options:0 error: &error];
            completionHandler(body, resp,error);
        };
        NSDictionary *respBody = @{};
        NSString *reqBody = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding];
        if ([urlString containsString:@"/activate"]) {
            NSString *productId = [EncryptionUtils  getTextBetween:@"product_id=" and:@"&" inString:reqBody];
            respBody = @{
                @"activation_id": [Constant G_EMAIL_ADDRESS],
                @"allowed_uses": @"10",
                @"expires": @NO,
                @"expiry_date": @"2500-12-30",
                @"license_data": @"D7BC2F5F-E9BC2E9E-B4DA2D3C-E7FF3E9F-D3FA6C7F",
                @"product_id": productId,
                @"times_used": @"1",
                @"type": @"activation_license",
                @"user_id": @""
        }   ;
        }
        NSLogger(@"Intercept url: %@, request body: %@, response body: %@",url, reqBody,respBody);
        wrapper(nil,respBody);
        return dummyTask;
        
    }
    NSLogger(@"Allow to pass request: %@", urlString);
    return ((id(*)(id, SEL,id,id,id))_dataTaskWithRequestIMP)(self, _cmd,request,delegate,completionHandler);

}


- (BOOL)hack {
    
    if ([[Constant getCurrentAppName] containsString:@"com.movist.MovistPro"]) {
//          TODO:         

    }
    
    if ([[Constant getCurrentAppName] containsString:@"com.charliemonroe"]) {
        // fake license
        NSFileManager *fileManager = [NSFileManager defaultManager];
        // 获取用户的主目录 (~)
        NSString *homeDirectory = NSHomeDirectory();
        NSString *appSupportPath = [homeDirectory stringByAppendingPathComponent:@"Library/Application Support"];
        NSString *targetPath = [appSupportPath stringByAppendingPathComponent:@"583749.cmlicense"];
        // 检查文件是否存在
        if (![fileManager fileExistsAtPath:targetPath]) {
            const char bytes[] = {
                0x62, 0x70, 0x6C, 0x69, 0x73, 0x74, 0x30, 0x30, 0xD4, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
                0x08, 0x55, 0x65, 0x6D, 0x61, 0x69, 0x6C, 0x57, 0x6C, 0x69, 0x63, 0x65, 0x6E, 0x73, 0x65, 0x5A,
                0x61, 0x63, 0x74, 0x69, 0x76, 0x61, 0x74, 0x69, 0x6F, 0x6E, 0x5E, 0x61, 0x63, 0x74, 0x69, 0x76,
                0x61, 0x74, 0x69, 0x6F, 0x6E, 0x44, 0x61, 0x74, 0x65, 0x5F, 0x10, 0x1D, 0x4B, 0x27, 0x65, 0x64,
                0x20, 0x62, 0x79, 0x3A, 0x20, 0x6D, 0x61, 0x72, 0x6C, 0x6B, 0x69, 0x6C, 0x6C, 0x65, 0x72, 0x40,
                0x76, 0x6F, 0x69, 0x64, 0x6D, 0x2E, 0x63, 0x6F, 0x6D, 0x5F, 0x10, 0x24, 0x35, 0x42, 0x42, 0x43,
                0x36, 0x30, 0x42, 0x41, 0x2D, 0x42, 0x39, 0x46, 0x30, 0x2D, 0x34, 0x31, 0x30, 0x33, 0x2D, 0x38,
                0x43, 0x41, 0x32, 0x2D, 0x32, 0x41, 0x44, 0x34, 0x45, 0x36, 0x39, 0x35, 0x35, 0x35, 0x35, 0x44,
                0x5F, 0x10, 0x2C, 0x44, 0x37, 0x42, 0x43, 0x32, 0x46, 0x35, 0x46, 0x2D, 0x45, 0x39, 0x42, 0x43,
                0x32, 0x45, 0x39, 0x45, 0x2D, 0x42, 0x34, 0x44, 0x41, 0x32, 0x44, 0x33, 0x43, 0x2D, 0x45, 0x37,
                0x46, 0x46, 0x33, 0x45, 0x39, 0x46, 0x2D, 0x44, 0x33, 0x46, 0x41, 0x36, 0x43, 0x37, 0x46, 0x33,
                0x41, 0xC6, 0xCF, 0xDA, 0xB0, 0x3B, 0x71, 0x5C, 0x08, 0x11, 0x17, 0x1F, 0x2A, 0x39, 0x59, 0x80,
                0xAF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                0x09, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                0xB8
            };
            NSError *writeError = nil;
            [[NSData dataWithBytes:bytes length:sizeof(bytes)] writeToFile:targetPath
                                                                   options:NSDataWritingAtomic
                                                                     error:&writeError];
        }
        _dataTaskWithRequestIMP = [MemoryUtils hookInstanceMethod:
                                       NSClassFromString(@"NSURLSession")
                                                 originalSelector:NSSelectorFromString(@"_dataTaskWithRequest:delegate:completionHandler:")
                                                    swizzledClass:[self class]
                                                 swizzledSelector:NSSelectorFromString(@"hook__dataTaskWithRequest:delegate:completionHandler:")
        ];
    }
    
    if ([[Constant getCurrentAppName] containsString:@"com.charliemonroe.Permute-3"]) {
        // fake license
        NSFileManager *fileManager = [NSFileManager defaultManager];
        // 获取用户的主目录 (~)
        NSString *homeDirectory = NSHomeDirectory();
        NSString *appSupportPath = [homeDirectory stringByAppendingPathComponent:@"Library/Application Support"];
        NSString *targetPath = [appSupportPath stringByAppendingPathComponent:@"583749.cmlicense"];
        // 检查文件是否存在
        if (![fileManager fileExistsAtPath:targetPath]) {
            const char bytes[] = {
                0x62, 0x70, 0x6C, 0x69, 0x73, 0x74, 0x30, 0x30, 0xD4, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
                0x08, 0x55, 0x65, 0x6D, 0x61, 0x69, 0x6C, 0x57, 0x6C, 0x69, 0x63, 0x65, 0x6E, 0x73, 0x65, 0x5A,
                0x61, 0x63, 0x74, 0x69, 0x76, 0x61, 0x74, 0x69, 0x6F, 0x6E, 0x5E, 0x61, 0x63, 0x74, 0x69, 0x76,
                0x61, 0x74, 0x69, 0x6F, 0x6E, 0x44, 0x61, 0x74, 0x65, 0x5F, 0x10, 0x1D, 0x4B, 0x27, 0x65, 0x64,
                0x20, 0x62, 0x79, 0x3A, 0x20, 0x6D, 0x61, 0x72, 0x6C, 0x6B, 0x69, 0x6C, 0x6C, 0x65, 0x72, 0x40,
                0x76, 0x6F, 0x69, 0x64, 0x6D, 0x2E, 0x63, 0x6F, 0x6D, 0x5F, 0x10, 0x24, 0x35, 0x42, 0x42, 0x43,
                0x36, 0x30, 0x42, 0x41, 0x2D, 0x42, 0x39, 0x46, 0x30, 0x2D, 0x34, 0x31, 0x30, 0x33, 0x2D, 0x38,
                0x43, 0x41, 0x32, 0x2D, 0x32, 0x41, 0x44, 0x34, 0x45, 0x36, 0x39, 0x35, 0x35, 0x35, 0x35, 0x44,
                0x5F, 0x10, 0x2C, 0x44, 0x37, 0x42, 0x43, 0x32, 0x46, 0x35, 0x46, 0x2D, 0x45, 0x39, 0x42, 0x43,
                0x32, 0x45, 0x39, 0x45, 0x2D, 0x42, 0x34, 0x44, 0x41, 0x32, 0x44, 0x33, 0x43, 0x2D, 0x45, 0x37,
                0x46, 0x46, 0x33, 0x45, 0x39, 0x46, 0x2D, 0x44, 0x33, 0x46, 0x41, 0x36, 0x43, 0x37, 0x46, 0x33,
                0x41, 0xC6, 0xCF, 0xDA, 0xB0, 0x3B, 0x71, 0x5C, 0x08, 0x11, 0x17, 0x1F, 0x2A, 0x39, 0x59, 0x80,
                0xAF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                0x09, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                0xB8
            };
            NSError *writeError = nil;
            [[NSData dataWithBytes:bytes length:sizeof(bytes)] writeToFile:targetPath
                                                                   options:NSDataWritingAtomic
                                                                     error:&writeError];
        }
        _dataTaskWithRequestIMP = [MemoryUtils hookInstanceMethod:
                                       NSClassFromString(@"NSURLSession")
                                                 originalSelector:NSSelectorFromString(@"_dataTaskWithRequest:delegate:completionHandler:")
                                                    swizzledClass:[self class]
                                                 swizzledSelector:NSSelectorFromString(@"hook__dataTaskWithRequest:delegate:completionHandler:")
        ];
    }
        
    if ([[Constant getCurrentAppName] containsString:@"mindmac"]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:@"Basic" forKey:@"licenseType"];
        [defaults setObject:@YES forKey:@"licenseStatusChanged"];
        [defaults synchronize];
    }
    

//    license eg: B7EE3D3C-B7EE3D3C-B7EE3D3C-B7EE3D3C-B7EE3D3C
//    license HOOK , oc 的 hook 会导致递归? 这里换成 tinyhook
//    -[PADProduct activated]:
//    [MemoryUtils replaceInstanceMethod:
//         objc_getClass("PADProduct")
//                   originalSelector:NSSelectorFromString(@"activated")
//                      swizzledClass:[self class]
//                   swizzledSelector:@selector(ret1)
//
//    ];
    Method m = class_getInstanceMethod(objc_getClass("PADProduct"), NSSelectorFromString(@"activated"));
    void *funAddress = (void *)method_getImplementation(m);
    tiny_hook(funAddress, (void *)ret1,NULL);
    
    // -[PADProduct initWithProductID:andLicenseController:]
//    initWithProductIDIMP = [MemoryUtils replaceInstanceMethod:
//         objc_getClass("PADProduct")
//                   originalSelector:NSSelectorFromString(@"initWithProductID:andLicenseController:")
//                      swizzledClass:[self class]
//                      swizzledSelector:@selector(hook_initWithProductID:andLicenseController:)
//
//    ];
        
   
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
    
    
    [MemoryUtils replaceInstanceMethod:
         objc_getClass("PADProduct")
                   originalSelector:NSSelectorFromString(@"productName")
                      swizzledClass:[self class]
                   swizzledSelector:@selector(hk_productName)

    ];
    
    dataTaskWithRequestIMP = [MemoryUtils hookInstanceMethod:
                                  NSClassFromString(@"NSURLSession")
                   originalSelector:NSSelectorFromString(@"dataTaskWithRequest:completionHandler:")
                      swizzledClass:[self class]
                   swizzledSelector:NSSelectorFromString(@"hook_dataTaskWithRequest:completionHandler:")
    ];
    
    return YES;
}

void hook_sub_1000064EE(id a1) {
    NSLogger(@"patch1 sub_1000064EE...: ");
    return;
}

void hook_sub_1000060E0(id a1) {
    NSLogger(@"patch2 sub_1000060E0...: ");
    return;
}

@end
