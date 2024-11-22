//
//  iStatHack.m
//  dylib_dobby_hook
//
//  Created by Hokkaido on 2024/10/24.
//

#import <Foundation/Foundation.h>
#import "tinyhook.h"
#import "common_ret.h"
#import "HackProtocolDefault.h"
#import <objc/objc-exception.h>
#import "URLSessionHook.h"

#import "JSONUtils.h"

@interface ShottrHack : HackProtocolDefault



@end

static IMP dataTaskWithRequestIMP;

@implementation ShottrHack

- (NSString *)getAppName {
    return @"cc.ffitch.shottr";
}

- (NSString *)getSupportAppVersion {
    
    return @"1.";
}

- (BOOL)hack {

    dataTaskWithRequestIMP = [MemoryUtils hookInstanceMethod:
                                  NSClassFromString(@"NSURLSession")
                   originalSelector:NSSelectorFromString(@"dataTaskWithRequest:completionHandler:")
                      swizzledClass:[self class]
                   swizzledSelector:NSSelectorFromString(@"hook_dataTaskWithRequest:completionHandler:")
    ];
    
    return YES;
}

- (id)hook_dataTaskWithRequest:(NSMutableURLRequest *)request completionHandler:
    (void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    
    NSURL *url = [request URL];
    NSString *urlString = [url absoluteString];

    // Check if the URL contains specific paths
    if ([urlString containsString:@"/licensing/verify.php"]) {
        NSDictionary *respBody;
        NSString *reqBody = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding];

        NSString *hash = [JSONUtils getVFromJSON:reqBody keyName:@"hash"];
        
        URLSessionHook *dummyTask = [[URLSessionHook alloc] init];
        // Create the response body based on the URL
        respBody = @{
            @"hash": hash,
            @"tier": @"1",
        };

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
    return ((id(*)(id, SEL, NSMutableURLRequest *, void (^)(NSData *, NSURLResponse *, NSError *)))dataTaskWithRequestIMP)(self, _cmd, request, completionHandler);
}

@end
