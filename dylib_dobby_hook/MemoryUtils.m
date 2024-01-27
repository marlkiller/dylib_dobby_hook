//
//  MemoryUtils.m
//  dylib_dobby_hook
//
//  Created by artemis on 2024/1/15.
//

#import <Foundation/Foundation.h>
#import "MemoryUtils.h"
#import "Constant.h"
#import "mach-o/fat.h"
#import "mach-o/getsect.h"
#import <mach-o/dyld.h>
#import <objc/runtime.h>


@implementation MemoryUtils

const uintptr_t ARCH_FAT_SIZE = 0x100000000;

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


NSData *machineCode2Bytes(NSString *hexString) {
    NSMutableData *data = [NSMutableData new];
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    hexString = [[hexString componentsSeparatedByCharactersInSet:whitespace] componentsJoinedByString:@""];

    for (NSUInteger i = 0; i < [hexString length]; i += 2) {
        NSString *byteString = [hexString substringWithRange:NSMakeRange(i, 2)];
        if ([byteString isEqualToString:@"??"]) {
            uint8_t byte = (uint8_t) 144;
            [data appendBytes:&byte length:1];
            continue;
        }
        NSScanner *scanner = [NSScanner scannerWithString:byteString];
        unsigned int byteValue;
        [scanner scanHexInt:&byteValue];
        uint8_t byte = (uint8_t) byteValue;
        [data appendBytes:&byte length:1];
    }
    return [data copy];
}




/*
 * 特征吗搜索
 * ? 匹配所有
 */
+ (NSArray *)searchMachineCodeOffsets:(NSString *)searchFilePath machineCode:(NSString *)searchMachineCode count:(int)count {
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:searchFilePath];    

    NSMutableArray<NSNumber *> *offsets = [NSMutableArray array];
    NSData *fileData = [fileHandle readDataToEndOfFile];
    NSUInteger fileLength = [fileData length];

    NSData *searchBytes = machineCode2Bytes(searchMachineCode);
    NSUInteger searchLength = [searchBytes length];
    NSUInteger searchIndex = 0;
    NSUInteger matchCounter = 0;

    for (NSUInteger i = 0; i < fileLength; i++) {
        uint8_t currentByte = ((const uint8_t *) [fileData bytes])[i];
//        if (i>364908 && i<364930) {
//            NSLog(@">>>>>> %d : %p",i,currentByte);
//        }
        
        if (searchIndex < searchLength) {
            uint8_t searchByte = ((const uint8_t *) [searchBytes bytes])[searchIndex];

            // ?? nop: 0x90
            if (searchByte == 0x90) {
                // Wildcard byte, continue searching
                searchIndex++;
            } else if (currentByte == searchByte) {
                // Matched byte, move to the next search index
                searchIndex++;
            } else {
                // Mismatched byte, reset search index
                searchIndex = 0;
            }
        } else {
            // Reached the end of the search pattern, add offset to results
            [offsets addObject:@(i - searchLength)];
            searchIndex = 0;
            matchCounter++;

            if (matchCounter >= count) {
                break;
            }
        }
    }
    [fileHandle closeFile];
    return [offsets copy];
}


/**
 * 从Mach-O中读取文件架构信息
 * @param filePath 文件路径
 * @return 返回文件中所有架构列表 只能分析FAT架构文件 Mach-O 64位文件解析不了 会死循环
 */
NSArray<NSDictionary *> *getArchitecturesInfoForFile(NSString *filePath) {
    NSMutableArray < NSDictionary * > *architecturesInfo = [NSMutableArray array];

    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
    NSData *fileData = [fileHandle readDataOfLength:sizeof(struct fat_header)];

    if (fileData) {
        const struct fat_header *header = (const struct fat_header *) [fileData bytes];
        uint32_t nfat_arch = OSSwapBigToHostInt32(header->nfat_arch);
        for (uint32_t i = 0; i < nfat_arch; i++) {
            NSData *archData = [fileHandle readDataOfLength:sizeof(struct fat_arch)];
            const struct fat_arch *arch = (const struct fat_arch *) [archData bytes];

            cpu_type_t cpuType = OSSwapBigToHostInt32(arch->cputype);
            cpu_subtype_t cpuSubtype = OSSwapBigToHostInt32(arch->cpusubtype);
            uint32_t offset = OSSwapBigToHostInt32(arch->offset);
            uint32_t size = OSSwapBigToHostInt32(arch->size);

            NSDictionary *archInfo = @{
                    @"cpuType": @(cpuType),
                    @"cpuSubtype": @(cpuSubtype),
                    @"offset": @(offset),
                    @"size": @(size)
            };

            [architecturesInfo addObject:archInfo];
        }
    }
    [fileHandle closeFile];
    return [architecturesInfo copy];
}


/**
 * 获取当前文件相对内存地址偏移
 */
+ (uintptr_t)getCurrentArchFileOffset: (NSString *) filePath {
    const uint32_t desiredCpuType = [Constant isArm] ? CPU_TYPE_ARM64:CPU_TYPE_X86_64;
    NSArray<NSDictionary *> *architecturesInfo = getArchitecturesInfoForFile(filePath);
    for (NSDictionary *archInfo in architecturesInfo) {
        cpu_type_t cpuType = [archInfo[@"cpuType"] unsignedIntValue];
        uint32_t offset = [archInfo[@"offset"] unsignedIntValue];

        if (cpuType == desiredCpuType) {
            return offset;
        } else
            continue;
    }
    return 0;}



+ (uintptr_t)getPtrFromAddress:(uintptr_t)targetFunctionAddress {
    return [self getPtrFromAddress:0 targetFunctionAddress:targetFunctionAddress];
}

