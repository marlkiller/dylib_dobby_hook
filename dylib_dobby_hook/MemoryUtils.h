//
//  MemoryUtils.h
//  dylib_dobby_hook
//
//  Created by artemis on 2024/1/15.
//

#import <Foundation/Foundation.h>

@interface MemoryUtils : NSObject

+ (NSString *)readStringAtAddress:(uintptr_t)address;
+ (void)writeString:(NSString *)string toAddress:(uintptr_t)address;

+ (int)readIntAtAddress:(uintptr_t)address;
+ (void)writeInt:(int)value toAddress:(uintptr_t)address;

+ (NSString *)readMachineCodeStringAtAddress:(uintptr_t)address length:(int)length;
+ (void)writeMachineCodeString:(NSString *)codeString toAddress:(uintptr_t)address;

@end
