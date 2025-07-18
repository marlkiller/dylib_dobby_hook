//
//  URLSessionHook.m
//  dylib_dobby_hook
//
//  Created by voidm on 2024/9/7.
//

#import "URLSessionHook.h"
#import <objc/runtime.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>
#import "Logger.h"
#import <Network/Network.h>

#include <stdio.h>
#include <unistd.h>
#include <dlfcn.h>
#include <string.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <pthread.h>
#import "common_ret.h"



@implementation URLSessionHook

- (void)resume {
    // 重写 resume 方法，使其不做任何事情
    NSLogger(@"DummyURLSessionDataTask.resume");
}
- (void)set_callCompletionHandlerInline:arg1 {
    // for downie 4
}

#pragma mark - NSURLProtocol
static NSString *G_FILTER = nil;
static NSString *G_HANDLER_KEY = @"G_HANDLER_KEY";
static NSString *G_COMPLETION_HANDLER_KEY = @"G_COMPLETION_HANDLER_KEY";

- (instancetype)init {
    if (self = [super init]) {
        _lock = [NSLock new];
    }
    return self;
}

static void swizzleClassMethod(Class cls, SEL originalSel, SEL swizzledSel) {
    Method orig = class_getClassMethod(cls, originalSel);
    Method swiz = class_getClassMethod(cls, swizzledSel);
    
    if (class_addMethod(cls, originalSel, method_getImplementation(swiz), method_getTypeEncoding(swiz))) {
        class_replaceMethod(cls, swizzledSel, method_getImplementation(orig), method_getTypeEncoding(orig));
    } else {
        method_exchangeImplementations(orig, swiz);
    }
}

+ (NSURLSessionConfiguration *)hook_defaultSessionConfiguration {
    NSURLSessionConfiguration *cfg = [self hook_defaultSessionConfiguration];
    [self insertOurProtocolIntoConfig:cfg];
    return cfg;
}

+ (NSURLSessionConfiguration *)hook_ephemeralSessionConfiguration {
    NSURLSessionConfiguration *cfg = [self hook_ephemeralSessionConfiguration];
    [self insertOurProtocolIntoConfig:cfg];
    return cfg;
}

+ (void)insertOurProtocolIntoConfig:(NSURLSessionConfiguration *)cfg {
    NSMutableArray<Class> *protos = [cfg.protocolClasses mutableCopy] ?: [NSMutableArray array];
    if (![protos containsObject:[URLSessionHook class]]) {
        [protos insertObject:[URLSessionHook class] atIndex:0];
        cfg.protocolClasses = protos;
    }
}


