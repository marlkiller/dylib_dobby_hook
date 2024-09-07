//
//  URLSessionHook.h
//  dylib_dobby_hook
//
//  Created by voidm on 2024/9/7.
//

#ifndef URLSessionHook_h
#define URLSessionHook_h

@interface URLSessionHook : NSObject

typedef void (^NSCompletionHandler)(NSData *data, NSURLResponse *response, NSError *error);

@end
#endif /* URLSessionHook_h */
