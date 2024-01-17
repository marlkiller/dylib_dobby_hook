//
//  MemoryUtils.m
//  dylib_dobby_hook
//
//  Created by artemis on 2024/1/15.
//

#import <Foundation/Foundation.h>
#import "MemoryUtils.h"

@implementation MemoryUtils

+ (NSString *)readStringAtAddress:(uintptr_t)address {
    const char *cString = (const char *)address;
    NSString *string = [NSString stringWithUTF8String:cString];
    return string;
}

+ (void)writeString:(NSString *)string toAddress:(uintptr_t)address {
    const char *cString = [string UTF8String];
    size_t length = strlen(cString) + 1;
    memcpy((void *)address, cString, length);
}

+ (int)readIntAtAddress:(uintptr_t)address {
    int *intPtr = (int *)address;
    int value = *intPtr;
    return value;
}

+ (void)writeInt:(int)value toAddress:(uintptr_t)address {
    int *intPtr = (int *)address;
    *intPtr = value;
}


+ (NSString *)readMachineCodeStringAtAddress:(uintptr_t)address length:(int)length {
    unsigned char *bytes = (unsigned char *)address;
    NSMutableString *codeString = [NSMutableString string];
    for (NSUInteger i = 0; i < length; i++) {
        [codeString appendFormat:@"%02X ", bytes[i]];
    }
    
    return [codeString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

+ (void)writeMachineCodeString:(NSString *)codeString toAddress:(uintptr_t)address {
    NSString *trimmedCodeString = [codeString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSArray<NSString *> *byteStrings = [trimmedCodeString componentsSeparatedByString:@" "];
    
    unsigned char *bytes = (unsigned char *)address;
    for (NSUInteger i = 0; i < byteStrings.count; i++) {
        NSScanner *scanner = [NSScanner scannerWithString:byteStrings[i]];
        unsigned int byteValue;
        [scanner scanHexInt:&byteValue];
        bytes[i] = (unsigned char)byteValue;
    }
}

@end