- (NSDictionary<NSString *, NSString *> *)parseQueryParameters:(NSString *)query {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    NSArray *components = [query componentsSeparatedByString:@"&"];
    for (NSString *component in components) {
        NSArray *keyValue = [component componentsSeparatedByString:@"="];
        if (keyValue.count >= 1) {
            NSString *key = [keyValue[0] stringByRemovingPercentEncoding];
            NSString *value = keyValue.count >= 2 ? [keyValue[1] stringByRemovingPercentEncoding] : @"";
            if (key) {
                params[key] = value ?: @"";
            }
        }
    }
    return [params copy];
}
+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    if ([NSURLProtocol propertyForKey:G_HANDLER_KEY inRequest:request]) {
        return NO;
    }
    NSString *scheme = request.URL.scheme.lowercaseString;
    if (!([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"])) {
        NSLogger(@"Skipping non-HTTP(s) request: %@://%@", scheme, request.URL.host);
        return NO;
    }
    NSString *urlString = request.URL.absoluteString;
    if (G_FILTER && ![urlString containsString:G_FILTER]) {
        return NO;
    }
    return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)logDelegateInfo:(NSMutableString *)log forRequest:(NSURLRequest *)request {
    id task = nil;
    if (@available(macOS 10.11, *)) {
        task = [self valueForKey:@"task"];
    }
    if (task) {
        id session = [task valueForKeyPath:@"session"];
        id delegate = [session valueForKeyPath:@"delegate"];
        if (session && delegate) {
            [log appendFormat:@"👤 Delegate: %@\n", NSStringFromClass([delegate class])];
            const char *imageName = class_getImageName([delegate class]);
            if (imageName) {
                [log appendFormat:@"  ├─ Module: %s\n", imageName];
            } else {
                [log appendString:@"  ├─ Module: Unknown\n"];
            }
            return;
        }
    }
    [log appendString:@"👤 Delegate: None\n"];
}


- (void)logRequestDetails:(NSMutableString *)log forRequest:(NSURLRequest *)request {
    // 请求状态和方法
    [log appendFormat:@"🌐 %@ %@\n", request.HTTPMethod ?: @"GET", request.URL.absoluteString];
    
    // 委托信息
    [self logDelegateInfo:log forRequest:request];
    
    // completion handler 分析
    NSString *handlerLog = [NSURLProtocol propertyForKey:G_COMPLETION_HANDLER_KEY inRequest:request];
    if (handlerLog) {
        [log appendString:handlerLog];
    }
    
    // 查询参数
    NSString *query = request.URL.query;
    if (query.length > 0) {
        NSDictionary *params = [self parseQueryParameters:query];
        if (params.count > 0) {
            [log appendString:@"🔍 Request Query: \n"];
            [params enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
                [log appendFormat:@"%@=%@, ", key, value];
            }];
            [log appendString:@"\n"];
        }
    }
    
    // 头部信息
    NSDictionary<NSString *, NSString *> *headers = request.allHTTPHeaderFields;
    if (headers.count > 0) {
        [log appendFormat:@"📤 Request Headers: %@\n", [self compactJSONStringFromDictionary:headers]];
    }
    
    // 请求体处理
    NSData *bodyData = request.HTTPBody;
    if (!bodyData && request.HTTPBodyStream) {
        // 从 HTTPBodyStream 中读取数据（如果有）
        NSInputStream *stream = request.HTTPBodyStream;
        NSMutableData *streamData = [NSMutableData data];
        [stream open];
        uint8_t buffer[1024];
        NSInteger len;
        while ((len = [stream read:buffer maxLength:sizeof(buffer)]) > 0) {
            [streamData appendBytes:buffer length:len];
        }
        [stream close];
        bodyData = streamData;
    }

    if (bodyData.length > 0) {
        NSString *contentType = [request valueForHTTPHeaderField:@"Content-Type"].lowercaseString;
        
        if ([contentType containsString:@"application/x-www-form-urlencoded"]) {
            NSDictionary *formData = [self parseQueryParameters:[[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding]];
            if (formData.count > 0) {
                [log appendString:@"📝 Request Form: \n"];
                [formData enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
                    [log appendFormat:@"%@=%@, ", key, value];
                }];
                [log appendString:@"\n"];
            }
        }
        else if ([contentType containsString:@"application/json"]) {
            NSString *jsonString = [[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding];
            if (jsonString) {
                if (jsonString.length > 1024) {
                    [log appendFormat:@"📝 Request JSON: [truncated 1KB] \n%@...\n", [jsonString substringToIndex:1024]];
                } else {
                    [log appendFormat:@"📝 Request JSON: \n%@\n", jsonString];
                }
            } else {
                [log appendFormat:@"📦 Request Body: %lu bytes\n", (unsigned long)bodyData.length];
            }
        }
        else {
            NSString *bodyString = [[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding];
            if (bodyString) {
                if (bodyString.length > 1024) {
                    [log appendFormat:@"📝 Request Body: [truncated 1KB] \n%@...\n", [bodyString substringToIndex:1024]];
                } else {
                    [log appendFormat:@"📝 Request Body: \n%@\n", bodyString];
                }
            } else {
                [log appendFormat:@"📦 Request Binary: %lu bytes\n", (unsigned long)bodyData.length];
            }
        }
    }
}
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    
    // 无条件信任服务器证书
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
    } else {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

- (NSString *)statusEmojiForCode:(NSInteger)code error:(NSError *)error {
    if (error) return @"🛑";
    if (code >= 500) return @"❌";
    if (code >= 400) return @"⚠️";
    return @"✅";
}

- (NSString *)compactJSONStringFromDictionary:(NSDictionary *)dict {
    if (!dict || dict.count == 0) return nil;
    
    // 过滤掉不可 JSON 序列化的对象
    NSMutableDictionary *filteredDict = [NSMutableDictionary dictionary];
    [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj isKindOfClass:[NSString class]] ||
            [obj isKindOfClass:[NSNumber class]] ||
            [obj isKindOfClass:[NSArray class]] ||
            [obj isKindOfClass:[NSDictionary class]] ||
            [obj isKindOfClass:[NSNull class]]) {
            filteredDict[key] = obj;
        } else {
            filteredDict[key] = [obj description]; // 或者直接跳过
        }
    }];
    
    NSError *jsonError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:filteredDict
                                                       options:0
                                                         error:&jsonError];
    if (!jsonData) {
        NSLogger(@"JSON 序列化失败: %@", jsonError);
        return nil;
    }
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

