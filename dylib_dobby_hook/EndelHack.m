#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface EndelHack : NSObject
@property (class, nonatomic, readonly) EndelHack *shared;
- (void)applyHack;
@end

@implementation EndelHack

static EndelHack *_shared = nil;
static IMP originalDataTask = NULL;

+ (EndelHack *)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shared = [EndelHack new];
    });
    return _shared;
}

#pragma mark - NSURLSession Hook

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

#pragma mark - Hook Installation

- (void)applyHack {
    NSString *sessionClassName = @"NSURLSession";
    Class sessionClass = objc_getClass([sessionClassName UTF8String]);
    if (sessionClass) {
        NSString *selectorName = @"dataTaskWithRequest:completionHandler:";
        Method targetMethod = class_getInstanceMethod(sessionClass, NSSelectorFromString(selectorName));
        if (targetMethod) {
            originalDataTask = method_getImplementation(targetMethod);
            method_setImplementation(targetMethod, (IMP)hookedDataTaskWithRequest);
        }
    }
}

@end

__attribute__((constructor))
static void initialize(void) {
    @autoreleasepool {
        [[EndelHack shared] applyHack];
    }
}
