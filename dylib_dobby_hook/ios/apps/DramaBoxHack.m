//
//  DramaBoxHack.m
//  dylib_dobby_hook
//
//  Created by markusp87 on 26.04.26.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "tinyhook.h"
#import "MemoryUtils.h"
#import "HackProtocolDefault.h"
#import "common_ret.h"
#import "UIKit/UIKit.h"

@interface DramaBoxHack : HackProtocolDefault

@end

@implementation DramaBoxHack

static IMP didReceiveDataIMP;

- (NSString *)getAppName {
    return @"com.storymatrix.drama";
}

- (NSString *)getSupportAppVersion {
    return @"";
}

- (void)hook_URLSession:(NSURLSession *)session
               dataTask:(NSURLSessionDataTask *)dataTask
          didReceiveData:(NSData *)data {

    NSString *urlString = dataTask.currentRequest.URL.absoluteString ?: @"";

    if ([urlString containsString:@"sapi.dramaboxdb.com"] || [urlString containsString:@"sapi.dramaboxvideo.com"]) {
        NSString *body = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if ([json isKindOfClass:NSDictionary.class]) {
            NSMutableDictionary *dict = [(NSDictionary *)json mutableCopy];

            id dataObj = dict[@"data"];
            if ([dataObj isKindOfClass:NSDictionary.class]) {
                NSMutableDictionary *dataDict = [(NSDictionary *)dataObj mutableCopy];
                id subscribeObj = dataDict[@"subscribeInfo"];
                NSMutableDictionary *subscribeDict = [(NSDictionary *)subscribeObj mutableCopy];

                if (dataDict[@"isVip"]) {
                    if (dataDict[@"subscribeInfo"]) {
                        subscribeDict[@"isVip"] = @1;
                        dataDict[@"subscribeInfo"] = subscribeDict;
                    }
                    dataDict[@"isVip"] = @1; // oder @NO / @1 / @0
                    dataDict[@"isExVip"] = @1;
                    dataDict[@"isSubCoinVip"] = @1;
                    dict[@"data"] = dataDict;
                }
                else if (dataDict[@"list"]) {
                    NSMutableArray *listMutable = [dataDict[@"list"] mutableCopy];

                    for (NSInteger i = 0; i < listMutable.count; i++) {
                        NSMutableDictionary *item = [listMutable[i] mutableCopy];

                        if (item[@"isCharge"]) {
                            item[@"isCharge"] = @0;
                            item[@"isPay"] = @0;
                        }

                        listMutable[i] = item;
                    }

                    dataDict[@"list"] = listMutable;
                    dict[@"data"] = dataDict;
                }
                else if (dataDict[@"unLockType"]) {
                    dataDict[@"jumpType"] = @1; // oder @NO / @1 / @0
                    dataDict[@"vipQualityType"] = @1;
                    dataDict[@"unLockType"] = @2;
                    dataDict[@"status"] = @1;
                    NSMutableDictionary *offlineDict = [(NSDictionary *)dataDict mutableCopy];
                    offlineDict[@"downloadType"] = @3;
                    dataDict[@"offlineDownloadInfo"] = offlineDict;
                    dict[@"data"] = dataDict;
                }
                    NSData *modifiedData =
                    [NSJSONSerialization dataWithJSONObject:dict
                                                    options:0
                                                      error:nil];
                    
                    ((void (*)(id, SEL, id, id, id))didReceiveDataIMP)(
                                                                       self,
                                                                       _cmd,
                                                                       session,
                                                                       dataTask,
                                                                       modifiedData
                                                                       );
                    
                    return;
            }
        }
        NSLogger(@"[Delegate didReceiveData] Data: %@", body);
        
    }

    ((void (*)(id, SEL, id, id, id))didReceiveDataIMP)(
        self,
        _cmd,
        session,
        dataTask,
        data
    );
}

- (BOOL)hack {
    
    Class delegateCls = NSClassFromString(@"DRBCommonKit.CustomURLSessionDelegate");

    if (delegateCls) {
        didReceiveDataIMP =
        [MemoryUtils hookInstanceMethod:delegateCls
                       originalSelector:NSSelectorFromString(@"URLSession:dataTask:didReceiveData:")
                          swizzledClass:[self class]
                        swizzledSelector:NSSelectorFromString(@"hook_URLSession:dataTask:didReceiveData:")];
        NSLogger(@"[DramaBoxURLHook] Delegate hooks installed: %@", delegateCls);
    } else {
        NSLogger(@"[DramaBoxURLHook] Delegate class not found");
    }
    return YES;
}

@end