// [URLSessionHook startLoading]
- (void)startLoading {
    NSMutableURLRequest *request = [self.request mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:G_HANDLER_KEY inRequest:request];

    NSMutableString *log = [NSMutableString string];
    [log appendString:@"⌛ ..."];
    [self logRequestDetails:log forRequest:request];
    NSURLSessionConfiguration *tempConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    tempConfig.protocolClasses = nil; // 防止递归拦截
    NSURLSession *session = [NSURLSession sessionWithConfiguration:tempConfig
                                                             delegate:self
                                                        delegateQueue:nil];
    self._session = session;
    __weak typeof(self) weakSelf = self;
    // NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        // 防止循环引用
        if (!strongSelf) return;
        NSInteger statusCode = [response isKindOfClass:[NSHTTPURLResponse class]] ?
                                 [(NSHTTPURLResponse *)response statusCode] : 0;
        NSString *statusEmoji = [self statusEmojiForCode:statusCode error:error];
        NSString *statusText = [NSHTTPURLResponse localizedStringForStatusCode:statusCode] ?: @"Unknown";
        NSRange firstLineRange = [log rangeOfString:@"⌛ ..."];
        [log replaceCharactersInRange:firstLineRange
                         withString:[NSString stringWithFormat:@"\n%@ %03ld %@\n",
                                    statusEmoji,
                                    (long)statusCode,
                                    statusText]];
        [log appendFormat:@"\n"];
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSDictionary *headers = [(NSHTTPURLResponse *)response allHeaderFields];
            if (headers.count > 0) {
                [log appendFormat:@"📤 Response Headers: %@\n", [self compactJSONStringFromDictionary:headers]];
            }
        }
                    
        // 响应体处理
        if (error) {
            [log appendFormat:@"🛑 Error: %@ (Code: %ld)\n", error.localizedDescription, (long)error.code];
            if (error.userInfo) {
                [log appendFormat:@"📝 Error UserInfo: %@\n", [self compactJSONStringFromDictionary:error.userInfo]];
            }
        } else if (data.length > 0) {
            NSString *contentType = nil;
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                contentType = [[(NSHTTPURLResponse *)response allHeaderFields][@"Content-Type"] lowercaseString];
            }
            // 根据内容类型处理响应体
            if (contentType && [contentType containsString:@"application/json"]) {
                NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                if (jsonString) {
                    if (jsonString.length > 1024) {
                        [log appendFormat:@"📝 Response JSON: [truncated 1KB] \n%@...\n", [jsonString substringToIndex:1024]];
                    } else {
                        [log appendFormat:@"📝 Response JSON: \n%@\n", jsonString];
                    }
                } else {
                    [log appendFormat:@"📦 Response Data: %lu bytes\n", (unsigned long)data.length];
                }
            }
            else if (contentType && ([contentType containsString:@"text"] ||
                                    [contentType containsString:@"xml"] ||
                                    [contentType containsString:@"javascript"] ||
                                    [contentType containsString:@"html"])) {
                NSString *bodyString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                if (bodyString) {
                    if (bodyString.length > 512) {
                        [log appendFormat:@"📝 Response Body: [truncated 1KB] \n%@...\n", [bodyString substringToIndex:512]];
                    } else {
                        [log appendFormat:@"📝 Response Body: \n%@\n", bodyString];
                    }
                } else {
                    [log appendString:@"📝 Response Body: <invalid UTF-8>\n"];
                }
            } else {
                // 二进制数据预览
                const NSUInteger previewLength = MIN(32, data.length);
                NSMutableString *hexPreview = [NSMutableString string];
                const unsigned char *bytes = data.bytes;
                for (NSUInteger i = 0; i < previewLength; i++) {
                    [hexPreview appendFormat:@"%02x ", bytes[i]];
                }
                
                [log appendFormat:@"📦 Response Binary: %lu bytes [%s%s]\n",
                 (unsigned long)data.length,
                 [hexPreview UTF8String],
                 data.length > previewLength ? "..." : ""];
            }
        } else {
            [log appendString:@"📭 Empty Response\n"];
        }
        
        [log appendString:@"--------------------------------\n"];
        NSLogger(@"%@", log);
        
        // 回调客户端
        if (error) {
            [self.client URLProtocol:self didFailWithError:error];
        } else {
            [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
            if (data) [self.client URLProtocol:self didLoadData:data];
            [self.client URLProtocolDidFinishLoading:self];
        }
        self._isFinished = YES;
    }];
    self._task = task;
    [task resume];
}


