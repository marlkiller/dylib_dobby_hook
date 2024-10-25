//
//  Header.h
//  dylib_dobby_hook
//
//  Created by voidm on 2024/10/16.
//

#ifndef Header_h
#define Header_h

#define NSLogger(fmt, ...) \
    NSLog((@"%s [Line %d] >>>>>> " fmt), \
              __PRETTY_FUNCTION__, \
              __LINE__, ##__VA_ARGS__)

#endif /* Header_h */
