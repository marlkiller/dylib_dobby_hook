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
#import <AppKit/AppKit.h>


@implementation MemoryUtils

const uintptr_t ARCH_FAT_SIZE = 0x100000000;

//TODO: 待验证~! 将偏移信息缓存起来,这样似乎比直接扫描程序快一些 ??
#ifdef DEBUG
const bool CACHE_MACHINE_CODE_OFFSETS = false;
#else
const bool CACHE_MACHINE_CODE_OFFSETS = true;
#endif
NSString * CACHE_MACHINE_CODE_KEY = @"All-Offsets";


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
        
        size_t pageSize = (size_t)sysconf(_SC_PAGESIZE);
        uintptr_t pageStart = address & ~(pageSize - 1);
        
        mach_port_t selfTask = mach_task_self();
        kern_return_t kr;

        // 更改页的内存保护
        kr = mach_vm_protect(selfTask, (mach_vm_address_t)pageStart, pageSize, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
        if (kr != KERN_SUCCESS) {
            // 错误处理
            NSLog(@"xxxxxxxxxxxxxxxxerr");
            return;
        }
        
        unsigned char *bytes = (unsigned char *)address;
        for (NSUInteger i = 0; i < byteStrings.count; i++) {
            NSScanner *scanner = [NSScanner scannerWithString:byteStrings[i]];
            unsigned int byteValue;
            [scanner scanHexInt:&byteValue];
            bytes[i] = (unsigned char)byteValue;
        }
         
        // 恢复页的内存保护
        kr = mach_vm_protect(selfTask, (mach_vm_address_t)pageStart, pageSize, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
        if (kr != KERN_SUCCESS) {
            // 错误处理
            return;
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


+ (void)saveMachineCodeOffsetsToUserDefaults:(NSString *)searchMachineCode offsets:(NSArray<NSNumber *> *)offsets {
    NSString *appVersion = [Constant getCurrentAppVersion];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSMutableDictionary *allOffsetsMap = [NSMutableDictionary dictionaryWithDictionary:[defaults objectForKey:CACHE_MACHINE_CODE_KEY]];
    
    // Make sure versionMap is mutable
    NSMutableDictionary *versionMap = [allOffsetsMap objectForKey:appVersion];
    if (!versionMap) {
        versionMap = [NSMutableDictionary dictionary];
        [allOffsetsMap setObject:versionMap forKey:appVersion];
    }
    
    // Convert versionMap to mutable if needed
    if (![versionMap isKindOfClass:[NSMutableDictionary class]]) {
        versionMap = [versionMap mutableCopy];
        [allOffsetsMap setObject:versionMap forKey:appVersion];
    }
    
    [versionMap setObject:offsets forKey:searchMachineCode];
    
    [defaults setObject:allOffsetsMap forKey:CACHE_MACHINE_CODE_KEY];
    [defaults synchronize];
    
    NSLog(@">>>>>> Offset information saved to UserDefaults for machine code: %@", offsets);
}

+ (NSArray<NSNumber *> *)loadMachineCodeOffsetsFromUserDefaults:(NSString *)searchMachineCode {
    NSString *appVersion = [Constant getCurrentAppVersion];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSDictionary *allOffsetsMap = [defaults objectForKey:CACHE_MACHINE_CODE_KEY];
    NSDictionary *versionMap = [allOffsetsMap objectForKey:appVersion];

    if (versionMap) {
        NSArray<NSNumber *> *offsets = [versionMap objectForKey:searchMachineCode];
        NSLog(@">>>>>> Offset information loaded from UserDefaults for machine code: %@", offsets);
        return offsets ?: nil;
    }
    return nil;
}


/*
 * 特征吗搜索
 * ? 匹配所有
 */
+ (NSArray *)searchMachineCodeOffsets:(NSString *)searchFilePath machineCode:(NSString *)searchMachineCode count:(int)count {
    searchMachineCode = [searchMachineCode stringByReplacingOccurrencesOfString:@"." withString:@"?"];

    if (CACHE_MACHINE_CODE_OFFSETS) {
            NSArray *cachedOffsets = [self loadMachineCodeOffsetsFromUserDefaults:searchMachineCode];
            if (cachedOffsets) {
                return [cachedOffsets copy];
            }
        }
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:searchFilePath];

    NSMutableArray<NSNumber *> *offsets = [NSMutableArray array];
    NSData *fileData = [fileHandle readDataToEndOfFile];
    NSUInteger fileLength = [fileData length];

    NSData *searchBytes = machineCode2Bytes(searchMachineCode);
    NSUInteger searchLength = [searchBytes length];
    NSUInteger matchCounter = 0;
    
    for (NSUInteger i = 0; i < fileLength - searchLength + 1; i++) {
         BOOL isMatch = YES;
         for (NSUInteger j = 0; j < searchLength; j++) {
             uint8_t fileByte = ((const uint8_t *)[fileData bytes])[i + j];
             // if (i>364908 && i<364930) {
             //     NSLog(@">>>>>> %d : %p",i,fileByte);
             // }
             uint8_t searchByte = ((const uint8_t *)[searchBytes bytes])[j];
             if (searchByte != 0x90 && fileByte != searchByte) {
                 isMatch = NO;
                 break;
             }
         }
         if (isMatch) {
             [offsets addObject:@(i)];
             matchCounter++;
             if (matchCounter >= count) {
                 break;
             }
         }
     }
    [fileHandle closeFile];
    if (CACHE_MACHINE_CODE_OFFSETS) {
        [self saveMachineCodeOffsetsToUserDefaults :searchMachineCode offsets:offsets];
    }
    return [offsets copy];
}


/**
 * 从Mach-O中读取文件架构信息
 * @param filePath 文件路径
 * @return 返回文件中所有架构列表以及偏移量
 */
NSArray<NSDictionary *> *getArchitecturesInfoForFile(NSString *filePath) {
    NSMutableArray < NSDictionary * > *architecturesInfo = [NSMutableArray array];
    
    NSData *fileData = [NSData dataWithContentsOfFile:filePath];
    if (fileData == nil) {
        NSLog(@">>>>>> Failed to read file data.");
        return nil;
    }
    const uint32_t magic = *(const uint32_t *)fileData.bytes;
    if (magic == FAT_MAGIC || magic == FAT_CIGAM) {
        NSLog(@">>>>>> is FAT");
        struct fat_header *fatHeader = (struct fat_header *)fileData.bytes;
        uint32_t nfat_arch = OSSwapBigToHostInt32(fatHeader->nfat_arch);
        struct fat_arch *fatArchs = (struct fat_arch *)(fileData.bytes + sizeof(struct fat_header));
        
        for (uint32_t i = 0; i < nfat_arch; i++) {
            cpu_type_t cpuType = OSSwapBigToHostInt32(fatArchs[i].cputype);
            cpu_subtype_t cpuSubtype = OSSwapBigToHostInt32(fatArchs[i].cpusubtype);
            uint32_t offset = OSSwapBigToHostInt32(fatArchs[i].offset);
            uint32_t size = OSSwapBigToHostInt32(fatArchs[i].size);
            NSDictionary *archInfo = @{
                    @"cpuType": @(cpuType),
                    @"cpuSubtype": @(cpuSubtype),
                    @"offset": @(offset),
                    @"size": @(size)
            };
            [architecturesInfo addObject:archInfo];
        }
    }else {
        NSLog(@">>>>>> is not FAT");
        // magic == MH_MAGIC_64 || magic == MH_CIGAM_64)
        // /* Constant for the magic field of the mach_header (32-bit architectures) */
        // #define    MH_MAGIC    0xfeedface    /* the mach magic number */
        // #define    MH_CIGAM    0xcefaedfe    /* NXSwapInt(MH_MAGIC) */
        struct mach_header *header = (struct mach_header *)fileData.bytes;
        cpu_type_t cpuType = header->cputype;
        cpu_subtype_t cpuSubtype = header->cpusubtype;

        NSDictionary *archInfo = @{
           @"cpuType": @(cpuType),
           @"cpuSubtype": @(cpuSubtype),
           @"offset": @0,
           @"size": @0
        };
        [architecturesInfo addObject:archInfo];
    }
    return architecturesInfo;
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


+ (int)indexForImageWithName:(NSString *)imageName {
    uint32_t imageCount = _dyld_image_count();
    for (uint32_t i = 0; i < imageCount; i++) {
        const char* currentImageName = _dyld_get_image_name(i);
        NSString *currentImageNameString = [NSString stringWithUTF8String:currentImageName];
        
        if ([currentImageNameString.lastPathComponent isEqualToString:imageName]) {
            NSLog(@">>>>>> indexForImageWithName: %@ -> %d", imageName,i);
            return i;
        }
    }
    
    return -1; // 如果找不到匹配的图像，返回-1
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
+ (void)hookInstanceMethod:(Class)originalClass originalSelector:(SEL)originalSelector swizzledClass:(Class)swizzledClass swizzledSelector:(SEL)swizzledSelector {
    Method originalMethod = class_getInstanceMethod(originalClass, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(swizzledClass, swizzledSelector);
    
    if (originalMethod && swizzledMethod) {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    } else {
        NSLog(@">>>>>> Failed to swizzle method.");
        NSString *message = [NSString stringWithFormat:@"originalClass:%@, originalSelector:%@, originalMethod:%p\n"
                                                        "swizzledClass:%@, swizzledSelector:%@, swizzledMethod:%p\n",
                                                        NSStringFromClass(originalClass),
                                                        NSStringFromSelector(originalSelector),
                                                        originalMethod,
                                                        NSStringFromClass(swizzledClass),
                                                        NSStringFromSelector(swizzledSelector),
                                                        swizzledMethod];
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setInformativeText:message];
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
    }
}

/**
 替换类方法
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
+ (void)hookClassMethod:(Class)originalClass originalSelector:(SEL)originalSelector swizzledClass:(Class)swizzledClass swizzledSelector:(SEL)swizzledSelector {
    Method originalMethod = class_getClassMethod(originalClass, originalSelector);
    Method swizzledMethod = class_getClassMethod(swizzledClass, swizzledSelector);
    
    if (originalMethod && swizzledMethod) {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    } else {
        NSLog(@">>>>>> Failed to swizzle class method.");
        NSString *message = [NSString stringWithFormat:@"originalClass:%@, originalSelector:%@, originalMethod:%p\n"
                                                        "swizzledClass:%@, swizzledSelector:%@, swizzledMethod:%p\n",
                                                        NSStringFromClass(originalClass),
                                                        NSStringFromSelector(originalSelector),
                                                        originalMethod,
                                                        NSStringFromClass(swizzledClass),
                                                        NSStringFromSelector(swizzledSelector),
                                                        swizzledMethod];
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setInformativeText:message];
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
    }
}
@end