- (void)stopLoading {
    // NSLogger(@"Stop Loading: %@", self.request.URL.absoluteString);
//    NSError *cancelError = [NSError errorWithDomain:NSCocoaErrorDomain
//                                                 code:NSURLErrorCancelled
//                                             userInfo:nil];
//    [self.client URLProtocol:self didFailWithError:cancelError];
    
//    [self.lock lock];
//    BOOL isFinished = _isFinished;
//    [self.lock unlock];

    if (self._task) {
        if ([self._task respondsToSelector:@selector(cancel)]) {
            [self._task cancel];
        }else{
            NSLogger("WARN cancel: %@",self.request.URL);
        }
        self._task = nil;
    }
    
    if (self._session) {
        if ([self._session respondsToSelector:@selector(invalidateAndCancel)]) {
            [self._session invalidateAndCancel];
        }else {
            NSLogger("WARN invalidateAndCancel: %@",self.request.URL);
        }
        self._session = nil;
    }
    
    // 仅当请求未完成时报告取消错误
    if (!self._isFinished) {
        NSError *cancelError = [NSError errorWithDomain:NSURLErrorDomain
                                                   code:NSURLErrorCancelled
                                               userInfo:nil];
        [self.client URLProtocol:self didFailWithError:cancelError];
    }
}

+ (void)swizzleSessionConfigurationMethods {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class cfgClass = NSClassFromString(@"NSURLSessionConfiguration");
        if (cfgClass) {
            swizzleClassMethod(cfgClass,
                              @selector(defaultSessionConfiguration),
                              @selector(hook_defaultSessionConfiguration));
            
            swizzleClassMethod(cfgClass,
                              @selector(ephemeralSessionConfiguration),
                              @selector(hook_ephemeralSessionConfiguration));
        }
    });
}
+ (void)swizzleSessionTaskMethods {
    SEL originalSelector = @selector(dataTaskWithRequest:completionHandler:);
    SEL swizzledSelector = @selector(p_hook_dataTaskWithRequest:completionHandler:);
    
    Method originalMethod = class_getInstanceMethod([NSURLSession class], originalSelector);
    Method swizzledMethod = class_getInstanceMethod([self class], swizzledSelector);
    
    original_dataTaskWithRequest_completionHandler = (void *)method_getImplementation(originalMethod);
    method_exchangeImplementations(originalMethod, swizzledMethod);
}



