//
//  Header.h
//  dylib_dobby_hook
//
//  Created by voidm on 2024/10/16.
//

#ifndef Header_h
#define Header_h

#define NSLogger(fmt, ...) \
    NSLog((@"[%@ | TID: %u] %s [Line %d] >>>>>> " fmt), \
              [[NSThread currentThread] isMainThread] ? @"Main" : ([[NSThread currentThread] name] ?: @"Unnamed"), \
              mach_thread_self(), \
              __PRETTY_FUNCTION__, \
              __LINE__, ##__VA_ARGS__)

#endif /* Header_h */
