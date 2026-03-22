//
//  iStatHack.m
//  dylib_dobby_hook
//
//  Created by Hokkaido on 2024/10/10.
//
//  if it is not activated goto Registration page and put this key hank-okay-bail-east-1111-1
//  inject iStat Menus | iStat Menus Menubar.app

#import <Foundation/Foundation.h>
#import "tinyhook.h"
#import "common_ret.h"
#import "HackProtocolDefault.h"
#import <objc/objc-exception.h>
#import "URLSessionHook.h"

@interface iStat7Hack : HackProtocolDefault



@end

static IMP dataTaskWithRequestIMP2;

@implementation iStat7Hack

- (NSString *)getAppName {
    return @"com.bjango.istatmenus";
}

- (NSString *)getSupportAppVersion {
    
    return @"7.";
}

- (BOOL)hack {

    dataTaskWithRequestIMP2 = [MemoryUtils hookInstanceMethod:
                                  NSClassFromString(@"NSURLSession")
                   originalSelector:NSSelectorFromString(@"dataTaskWithRequest:completionHandler:")
                      swizzledClass:[self class]
                   swizzledSelector:NSSelectorFromString(@"hook_dataTaskWithRequest:completionHandler:")
    ];

    [MemoryUtils hookClassMethod:NSClassFromString(@"Registration")
                     originalSelector:NSSelectorFromString(@"isLicenseValid:validationInfo:completion:")
                        swizzledClass:[self class]
                     swizzledSelector:NSSelectorFromString(@"hk_isLicenseValid:validationInfo:completion:")
         ];
    
    
    return YES;
}

- (id)hook_dataTaskWithRequest:(NSMutableURLRequest *)request completionHandler:
    (void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    
    NSURL *url = [request URL];
    NSString *urlString = [url absoluteString];

    // Check if the URL contains specific paths
    if([urlString containsString:@"/api/1/weather/"]) {
        NSData *bodyData = request.HTTPBody;

        if (bodyData) {
            NSError *err = nil;
            id json = [NSJSONSerialization JSONObjectWithData:bodyData options:NSJSONReadingMutableContainers error:&err];
            if ((json && [json isKindOfClass:[NSMutableDictionary class]]) || [json isKindOfClass:[NSDictionary class]]) {
                NSMutableDictionary *dict = ([json isKindOfClass:[NSMutableDictionary class]] ? json : [json mutableCopy]);

                // change fields
                dict[@"setapp"] = @"1"; // e.g. setapp it will bypass api check
                dict[@"license"] = @"trial";       // e.g. @"trial" it will get expired on Mon Oct 06 22:33:57 +0530 2025
                dict[@"identifier"] = @""; // e.g. UUID string

                NSData *newBody = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&err];
                if (newBody) {
                    [request setHTTPBody:newBody];
                    NSString *lenStr = [NSString stringWithFormat:@"%lu", (unsigned long)newBody.length];
                    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
                    [request setValue:lenStr forHTTPHeaderField:@"Content-Length"];
                }
            }
        }
    }
    
    if ([urlString containsString:@"/istatmenus/v3/subscription/"] || [urlString containsString:@"/verify/"] || [urlString containsString:@"/api/1/subscription/"]) {
        NSDictionary *respBody;
        NSString *reqBody = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding];

        URLSessionHook *dummyTask = [[URLSessionHook alloc] init];
        // Create the response body based on the URL
        if ([urlString containsString:@"/istatmenus/v3/subscription/"] || [urlString containsString:@"/api/1/subscription/"]) {
            respBody = @{
                @"start": @1721215186,
                @"end": @3100763986,
                @"frequency": @15,
                @"devices": @3,
                @"paid": @"1"
            };
        } else if ([urlString containsString:@"/verify/"]) {
            respBody = @{
                @"time": @"1728473199",
                @"license": @"hank-okay-bail-east-1111-1",
                @"hashversion": @"3",
                @"signature": @""
            };
        }

        // Log the intercepted request and response body
        NSLogger(@"[hook_dataTaskWithRequest] Intercepted URL: %@, Request Body: %@, Response Body: %@", url, reqBody, respBody);

        // Create a response and call the completion handler
        __auto_type resp = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:200 HTTPVersion:@"1.1" headerFields:@{}];
        NSData *body = [NSJSONSerialization dataWithJSONObject:respBody options:0 error:nil];
        
        if (completionHandler) {
            completionHandler(body, resp, nil);
        }
        return dummyTask;
    }
    
    NSLogger(@"[hook_dataTaskWithRequest] Allowing URL: %@", url);
    return ((id(*)(id, SEL, NSMutableURLRequest *, void (^)(NSData *, NSURLResponse *, NSError *)))dataTaskWithRequestIMP2)(self, _cmd, request, completionHandler);
}

+ (void)hk_isLicenseValid:(id)licenseInfo
      validationInfo:(id)validationInfo
          completion:(void (^)(BOOL isValid, NSError *error))completion {

    NSLogger(@"[hk_isLicenseValid] License is valid");
    // 検証が成功した場合
    completion(YES, nil);
}


@end