NSMutableString* logHandlerAddress(id completionHandler) {
    NSMutableString *log = [NSMutableString string];
    [log appendString:@"🧠 Completion Handler Analysis:\n"];
    
    if (!completionHandler) {
        [log appendString:@"  ❌ Handler is nil\n"];
        return log;
    }
    
    Class blockClass = objc_getClass("NSBlock");
    if (!blockClass || ![completionHandler isKindOfClass:blockClass]) {
        [log appendFormat:@"  ⚠️ Not a Block: %@\n", [completionHandler class]];
        return log;
    }
    
    void *invokePtr = NULL;
    struct BlockLayout *block = NULL;
    
    @try {
        void *blockPtr = (__bridge void *)completionHandler;
        block = (struct BlockLayout *)blockPtr;
        if (block && block->invoke) {
            invokePtr = (void *)block->invoke;
        }
    } @catch (NSException *e) {
        [log appendFormat:@"  ❌ Block Access Error: %@\n", e.reason];
        return log;
    }

    if (!invokePtr) {
        [log appendString:@"  ❌ Failed to get invoke pointer\n"];
        return log;
    }

    Dl_info info;
    if (dladdr(invokePtr, &info)) {
        for (uint32_t i = 0; i < _dyld_image_count(); i++) {
            if (_dyld_get_image_header(i) == info.dli_fbase) {
                const char *imageName = _dyld_get_image_name(i);
                uintptr_t offsetInModule = (uintptr_t)invokePtr - (uintptr_t)info.dli_fbase;
                uintptr_t slide = _dyld_get_image_vmaddr_slide(i);
                uintptr_t staticAddress = (uintptr_t)invokePtr - slide;
                [log appendFormat:@"  ├─ Module: %s\n", imageName];
                [log appendFormat:@"  ├─ Address: Runtime=%p | Offset=0x%lx | Static=0x%lx\n", invokePtr, offsetInModule, staticAddress];
                break;
            }
        }
    } else {
        [log appendFormat:@"  ❌ dladdr failed for: %p\n", invokePtr];
    }
    
//    // 🧪 获取 Block 类型签名
//    const int BLOCK_HAS_SIGNATURE = (1 << 30);
//    if (block && (block->flags & BLOCK_HAS_SIGNATURE)) {
//        // descriptor 是结构体指针，跳过 reserved 和 size
//        void **descPtr = (void **)(block->descriptor);
//        descPtr += 2;
//
//        // 如果包含 copy 和 dispose helper，还需要继续偏移
//        const int BLOCK_HAS_COPY_DISPOSE = (1 << 25);
//        if (block->flags & BLOCK_HAS_COPY_DISPOSE) {
//            descPtr += 2;
//        }
//
//        const char *signature = *(const char **)descPtr;
//        if (signature) {
//            [log appendFormat:@"  ├─ Signature: %s\n", signature];
//        } else {
//            [log appendString:@"  ⚠️ Signature pointer is null\n"];
//        }
//    } else {
//        [log appendString:@"  ⚠️ No signature present in block flags\n"];
//    }
    return log;
}
static NSURLSessionDataTask *(*original_dataTaskWithRequest_completionHandler)(id, SEL, NSURLRequest *, void (^)(NSData *, NSURLResponse *, NSError *)) = NULL;

