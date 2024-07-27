//
//  CommonRetOC.h
//  dylib_dobby_hook
//
//  Created by voidm on 2024/7/27.
//

#ifndef CommonRetOC_h
#define CommonRetOC_h
#import "HackProtocol.h"

@interface CommonRetOC : NSObject <HackProtocol>
- (void)ret;
- (void)ret_;
- (void)ret__;

- (int)ret1;
- (int)ret0;
+ (int)ret1;
+ (int)ret0;
@end

#endif /* CommonRetOC_h */
