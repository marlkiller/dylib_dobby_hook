//
//  HackProtocolDefault.h
//  dylib_dobby_hook
//

#ifndef HackProtocolDefault_h
#define HackProtocolDefault_h

#import "HackProtocol.h"

@interface HackProtocolDefault : NSObject <HackProtocol>

- (void)ret;
- (void)ret_;
- (void)ret__;

- (int)ret1;
- (int)ret0;
+ (int)ret1;
+ (int)ret0;

@end
#endif 