- (NSURLSessionDataTask *)p_hook_dataTaskWithRequest:(NSURLRequest *)request
                                completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    
    
    if ([URLSessionHook canInitWithRequest:request]) {
        NSMutableURLRequest *mutableRequest = [request mutableCopy];
        [NSURLProtocol setProperty:logHandlerAddress(completionHandler) forKey:G_COMPLETION_HANDLER_KEY inRequest:mutableRequest];
        //    void (^wrappedHandler)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
        //        if (completionHandler) {
        //            completionHandler(data, response, error);
        //        }
        //    };
        return original_dataTaskWithRequest_completionHandler(self, _cmd, mutableRequest, completionHandler);

    }
    return original_dataTaskWithRequest_completionHandler(self, _cmd, request, completionHandler);
}
+ (void)hookExistingSessions {
    int numClasses = objc_getClassList(NULL, 0);
    if (numClasses <= 0) return;
    
    Class *classes = (Class *)malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);
    
    for (int i = 0; i < numClasses; i++) {
        Class cls = classes[i];
        Class superClass = cls;
        while (superClass) {
            if (superClass == [NSURLSession class]) {
                [self injectProtocolIntoSessionClass:cls];
                break;
            }
            superClass = class_getSuperclass(superClass);
        }
    }
    free(classes);
}

