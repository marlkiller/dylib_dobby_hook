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

+ (int)readIntAtAddress:(void *)address;
+ (void)writeInt:(int)value toAddress:(void *)address;

+ (NSString *)readMachineCodeStringAtAddress:(uintptr_t)address length:(int)length;
+ (void)writeMachineCodeString:(NSString *)codeString toAddress:(uintptr_t)address;


+ (uintptr_t)getCurrentArchFileOffset: (NSString *) filePath;


+ (void)saveMachineCodeOffsetsToUserDefaults:(NSString *)searchMachineCode offsets:(NSArray<NSNumber *> *)offsets;
+ (NSArray<NSNumber *> *)loadMachineCodeOffsetsFromUserDefaults:(NSString *)searchMachineCode;

+ (NSArray *)searchMachineCodeOffsets:(NSString *)searchFilePath machineCode:(NSString *)searchMachineCode count:(int)count;

+ (uintptr_t)getPtrFromAddress:(uintptr_t)targetFunctionAddress;
+ (uintptr_t)getPtrFromAddress:(uint32_t)index targetFunctionAddress:(uintptr_t)targetFunctionAddress;
+ (uintptr_t)getPtrFromGlobalOffset:(uint32_t)index targetFunctionOffset:(uintptr_t)targetFunctionOffset;
+ (uintptr_t)getPtrFromGlobalOffset:(uint32_t)index targetFunctionOffset:(uintptr_t)targetFunctionOffset reduceOffset:(uintptr_t)reduceOffset;

+ (int)indexForImageWithName:(NSString *)imageName;

+ (void)listAllPropertiesMethodsAndVariables:(Class) cls;
+ (void)inspectObjectWithAddress:(void *)address;
+ (void)exAlart:(NSString *)title message:(NSString *)message;

+ (void)hookInstanceMethod:(Class)originalClass originalSelector:(SEL)originalSelector swizzledClass:(Class)swizzledClass swizzledSelector:(SEL)swizzledSelector;
+ (void)hookClassMethod:(Class)originalClass originalSelector:(SEL)originalSelector swizzledClass:(Class)swizzledClass swizzledSelector:(SEL)swizzledSelector;
+ (void)replaceInstanceMethod:(Class)originalClass originalSelector:(SEL)originalSelector swizzledClass:(Class)swizzledClass swizzledSelector:(SEL)swizzledSelector;
+ (void)replaceClassMethod:(Class)originalClass originalSelector:(SEL)originalSelector swizzledClass:(Class)swizzledClass swizzledSelector:(SEL)swizzledSelector;


+ (id)getInstanceIvar:(Class)cls ivarName:(const char *)ivarName;
+ (void)setInstanceIvar:(Class)slf ivarName:(const char *)ivarName value:(id)value;
@end
