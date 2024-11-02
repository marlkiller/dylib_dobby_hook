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

+ (NSArray *)searchMachineCodeOffsets:(NSString *)fullFilePath machineCode:(NSString *)searchMachineCode count:(int)count;

+ (uintptr_t)getPtrFromAddress:(NSString *)searchFilePath targetFunctionAddress:(uintptr_t)targetFunctionAddress;
/**
 * Retrieves the first pointer address matching the specified machine code from the given file path.
 *
 * Example usage:
 * NSNumber *funAddress = [MemoryUtils getPtrFromMachineCode:@"/Contents/MacOS/Surge" machineCode:@“55 48 89 E5 41 57 41 56 41”];
 *
 * @param searchFilePath The path to search for the machine code.
 * @param machineCode The machine code to search for.
 * @return An NSNumber containing the pointer address, or nil if not found.
 */
+ (NSNumber *)getPtrFromMachineCode:(NSString *)searchFilePath machineCode:(NSString *)machineCode;

/**
 * Retrieves an array of pointer addresses matching the specified machine code from the given file path.
 *
 * Example usage:
 * NSArray<NSNumber *> *funAddresses = [MemoryUtils getPtrFromMachineCode:@"/Contents/MacOS/Surge" machineCode:@"55 48 89 E5 41 57 41 56 41" count:6];
 *
 * @param searchFilePath The path to search for the machine code.
 * @param machineCode The machine code to search for.
 * @param count The maximum number of matching addresses to retrieve.
 * @return An NSArray of NSNumber containing pointer addresses, or an empty array if none found.
 */
+ (NSArray<NSNumber *> *)getPtrFromMachineCode:(NSString *)searchFilePath machineCode:(NSString *)machineCode count:(int)count;


+ (uintptr_t)getPtrFromGlobalOffset:(NSString *)searchFilePath globalFunOffset:(uintptr_t)globalFunOffset;
+ (uintptr_t)getPtrFromGlobalOffset:(uint32_t)index globalFunOffset:(uintptr_t)globalFunOffset fileOffset:(uintptr_t)fileOffset;

+ (int)indexForImageWithName:(NSString *)imageName;

+ (void)listAllPropertiesMethodsAndVariables:(Class) cls;
+ (void)inspectObjectWithAddress:(void *)address;
+ (void)exAlart:(NSString *)title message:(NSString *)message;

/**
 交换 OC 对象方法,返回原始函数地址
 [MemoryUtils hookInstanceMethod:
             objc_getClass("_TtC8DevUtils16WindowController")
             originalSelector:NSSelectorFromString(@"showUnregistered")
             swizzledClass:[self class]
             swizzledSelector:NSSelectorFromString(@"hk_showUnregistered")
 ];

 @param originalClass 原始类
 @param originalSelector 原始类的方法
 @param swizzledClass 替换类
 @param swizzledSelector 替换类的方法
 */
+ (IMP)hookInstanceMethod:(Class)originalClass originalSelector:(SEL)originalSelector swizzledClass:(Class)swizzledClass swizzledSelector:(SEL)swizzledSelector;

/**
 交换 OC 类方法,返回原始函数地址
 [MemoryUtils hookClassMethod:
             objc_getClass("GlobalFunction")
             originalSelector:NSSelectorFromString(@"isInChina")
             swizzledClass:[self class]
             swizzledSelector:@selector(hk_isInChina)
 ];
 @param originalClass 原始类
 @param originalSelector 原始类的类方法
 @param swizzledClass 替换类
 @param swizzledSelector 替换类的类方法
 */
+ (IMP)hookClassMethod:(Class)originalClass originalSelector:(SEL)originalSelector swizzledClass:(Class)swizzledClass swizzledSelector:(SEL)swizzledSelector;

/**
 替换 OC 对象方法,返回原始函数地址
 [MemoryUtils hookInstanceMethod:
             objc_getClass("_TtC8DevUtils16WindowController")
             originalSelector:NSSelectorFromString(@"showUnregistered")
             swizzledClass:[self class]
             swizzledSelector:NSSelectorFromString(@"hk_showUnregistered")
 ];

 @param originalClass 原始类
 @param originalSelector 原始类的方法
 @param swizzledClass 替换类
 @param swizzledSelector 替换类的方法
 */
