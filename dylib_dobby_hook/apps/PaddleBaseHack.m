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
                        @"uuid" : @"B7EE3D3C-B7EE3D3C-B7EE3D3C-B7EE3D3C-B7EE3D3C",
                        @"activated" : @"2024-06-02 21:26:07"
                    }
                ],
                @"signature" : @""
            };
        } else if ([urlString containsString:@"/3.2/product/data"]) {
            respBody = @{
                @"success" : @YES,
                @"response" : @ {},
                @"signature" : @""
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
        //2.13.0(230)
        NSString* targetApp = @"/Contents/MacOS/Movist Pro";
        NSLogger(@"Movist Pro start...");
        NSArray *CheckPtr = [MemoryUtils getPtrFromMachineCode:targetApp machineCode:@"4d 6f 76 69 73 74 20 50 72 6f 2e 64 65 62 75 67 2e 64 79 6c 69 62" count:1];
        uint8_t PatchHex[15] = {0x6c,0x69,0x62,0x5f,0x68,0x61,0x63,0x6b,0x2e,0x64,0x79,0x6c,0x69,0x62,0x00};
        
        for (NSNumber *item in CheckPtr) {
           //NSLogger(@"dylib name: %@",[MemoryUtils readMachineCodeStringAtAddress:item.unsignedIntegerValue length:9]);
           write_mem((void*)[item unsignedIntegerValue],(uint8_t *)PatchHex,15);
           //NSLogger(@"dylib name after: %@",[MemoryUtils readMachineCodeStringAtAddress:item.unsignedIntegerValue length:9]);
        }
        
#if defined(__arm64__) || defined(__aarch64__)
        NSString *sub_1000064EE = @"F4 4F BE A9 FD 7B 01 A9 FD 43 00 91 08 2A 00 B0 00 D9 45 F9 86 7E 10 94 F3 03 00 AA C2 28 00 F0 42 C0 0C 91 6A 80 10 94 C2 28 00 F0";

#elif defined(__x86_64__)
        NSString *sub_1000064EE = @"55 48 89 E5 41 57 41 56 53 50 48 8B 3D 49 EB 62 00 48 8B 35 A2 CF 62 00 4C 8B 3D 6B 2A 5F 00 41 FF D7 48 89 C3 48 8B 35 8E DD 62 00 48 8D 15 E7 CD 60";

#endif
        [MemoryUtils hookWithMachineCode:targetApp
                                 machineCode:sub_1000064EE
                                   fake_func:(void *)hook_sub_1000064EE
                                       count:1
        ];
        

#if defined(__arm64__) || defined(__aarch64__)
        NSString *sub_1000060E0 = @"FF 83 05 D1 E9 23 0F 6D FC 6F 10 A9 FA 67 11 A9 F8 5F 12 A9 F6 57 13 A9 F4 4F 14 A9 FD 7B 15 A9 FD 43 05 91 A8 26 00 B0 08 51 41 F9 08 01 40 F9";

#elif defined(__x86_64__)
        NSString *sub_1000060E0 = @"55 48 89 E5 41 57 41 56 41 55 41 54 53 48 81 EC 28 01 00 00 48 8B 05 DD 2A 5F 00 48 8B 00 48 89 45 D0 48 8B 3D 0F EF 62 00 48 8B 35 E0 D1 62 00";
#endif
        [MemoryUtils hookWithMachineCode:targetApp
                                 machineCode:sub_1000060E0
                                   fake_func:(void *)hook_sub_1000060E0
                                       count:1
        ];
        
#if defined(__arm64__) || defined(__aarch64__)
        NSString *sub_100018770 = @"FC 6F BA A9 FA 67 01 A9 F8 5F 02 A9 F6 57 03 A9 F4 4F 04 A9 FD 7B 05 A9 FD 43 01 91 FF 03 02 D1 A1 03 15 F8 A0 03 14 F8";

#elif defined(__x86_64__)
        NSString *sub_100018770 = @"55 48 89 E5 41 57 41 56 41 55 41 54 53 48 81 EC A8 00 00 00 48 89 75 C0 48 89 7D 90 31 FF E8 CF 64 51 00 48 89 85 60 FF FF FF 48 8B 40 F8 48 89";
#endif
        [MemoryUtils hookWithMachineCode:targetApp
                                 machineCode:sub_100018770
                                   fake_func:(void *)ret1
                                       count:1
        ];

        
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

void hook_sub_1000064EE(id a1) {
    NSLogger(@"patch1 sub_1000064EE...: ");
    return;
}

void hook_sub_1000060E0(id a1) {
    NSLogger(@"patch2 sub_1000060E0...: ");
    return;
}

@end
