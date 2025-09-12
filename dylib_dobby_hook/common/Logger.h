//
//  Header.h
//  dylib_dobby_hook
//
//  Created by voidm on 2024/10/16.
//

#ifndef Header_h
#define Header_h

//#ifdef DEBUG
//#warning DEBUG is defined
//#else
//#warning DEBUG is NOT defined
//#endif

#ifdef DEBUG
#define NSLogger(fmt, ...) \
    NSLog((@"%s [Line %d] >>>>>> " fmt), \
          __func__, \
          __LINE__, ##__VA_ARGS__)
#else
#define NSLogger(fmt, ...) do {} while (0)
#endif

#ifdef DEBUG
#define CLogger(fmt, ...)                   \
    printf("%s [Line %d] >>>>>> " fmt "\n", \
        __PRETTY_FUNCTION__,                \
        __LINE__, ##__VA_ARGS__)
#else
#define CLogger(fmt, ...) \
    do {                  \
    } while (0)
#endif

#endif /* Header_h */