+ (IMP)replaceInstanceMethod:(Class)originalClass originalSelector:(SEL)originalSelector swizzledClass:(Class)swizzledClass swizzledSelector:(SEL)swizzledSelector;

/**
 替换 OC 类方法,返回原始函数地址
 [MemoryUtils hookClassMethod:
             objc_getClass("GlobalFunction")
             originalSelector:NSSelectorFromString(@"isInChina")
             swizzledClass:[self class]
             swizzledSelector:@selector(hk_isInChina)
 ];
 @param originalClass 原始类
 @param originalSelector 原始类的类方法
 @param swizzledClass 替换类
 @param swizzledSelector 替换类的类方法
 */
+ (IMP)replaceClassMethod:(Class)originalClass originalSelector:(SEL)originalSelector swizzledClass:(Class)swizzledClass swizzledSelector:(SEL)swizzledSelector;

/**
 * Example usage:
 * id _appExtraInfoLabel = [MemoryUtils getInstanceIvar:self ivarName:"_appExtraInfoLabel"];
 *
 * @param slf object
 * @param ivarName Variable name, e.g., `self->ivarName` or `[self appInstance]`
 * @return Returns an object wrapped in `id`
 */
+ (id)getInstanceIvar:(id)slf ivarName:(const char *)ivarName;
+ (void)setInstanceIvar:(id)slf ivarName:(const char *)ivarName value:(id)value;

/**
 * Converts a CFStringRef to an char *.
 */
+ (char *)CFStringToCString:(CFStringRef)cfString;

/**
 * Invokes a selector on a target object with a variable number of arguments.
 *
 * Example usage:
 * [MemoryUtils invokeSelector:@"applicationSupportDirectoryPathWithName:"
 *                      onTarget:NSClassFromString(@"KDStorageHelper"),
 *                               @"com.nssurge.surge-mac"]
 *
 * @param selectorName The name of the selector to invoke.
 * @param target The target object on which to invoke the selector.
 * @param ... A variable number of arguments for the selector. The last argument must be `nil`.
 *
 * @return The return value of the invoked selector, which can be an object or an `NSNumber` for primitive types. Returns `nil` for `void` or unsupported return types.
 */
+ (id)invokeSelector:(NSString *)selectorName onTarget:(id)target, ... ;

/**
 * Example usage:
 * [MemoryUtils hookWithMachineCode:@"/Contents/MacOS/Surge"
 *                          machineCode:sub_0x10000e091Code
 *                            fake_func:(void *)ret
 *                                count:2];
 *
 * @param searchFilePath The relative path to the binary in which to search for the function.
 * @param machineCode The machine code pattern used to identify the function to hook.
 * @param fake_func The function to replace the original function with.
 * @param count The maximum number of functions to hook.
 */
+ (void)hookWithMachineCode:(NSString *)searchFilePath
               machineCode:(NSString *)machineCode
                  fake_func:(void *)fake_func
                      count:(int)count;

/**
 * Example usage:
 * [MemoryUtils hookWithMachineCode:@"/Contents/MacOS/Surge"
 *                          machineCode:sub_0x10000e091Code
 *                            fake_func:(void *)ret
 *                                count:2
 *                                out_orig:(void *)&hook_TRTrialStatus_ori:];
 *
 * @param searchFilePath The relative path to the binary in which to search for the function.
 * @param machineCode The machine code pattern used to identify the function to hook.
 * @param fake_func The function to replace the original function with.
 * @param count The maximum number of functions to hook.
 * @param out_orig A pointer to store the original function address, if needed.
 */
+ (void)hookWithMachineCode:(NSString *)searchFilePath
               machineCode:(NSString *)machineCode
                  fake_func:(void *)fake_func
                      count:(int)count
                   out_orig:(void **)out_orig;
@end
