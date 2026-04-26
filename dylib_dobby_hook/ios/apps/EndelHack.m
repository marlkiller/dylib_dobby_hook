#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "HackProtocolDefault.h"
#import "MemoryUtils.h"
#import "Constant.h"

@interface EndelHack : HackProtocolDefault

@end

@implementation EndelHack

static IMP originalDataTask = NULL;

- (NSString *)getAppName {
    return @"com.endel.endel";
}

- (NSString *)getSupportAppVersion {
    return @"";
}

static id hookedDataTaskWithRequest(id self, SEL _cmd, NSURLRequest *request, id completionHandler) {
    if (!request || !completionHandler) {
        if (originalDataTask) {
            return ((id (*)(id, SEL, id, id))originalDataTask)(self, _cmd, request, completionHandler);
        }
        return nil;
    }

    NSString *url = [[request URL] absoluteString];
    NSString *targetEndpoint = @"api-production.endel.io/v4/call";
    
    if ([url containsString:targetEndpoint]) {
        typedef void (^CompletionBlock)(NSData *, NSURLResponse *, NSError *);
        CompletionBlock wrappedHandler = ^(NSData *data, NSURLResponse *response, NSError *error) {

            if (!data || error) {
                ((CompletionBlock)completionHandler)(data, response, error);
                return;
            }

            NSError *jsonError = nil;
            id jsonObject = [NSJSONSerialization JSONObjectWithData:data
                                                           options:NSJSONReadingMutableContainers
                                                             error:&jsonError];

            if (jsonError || ![jsonObject isKindOfClass:[NSDictionary class]]) {
                ((CompletionBlock)completionHandler)(data, response, error);
                return;
            }

            NSMutableDictionary *modified = (NSMutableDictionary *)jsonObject;
            NSString *subscriptionKey = @"subscription";
            
            if (modified[subscriptionKey] && [modified[subscriptionKey] isKindOfClass:[NSDictionary class]]) {
                NSMutableDictionary *sub = [modified[subscriptionKey] mutableCopy];

                [sub setObject:@"DEFAULT" forKey:@"promo_type"];
                [sub setObject:@"YEAR" forKey:@"period"];
                [sub setObject:@"" forKey:@"promo_tag"];
                [sub setObject:@YES forKey:@"store_trial"];
                [sub setObject:@(0) forKey:@"time_left"];
                [sub setObject:@"12_Months_Freemium_Trial" forKey:@"price_id"];
                [sub setObject:@(9999999999) forKey:@"valid_until"];
                [sub setObject:@"ACTIVE" forKey:@"type"];
                [sub setObject:@(0) forKey:@"price"];
                [sub setObject:@"CALENDAR_BASED" forKey:@"trial_type"];
                [sub setObject:@"NOSTORE" forKey:@"prev_store"];
                [sub setObject:@YES forKey:@"cancel_at_period_end"];
                [sub setObject:@NO forKey:@"multiple_subscriptions"];
                [sub setObject:@"SGD" forKey:@"currency"];
                [sub setObject:@"APP_STORE" forKey:@"store"];
                [sub setObject:@NO forKey:@"trial_canceled"];

                [modified setObject:sub forKey:subscriptionKey];
            }

            NSData *modifiedData = [NSJSONSerialization dataWithJSONObject:modified
                                                                   options:0
                                                                     error:nil];

            if (modifiedData) {
                ((CompletionBlock)completionHandler)(modifiedData, response, nil);
            } else {
                ((CompletionBlock)completionHandler)(data, response, error);
            }
        };

        if (originalDataTask) {
            return ((id (*)(id, SEL, id, id))originalDataTask)(self, _cmd, request, [wrappedHandler copy]);
        }
        return nil;
    }

    if (originalDataTask) {
        return ((id (*)(id, SEL, id, id))originalDataTask)(self, _cmd, request, completionHandler);
    }
    return nil;
}

- (BOOL)hack {
    Class sessionClass = objc_getClass("NSURLSession");
    if (sessionClass) {
        originalDataTask = [MemoryUtils hookInstanceMethod:sessionClass
                                          originalSelector:NSSelectorFromString(@"dataTaskWithRequest:completionHandler:")
                                             swizzledClass:[self class]
                                          swizzledSelector:@selector(swizzled_dataTaskWithRequest:completionHandler:)];
        return YES;
    }
    return NO;
}

- (id)swizzled_dataTaskWithRequest:(NSURLRequest *)request completionHandler:(id)completionHandler {
    return hookedDataTaskWithRequest(self, _cmd, request, completionHandler);
}

@end