+ (void)injectProtocolIntoSessionClass:(Class)sessionClass {
    // Swizzle sessionWithConfiguration:方法
    Method origMethod = class_getClassMethod(sessionClass, @selector(sessionWithConfiguration:));
    if (origMethod) {
        IMP origIMP = method_getImplementation(origMethod);
        
        id (^block)(Class, NSURLSessionConfiguration *) = ^id(Class cls, NSURLSessionConfiguration *config) {
            [URLSessionHook injectProtocolIntoConfiguration:config];
            return ((id (*)(Class, SEL, NSURLSessionConfiguration *))origIMP)(cls, @selector(sessionWithConfiguration:), config);
        };
        
        IMP newIMP = imp_implementationWithBlock(block);
        method_setImplementation(origMethod, newIMP);
    }
    
    Method origMethod2 = class_getClassMethod(sessionClass, @selector(sessionWithConfiguration:delegate:delegateQueue:));
    if (origMethod2) {
        IMP origIMP = method_getImplementation(origMethod2);
        
        id (^block)(Class, NSURLSessionConfiguration *, id, NSOperationQueue *) = ^id(Class cls, NSURLSessionConfiguration *config, id delegate, NSOperationQueue *queue) {
            [URLSessionHook injectProtocolIntoConfiguration:config];
            return ((id (*)(Class, SEL, NSURLSessionConfiguration *, id, NSOperationQueue *))origIMP)(cls, @selector(sessionWithConfiguration:delegate:delegateQueue:), config, delegate, queue);
        };
        
        IMP newIMP = imp_implementationWithBlock(block);
        method_setImplementation(origMethod2, newIMP);
    }
}
+ (void)injectProtocolIntoConfiguration:(NSURLSessionConfiguration *)cfg {
    if (!cfg) return;
    
    NSMutableArray *protocols = [cfg.protocolClasses mutableCopy];
    if (!protocols) protocols = [NSMutableArray array];
    
    if (![protocols containsObject:self]) {
        [protocols insertObject:self atIndex:0];
        cfg.protocolClasses = protocols;
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

static NSString *const P_HTTP  = @"🌐  HTTP";
static NSString *const P_HTTPS = @"🔒  HTTPS";
static NSString *const F_REQ   = @"⬆️  Request";
static NSString *const F_RES   = @"⬇️  Response";
static NSString *const F_REQ_NW   = @"⬆️  NW Request";
static NSString *const F_RES_NW   = @"⬇️  NW Response";



static NSMutableDictionary<NSValue *, NSMutableData *> *sslResponseCaches;
static NSMutableSet<NSValue *> *sslResponseCompleteConnections;

static NSMutableData *cache_for_conn(SSLContextRef conn) {
    NSValue *key = [NSValue valueWithPointer:conn];
    @synchronized (sslResponseCaches) {
        NSMutableData *cache = sslResponseCaches[key];
        if (!cache) {
            cache = [NSMutableData data];
            sslResponseCaches[key] = cache;
        }
        return cache;
    }
}

static void clear_cache_for_conn(SSLContextRef conn) {
    NSValue *key = [NSValue valueWithPointer:conn];
    @synchronized (sslResponseCaches) {
        [sslResponseCaches removeObjectForKey:key];
    }
    @synchronized (sslResponseCompleteConnections) {
        [sslResponseCompleteConnections removeObject:key];
    }
}


void log_connection(uintptr_t id, NSString *proto, NSString *flow, const void *data, size_t len) {
    NSString *out = [[NSString alloc] initWithBytes:data length:len encoding:NSUTF8StringEncoding];
    if (out) {
        NSLogger(@"\n%@ %@ [ID: %lu]\n%@", proto, flow, id, out);
    }
}




// 判断是否 HTTP 请求（简单判断）
int is_http_data(const void *buf, size_t len) {
    if (len < 4) return 0;
    const char *cbuf = (const char *)buf;
    // 常见的 HTTP 请求方法
    static const char *http_methods[] = {
        "GET ", "POST ", "PUT ", "DELETE ", "HEAD ",
        "OPTIONS ", "PATCH ", "TRACE ", "CONNECT "
    };
    for (int i = 0; i < sizeof(http_methods)/sizeof(http_methods[0]); i++) {
        if (strncmp(cbuf, http_methods[i], strlen(http_methods[i])) == 0) {
            return 1;
        }
    }
    // HTTP 响应的起始标志
    if (strncmp(cbuf, "HTTP/", 5) == 0) {
        return 1;
    }
    return 0;
}

// Hook SSLWrite 处理 HTTPS 请求日志
static OSStatus hk_SSLWrite(SSLContextRef conn, const void *data, size_t len, size_t *processed) {
    if (is_http_data(data, len)) {
        log_connection((intptr_t)conn, P_HTTPS,F_REQ, data, len);
    }
    return SSLWrite(conn, data, len, processed);
}

// Hook SSLRead 处理 HTTPS 响应，缓存并打印完整响应头
static OSStatus hk_SSLRead(SSLContextRef conn, void *data, size_t len, size_t *processed) {
    OSStatus ret = SSLRead(conn, data, len, processed);
    if (ret == errSecSuccess && processed && *processed > 0) {
        NSValue *key = [NSValue valueWithPointer:conn];
        @synchronized (sslResponseCompleteConnections) {
            if ([sslResponseCompleteConnections containsObject:key]) {
                log_connection((uintptr_t)conn, P_HTTPS,F_RES, data, *processed);
            } else {
                NSMutableData *cache = cache_for_conn(conn);
                [cache appendBytes:data length:*processed];

                NSString *cachedStr = [[NSString alloc] initWithData:cache encoding:NSUTF8StringEncoding];
                if (cachedStr) {
                    NSRange headerEndRange = [cachedStr rangeOfString:@"\r\n\r\n"];
                    if (headerEndRange.location != NSNotFound) {
                        NSData *fullResponse = [cache copy];
                        log_connection((uintptr_t)conn, P_HTTPS,F_RES,fullResponse.bytes, fullResponse.length);
                        [cache setLength:0];
                        [sslResponseCompleteConnections addObject:key];
                    }
                }
            }
        }
    } else if (ret != errSecSuccess) {
        clear_cache_for_conn(conn);
    }
    return ret;
}

// Hook send 处理 HTTP 请求日志
ssize_t hk_send(int sockfd, const void *buf, size_t len, int flags) {
    if (is_http_data(buf, len)) {
        log_connection(sockfd, P_HTTP,F_REQ, buf, len);
    }
    return send(sockfd, buf, len, flags);
}


// Hook recv 处理 HTTP 响应日志（明文）
ssize_t hk_recv(int sockfd, void *buf, size_t len, int flags) {
    ssize_t ret = recv(sockfd, buf, len, flags);
    if (ret > 0) {
        const char *cbuf = (const char *)buf;
        if (strstr(cbuf, "HTTP/") || strstr(cbuf, "200 OK")) {
            const char *header_end = strstr(cbuf, "\r\n\r\n");
            size_t log_len = header_end ? (header_end - cbuf) + 4 : MIN(ret, 1024);
            log_connection(sockfd, P_HTTP,F_RES,  buf, log_len);
        }
    }
    return ret;
}


// void hk_nw_connection_send(
//     nw_connection_t connection,
//     dispatch_data_t content,
//     nw_content_context_t context,
//     bool is_complete,
//     void (^completion)(nw_error_t error)
// ) {
//     size_t len = dispatch_data_get_size(content);
//     char *copiedBuf = malloc(len + 1);
//     __block size_t offset = 0;
//     dispatch_data_apply(content, ^bool(dispatch_data_t region, size_t region_offset, const void *region_data, size_t region_size) {
//         memcpy(copiedBuf + offset, region_data, region_size);
//         offset += region_size;
//         return true;
//     });
//     copiedBuf[len] = '\0';

//     if (is_http_data(copiedBuf, len)) {
//         log_connection((uintptr_t)connection, P_HTTPS,F_REQ_NW, copiedBuf, len);
//     }

//     // 调用原函数
//     nw_connection_send(connection, content, context, is_complete, completion);

//     free(copiedBuf);
// }

// void hk_nw_connection_receive(
//     nw_connection_t connection,
//                               uint32_t min_len,
//                               uint32_t max_len,
//     void (^completion)(dispatch_data_t, nw_content_context_t, bool, nw_error_t)
// ) {
//     void (^wrapped_completion)(dispatch_data_t, nw_content_context_t, bool, nw_error_t) =
//     ^(dispatch_data_t content, nw_content_context_t context, bool is_complete, nw_error_t error) {

//         size_t len = dispatch_data_get_size(content);
//         char *buf = malloc(len + 1);
//         __block size_t offset = 0;

//         dispatch_data_apply(content, ^bool(dispatch_data_t region, size_t region_offset, const void *region_data, size_t region_size) {
//             memcpy(buf + offset, region_data, region_size);
//             offset += region_size;
//             return true;
//         });
//         buf[len] = '\0';

//         if (is_http_data(buf, len)) {
//             log_connection((uintptr_t)connection, P_HTTPS,F_RES_NW, buf, len);
//         }

//         free(buf);

//         // 调用原始 block
//         completion(content, context, is_complete, error);
//     };

//     // 调用原始函数
//     nw_connection_receive(connection, min_len, max_len, wrapped_completion);
// }
//#define ENABLE_TRAFFIC_HOOKS
#ifdef ENABLE_TRAFFIC_HOOKS
    DYLD_INTERPOSE(hk_send, send);
    DYLD_INTERPOSE(hk_recv, recv);
    DYLD_INTERPOSE(hk_SSLRead, SSLRead);
    DYLD_INTERPOSE(hk_SSLWrite, SSLWrite);
    // DYLD_INTERPOSE(hk_nw_connection_send, nw_connection_send);
    // DYLD_INTERPOSE(hk_nw_connection_receive, nw_connection_receive);
#endif


#pragma clang diagnostic pop


// log stream --predicate 'process == "MyApp" && eventMessage contains "[URLSessionHook startLoading]"' --info
// log stream --predicate 'eventMessage contains "[URLSessionHook startLoading]"' --info
+ (void)record_NSURL:(NSString *)filter {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        

#ifdef ENABLE_TRAFFIC_HOOKS
        signal(SIGUSR1, SIG_IGN);
        sslResponseCaches = [NSMutableDictionary dictionary];
        sslResponseCompleteConnections = [NSMutableSet set];
#endif
        
        G_FILTER = [filter copy];
        // Register Protocol
        [NSURLProtocol registerClass:self];
        // Swizzle session
        [self swizzleSessionTaskMethods];
        // [self swizzleSessionConfigurationMethods];
        [self hookExistingSessions];
    });
}
@end


