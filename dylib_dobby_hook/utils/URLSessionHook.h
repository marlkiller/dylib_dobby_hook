//
//  URLSessionHook.h
//  dylib_dobby_hook
//
//  Created by voidm on 2024/9/7.
//

#ifndef URLSessionHook_h
#define URLSessionHook_h
#import <Foundation/Foundation.h>

@interface URLSessionHook : NSURLProtocol <NSURLSessionDelegate>

@property (nonatomic, strong) NSURLSession *_session;
@property (nonatomic, strong) NSURLSessionDataTask *_task;
@property (atomic, assign) BOOL _isFinished;
@property (nonatomic, strong) NSLock *lock;


struct BlockLayout {
    void *isa;
    int flags;
    int reserved;
    void (*invoke)(void *, ...);
    void *descriptor;
};

struct BlockDescriptor {
    unsigned long reserved;
    unsigned long size;
    void *copy_helper;
    void *dispose_helper;
    const char *signature;
};

typedef void (^NSCompletionHandler)(NSData *data, NSURLResponse *response, NSError *error);

+ (void)record_NSURL:(NSString *)filter ;
@end
#endif /* URLSessionHook_h */