/**
 * _dyld_get_image_vmaddr_slide(0)：这是一个函数，用于获取当前加载的动态库的虚拟内存起始地址（slide）。Slide 是一个偏移量，表示动态库在虚拟内存中的偏移位置。
 * 函数地址：这是你希望获取其内存地址的函数的地址。
 + 函数地址：将函数的地址加到 slide 上，这样就可以得到该函数在内存中的实际地址。
 */
+ (uintptr_t)getPtrFromAddress:(uint32_t)index targetFunctionAddress:(uintptr_t)targetFunctionAddress {

    BOOL isDebugging = [Constant isDebuggerAttached];
    intptr_t slide = 0;
    if(!isDebugging){
        // NSLog(@"The current app running with debugging");
        // 不知道为什么
        // 如果是调试模式, 计算地址不需要 + _dyld_get_image_vmaddr_slide,否则会出错
        slide = _dyld_get_image_vmaddr_slide(index);

    }
    return slide + targetFunctionAddress;
}

+ (uintptr_t)getPtrFromGlobalOffset:(uint32_t)index targetFunctionOffset:(uintptr_t)targetFunctionOffset {
    return [self getPtrFromGlobalOffset:index targetFunctionOffset:targetFunctionOffset reduceOffset:0x4000];
}

+ (uintptr_t)getPtrFromGlobalOffset:(uint32_t)index targetFunctionOffset:(uintptr_t)targetFunctionOffset reduceOffset:(uintptr_t)reduceOffset {
    
    // arm : 0x100000000 + 0xa91360 - 0x960000
    // x86 : baseAddress + 0x14ef90 - 0x4000
    // local offset + reduceOffset = global offset
    uintptr_t result  = 0;
    if ([Constant isArm]) {
        if([Constant isDebuggerAttached]){
            uintptr_t result = ARCH_FAT_SIZE+targetFunctionOffset-reduceOffset;
            NSLog(@">>>>>> 0x%lx + 0x%lx - 0x%lx = 0x%lx",ARCH_FAT_SIZE,targetFunctionOffset,reduceOffset,result);
            return result;

        }
        result = _dyld_get_image_vmaddr_slide(index)+ARCH_FAT_SIZE+targetFunctionOffset-reduceOffset;
        NSLog(@">>>>>> 0x%lx + 0x%lx + 0x%lx - 0x%lx = 0x%lx ",_dyld_get_image_vmaddr_slide(index),ARCH_FAT_SIZE,targetFunctionOffset,reduceOffset,result);
        return result;

    }else {
        const struct mach_header *header = _dyld_get_image_header(index);
        uintptr_t baseAddress = (uintptr_t)header;
        result = baseAddress + targetFunctionOffset - reduceOffset;
        NSLog(@">>>>>> 0x%lx + 0x%lx - 0x%lx = 0x%lx ",baseAddress,targetFunctionOffset,reduceOffset,result);
        return result;

    }
    return result;
}

+ (void)inspectObjectWithAddress:(void *)address {
    id object = (__bridge id)address;
    // LicenseModel *license = (__bridge LicenseModel *)addressPtr;
    
    // 获取对象的十六进制地址
    uintptr_t ptrValue = (uintptr_t)address;
    NSLog(@">>>>>> Address: 0x%lx", ptrValue);
    
    // 获取对象的类名
    NSString *className = NSStringFromClass([object class]);
    NSLog(@">>>>>> Class: %@", className);

    // %@ 格式说明符将其作为对象进行输出。在此情况下，NSLog 将会调用对象的 description 方法来获取其字符串表示形式，并将其输出到控制台。
    NSLog(@">>>>>> className.description: %@", address);
    NSString *objectDescription = [object description];
    NSLog(@">>>>>> Object Description: %@", objectDescription);

    // 获取对象的属性与值
    unsigned int count;
    objc_property_t *properties = class_copyPropertyList([object class], &count);

    for (unsigned int i = 0; i < count; i++) {
        objc_property_t property = properties[i];
        NSString *propertyName = [NSString stringWithUTF8String:property_getName(property)];

        id propertyValue = [object valueForKey:propertyName];
        NSLog(@">>>>>> Property: %@, Value: %@", propertyName, propertyValue);
    }

    free(properties);
}


/**
 替换对象方法 -[_TtC8DevUtils16WindowController showUnregistered]
 [MemoryUtils hookMethod:
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
+ (void)hookMethod:(Class)originalClass originalSelector:(SEL)originalSelector swizzledClass:(Class)swizzledClass swizzledSelector:(SEL)swizzledSelector {
    Method originalMethod = class_getInstanceMethod(originalClass, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(swizzledClass, swizzledSelector);
    
    if (originalMethod && swizzledMethod) {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    } else {
        NSLog(@"Failed to swizzle method.");
    }
}

/**
 替换类方法
 hookClassMethod(objc_getClass("MMComposeTextView"), @selector(preprocessTextAttributes:), [self class], @selector(hook_preprocessTextAttributes:));

 @param originalClass 原始类
 @param originalSelector 原始类的类方法
 @param swizzledClass 替换类
 @param swizzledSelector 替换类的类方法
 */
+ (void)hookClassMethod:(Class)originalClass originalSelector:(SEL)originalSelector swizzledClass:(Class)swizzledClass swizzledSelector:(SEL)swizzledSelector {
    Method originalMethod = class_getClassMethod(originalClass, originalSelector);
    Method swizzledMethod = class_getClassMethod(swizzledClass, swizzledSelector);
    
    if (originalMethod && swizzledMethod) {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    } else {
        NSLog(@"Failed to swizzle class method.");
    }
}
@end
