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
#include <mach/mach_vm.h>
#import "Logger.h"
#import "tinyhook.h"

@implementation MemoryUtils

const uintptr_t ARCH_FAT_SIZE = 0x100000000;

#ifdef DEBUG
const bool CACHE_MACHINE_CODE_OFFSETS = false;
#else
const bool CACHE_MACHINE_CODE_OFFSETS = true;
#endif
NSString * CACHE_MACHINE_CODE_KEY = @"All-Offsets";

static NSMutableDictionary<NSString *, NSNumber *> *fileOffsetCache = NULL;

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fileOffsetCache = [[NSMutableDictionary alloc] init];
    });
}
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

+ (int)readIntAtAddress:(void *)address {
    int *intPtr = (int *)address;
    int value = *intPtr;
    return value;
}

+ (void)writeInt:(int)value toAddress:(void *)address {
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
            NSLogger(@"xxxxxxxxxxxxxxxxerr");
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
    NSString *appVersion = [Constant getCurrentAppCFBundleVersion];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *allOffsetsMap = [NSMutableDictionary dictionaryWithDictionary:[defaults objectForKey:CACHE_MACHINE_CODE_KEY]];
    NSLogger(@"Offset information saved to UserDefaults for %@ machine code: %@",appVersion, offsets);

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
}

+ (NSArray<NSNumber *> *)loadMachineCodeOffsetsFromUserDefaults:(NSString *)searchMachineCode {
    NSString *appVersion = [Constant getCurrentAppCFBundleVersion];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSDictionary *allOffsetsMap = [defaults objectForKey:CACHE_MACHINE_CODE_KEY];
    NSDictionary *versionMap = [allOffsetsMap objectForKey:appVersion];

    if (versionMap) {
        NSArray<NSNumber *> *offsets = [versionMap objectForKey:searchMachineCode];
        NSLogger(@"Offset information loaded from UserDefaults %@ for machine code: %@",appVersion, offsets);
        return offsets ?: nil;
    }
    return nil;
}


/*
 * 特征吗搜索
 * ? 匹配所有
 */
+ (NSArray *)searchMachineCodeOffsets:(NSString *)fullFilePath machineCode:(NSString *)machineCode count:(int)count {
    machineCode = [machineCode stringByReplacingOccurrencesOfString:@"." withString:@"?"];

    if (CACHE_MACHINE_CODE_OFFSETS) {
        NSArray *cachedOffsets = [self loadMachineCodeOffsetsFromUserDefaults:machineCode];
        if (cachedOffsets) {
            return [cachedOffsets copy];
        }
    }
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:fullFilePath];

    NSMutableArray<NSNumber *> *offsets = [NSMutableArray array];
    NSData *fileData = [fileHandle readDataToEndOfFile];
    NSUInteger fileLength = [fileData length];

    NSData *searchBytes = machineCode2Bytes(machineCode);
    NSUInteger searchLength = [searchBytes length];
    NSUInteger matchCounter = 0;
    
    for (NSUInteger i = 0; i < fileLength - searchLength + 1; i++) {
         BOOL isMatch = YES;
         for (NSUInteger j = 0; j < searchLength; j++) {
             uint8_t fileByte = ((const uint8_t *)[fileData bytes])[i + j];
             // if (i>364908 && i<364930) {
             //     NSLogger(@"%d : %p",i,fileByte);
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
    
    if (matchCounter==0) {
        NSString *message = [NSString stringWithFormat:@"searchFilePath: %@ \rmachineCode: %@",
                                                fullFilePath,
                                                machineCode];
        
        [self exAlart:@"特征吗匹配 异常 ?!!!" message:message];
        return offsets;
    }
    if (CACHE_MACHINE_CODE_OFFSETS) {
        [self saveMachineCodeOffsetsToUserDefaults :machineCode offsets:offsets];
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
        NSLogger(@"Failed to read file data.");
        return nil;
    }
    const uint32_t magic = *(const uint32_t *)fileData.bytes;
    if (magic == FAT_MAGIC || magic == FAT_CIGAM) {
        NSLogger(@"is FAT");
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
        NSLogger(@"is not FAT");
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
    return 0;
}



/**
 * 根据  hopper|ida 中的绝对地址计算内存地址 , 这个方法好像是有点问题..
 * _dyld_get_image_vmaddr_slide(0)：用于获取当前加载的动态库的虚拟内存起始地址（slide）。Slide 是一个偏移量，表示动态库在虚拟内存中的偏移位置。
 */
+ (uintptr_t)getPtrFromAddress:(NSString *)searchFilePath targetFunctionAddress:(uintptr_t)targetFunctionAddress {
    NSString *imageName = [searchFilePath lastPathComponent];
    int imageIndex = [self indexForImageWithName:imageName];
    uintptr_t result  = 0;
//    if ([Constant isArm]) {
//
//    }
    result = targetFunctionAddress + _dyld_get_image_vmaddr_slide(imageIndex);
    NSLogger(@"0x%lx + 0x%lx = 0x%lx ", targetFunctionAddress, _dyld_get_image_vmaddr_slide(imageIndex), result);
    return result;
}

/**
 * 根据  hopper|ida 中的 global offsett 地址计算内存地址
 */
+ (uintptr_t)getPtrFromGlobalOffset:(NSString *)searchFilePath globalFunOffset:(uintptr_t)globalFunOffset {
    NSString *fullFilePath = [[Constant getCurrentAppPath] stringByAppendingString:searchFilePath];
    uintptr_t fileOffset = [self getCacheFileOffset:fullFilePath];
    NSString *imageName = [searchFilePath lastPathComponent];
    int imageIndex = [self indexForImageWithName:imageName];
    intptr_t funAddress = [MemoryUtils getPtrFromGlobalOffset:imageIndex globalFunOffset:globalFunOffset fileOffset:(uintptr_t)fileOffset];
    return funAddress;
}


+ (NSNumber *)getPtrFromMachineCode:(NSString *)searchFilePath machineCode:(NSString *)machineCode {
    NSArray<NSNumber *> *funAddresses = [self getPtrFromMachineCode:searchFilePath machineCode:machineCode count:1];
    if (funAddresses.count > 0) {
        return funAddresses[0];
    }
    return nil;
}

+ (NSArray<NSNumber *> *)getPtrFromMachineCode:(NSString *)searchFilePath machineCode:(NSString *)machineCode count:(int)count  {
    
    NSString *fullFilePath = [[Constant getCurrentAppPath] stringByAppendingString:searchFilePath];
    uintptr_t fileOffset = [self getCacheFileOffset:fullFilePath];
    NSArray<NSNumber *> *codeOffsets = [self searchMachineCodeOffsets:fullFilePath
                                                          machineCode:machineCode
                                                                count:count];
    
    NSString *imageName = [searchFilePath lastPathComponent];
    int imageIndex = [self indexForImageWithName:imageName];
    NSMutableArray<NSNumber *> *funAddresses = [NSMutableArray array];
    
    int processedCount = 0;
    for (NSNumber *globalFunOffset in codeOffsets) {
        if (processedCount >= count) {
            break;
        }
        uintptr_t funAddress = [MemoryUtils getPtrFromGlobalOffset:imageIndex
                                                  globalFunOffset:(uintptr_t)[globalFunOffset unsignedIntegerValue]
                                                       fileOffset:fileOffset];
        [funAddresses addObject:@(funAddress)];
        processedCount++;
    }
    
    return [funAddresses copy];
}
    
+ (uintptr_t)getPtrFromGlobalOffset:(uint32_t)index globalFunOffset:(uintptr_t)globalFunOffset fileOffset:(uintptr_t)fileOffset {
    
    // arm : 0x100000000 + 0xa91360 - 0x960000
    // x86 : baseAddress + 0x14ef90 - 0x4000
    // local offset + fileOffset = global offset
    uintptr_t result  = 0;
//    const struct mach_header *header = _dyld_get_image_header(index);
//    uintptr_t baseAddress = (uintptr_t)header;
//    result = baseAddress + globalFunOffset - fileOffset;
//    NSLogger(@"add1 0x%lx + 0x%lx - 0x%lx = 0x%lx ",baseAddress,globalFunOffset,fileOffset,result);
    result = _dyld_get_image_vmaddr_slide(index)+ARCH_FAT_SIZE+globalFunOffset-fileOffset;
    NSLogger(@"0x%lx + 0x%lx + 0x%lx - 0x%lx = 0x%lx ",_dyld_get_image_vmaddr_slide(index),ARCH_FAT_SIZE,globalFunOffset,fileOffset,result);
    return result;
}


+ (int)indexForImageWithName:(NSString *)imageName {
    uint32_t imageCount = _dyld_image_count();
    for (uint32_t i = 0; i < imageCount; i++) {
        const char* currentImageName = _dyld_get_image_name(i);
        NSString *currentImageNameString = [NSString stringWithUTF8String:currentImageName];
        
        if ([currentImageNameString.lastPathComponent isEqualToString:imageName]) {
            NSLogger(@"%@ -> %d", imageName,i);
            return i;
        }
    }
    
    return -1; // 如果找不到匹配的图像，返回-1
}


+ (void) listAllPropertiesMethodsAndVariables:(Class) cls {
    // 获取类的属性列表
    unsigned int propertyCount;
    objc_property_t *properties = class_copyPropertyList(cls, &propertyCount);
    NSLogger(@"Properties for class %@", NSStringFromClass(cls));
    for (unsigned int i = 0; i < propertyCount; i++) {
        objc_property_t property = properties[i];
        const char *propertyName = property_getName(property);
        NSLogger(@"- %@", [NSString stringWithUTF8String:propertyName]);
    }
    free(properties);
    
    // 获取类的实例变量列表
    unsigned int ivarCount;
    Ivar *ivars = class_copyIvarList(cls, &ivarCount);
    NSLogger(@"Instance Variables for class %@", NSStringFromClass(cls));
    for (unsigned int i = 0; i < ivarCount; i++) {
        Ivar ivar = ivars[i];
        const char *ivarName = ivar_getName(ivar);
        NSLogger(@"- %s", ivarName);
    }
    free(ivars);
    
    // 获取类的实例方法列表
    unsigned int instanceMethodCount;
    Method *instanceMethods = class_copyMethodList(cls, &instanceMethodCount);
    NSLogger(@"Instance Methods for class %@", NSStringFromClass(cls));
    for (unsigned int i = 0; i < instanceMethodCount; i++) {
        Method method = instanceMethods[i];
        NSLogger(@"- %@", NSStringFromSelector(method_getName(method)));
    }
    free(instanceMethods);
    
    // 获取类的方法列表
    unsigned int methodCount;
    Method *methods = class_copyMethodList(object_getClass(cls), &methodCount);
    NSLogger(@"Class Methods for class %@", NSStringFromClass(cls));
    for (unsigned int i = 0; i < methodCount; i++) {
        Method method = methods[i];
        NSLogger(@"+ %@", NSStringFromSelector(method_getName(method)));
    }
    free(methods);
}

+ (void)inspectObjectWithAddress:(void *)address {
    id object = (__bridge id)address;
    // LicenseModel *license = (__bridge LicenseModel *)addressPtr;
    
    // 获取对象的十六进制地址
    uintptr_t ptrValue = (uintptr_t)address;
    NSLogger(@"Address: 0x%lx", ptrValue);
    
    // 获取对象的类名
    NSString *className = NSStringFromClass([object class]);
    NSLogger(@"Class: %@", className);

    // %@ 格式说明符将其作为对象进行输出。在此情况下，NSLog 将会调用对象的 description 方法来获取其字符串表示形式，并将其输出到控制台。
    NSLogger(@"className.description: %@", address);
    NSString *objectDescription = [object description];
    NSLogger(@"Object Description: %@", objectDescription);

    // 获取对象的属性与值
    unsigned int count;
    objc_property_t *properties = class_copyPropertyList([object class], &count);

    for (unsigned int i = 0; i < count; i++) {
        objc_property_t property = properties[i];
        NSString *propertyName = [NSString stringWithUTF8String:property_getName(property)];

        id propertyValue = [object valueForKey:propertyName];
        NSLogger(@"Property: %@, Value: %@", propertyName, propertyValue);
    }

    free(properties);
}


+ (void)exAlart:(NSString *)title message:(NSString *)message {
    
    
    message = [NSString stringWithFormat:@"App: %@\rVersion: %@ %@\r\r%@",
               [Constant getCurrentAppPath],
               [Constant getSystemArchitecture],
               [Constant getCurrentAppVersion],
               message];
    
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setInformativeText:message];
    [alert setMessageText:title];
    [alert addButtonWithTitle:@"OK"];    
    [alert addButtonWithTitle:@"Commit Issue"];
    [alert addButtonWithTitle:@"Exit!!"];
    NSDictionary *attributes = @{
        NSFontAttributeName: [NSFont systemFontOfSize:12.0]
    };
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:message attributes:attributes];
    CGFloat textWidth = [attributedString size].width;
    alert.accessoryView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, textWidth, 0)];
    NSImage *image = [NSImage imageNamed:NSImageNameCaution];
    [alert setIcon:image];
    NSInteger response = [alert runModal];
    // Handle button clicks
    if (response == NSAlertFirstButtonReturn) {
        // OK button clicked
    }  else if (response == NSAlertSecondButtonReturn) {
        // 提交 Issue button clicked
        NSString *urlString = @"https://github.com/marlkiller/dylib_dobby_hook/issues/new";
        NSURL *url = [NSURL URLWithString:urlString];
        NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
        [workspace openURL:url];
    }else if (response == NSAlertThirdButtonReturn) {
        // 提交 Issue button clicked
        exit(0);
    }
}

+ (IMP)hookInstanceMethod:(Class)originalClass originalSelector:(SEL)originalSelector swizzledClass:(Class)swizzledClass swizzledSelector:(SEL)swizzledSelector {
    Method originalMethod = class_getInstanceMethod(originalClass, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(swizzledClass, swizzledSelector);
    IMP imp = nil;
    if (originalMethod && swizzledMethod) {
        imp = method_getImplementation(originalMethod);
        method_exchangeImplementations(originalMethod, swizzledMethod);
    } else {
        NSLogger(@"Failed to swizzle method.");
        NSString *message = [NSString stringWithFormat:@"originalClass: %@, originalSelector: %@, originalMethod:%p\r"
                                                        "swizzledClass: %@, swizzledSelector: %@, swizzledMethod:%p",
                                                        NSStringFromClass(originalClass),
                                                        NSStringFromSelector(originalSelector),
                                                        originalMethod,
                                                        NSStringFromClass(swizzledClass),
                                                        NSStringFromSelector(swizzledSelector),
                                                        swizzledMethod];
        [self exAlart:@"hookInstanceMethod 异常 ?!!!" message:message];
    }
    return imp;
}

+ (IMP)hookClassMethod:(Class)originalClass originalSelector:(SEL)originalSelector swizzledClass:(Class)swizzledClass swizzledSelector:(SEL)swizzledSelector {
    Method originalMethod = class_getClassMethod(originalClass, originalSelector);
    Method swizzledMethod = class_getClassMethod(swizzledClass, swizzledSelector);
    
    IMP imp = nil;
    if (originalMethod && swizzledMethod) {
        imp = method_getImplementation(originalMethod);
        method_exchangeImplementations(originalMethod, swizzledMethod);
    } else {
        NSLogger(@"Failed to swizzle class method.");
        NSString *message = [NSString stringWithFormat:@"originalClass: %@, originalSelector: %@, originalMethod: %p\r"
                                                        "swizzledClass: %@, swizzledSelector: %@, swizzledMethod: %p",
                                                        NSStringFromClass(originalClass),
                                                        NSStringFromSelector(originalSelector),
                                                        originalMethod,
                                                        NSStringFromClass(swizzledClass),
                                                        NSStringFromSelector(swizzledSelector),
                                                        swizzledMethod];
        [self exAlart:@"hookClassMethod 异常 ?!!!" message:message];
    }
    return imp;
}

+ (IMP)replaceInstanceMethod:(Class)originalClass originalSelector:(SEL)originalSelector swizzledClass:(Class)swizzledClass swizzledSelector:(SEL)swizzledSelector {
    Method originalMethod = class_getInstanceMethod(originalClass, originalSelector);
    IMP swizzledImplementation = class_getMethodImplementation(swizzledClass, swizzledSelector);
    const char *types = method_getTypeEncoding(originalMethod);
    
    IMP imp = nil;
    if (originalMethod && swizzledImplementation) {
        imp = method_getImplementation(originalMethod);
        // 替换对象方法
        class_replaceMethod(originalClass, originalSelector, swizzledImplementation, types);
    } else {
        NSLogger(@"Failed to replace instance method.");
        NSString *message = [NSString stringWithFormat:@"originalClass: %@, originalSelector: %@, originalMethod: %p\r"
                                                        "swizzledClass: %@, swizzledSelector: %@, swizzledImplementation: %p",
                                                        NSStringFromClass(originalClass),
                                                        NSStringFromSelector(originalSelector),
                                                        method_getImplementation(originalMethod),
                                                        NSStringFromClass(swizzledClass),
                                                        NSStringFromSelector(swizzledSelector),
                                                        swizzledImplementation];
        [self exAlart:@"replaceInstanceMethod 异常 ?!!!" message:message];
    }
    return imp;
}

+ (IMP)replaceClassMethod:(Class)originalClass originalSelector:(SEL)originalSelector swizzledClass:(Class)swizzledClass swizzledSelector:(SEL)swizzledSelector {
    Method originalMethod = class_getClassMethod(originalClass, originalSelector);
    IMP swizzledImplementation = class_getMethodImplementation(swizzledClass, swizzledSelector);
    const char *types = method_getTypeEncoding(originalMethod);
    
    IMP imp = nil;
    if (originalMethod && swizzledImplementation) {
        imp = method_getImplementation(originalMethod);
        // 替换类方法
        class_replaceMethod(object_getClass(originalClass), originalSelector, swizzledImplementation, types);
    } else {
        NSLogger(@"Failed to replace class method.");
        NSString *message = [NSString stringWithFormat:@"originalClass: %@, originalSelector: %@, originalMethod: %p\r"
                                                        "swizzledClass: %@, swizzledSelector: %@, swizzledImplementation: %p",
                                                        NSStringFromClass(originalClass),
                                                        NSStringFromSelector(originalSelector),
                                                        method_getImplementation(originalMethod),
                                                        NSStringFromClass(swizzledClass),
                                                        NSStringFromSelector(swizzledSelector),
                                                        swizzledImplementation];
        [self exAlart:@"replaceClassMethod 异常 ?!!!" message:message];
    }
    return imp;
}

+ (id) getInstanceIvar:(id)slf ivarName:(const char *)ivarName {
    Class cls = object_getClass(slf);
    Ivar ivar = class_getInstanceVariable(cls, ivarName);

    if (!ivar) {
        NSLogger(@"%@.%s is null", slf, ivarName);
        return nil;
    }
    const char *ivarType = ivar_getTypeEncoding(ivar);
    ptrdiff_t ivarOffset = ivar_getOffset(ivar);
    void *ivarPointer = (__bridge void *)slf + ivarOffset;
    id result = nil; 

    if (strcmp(ivarType, @encode(int)) == 0) {
        int value = *(int *)ivarPointer;
        result = @(value);
    } else if (strcmp(ivarType, @encode(float)) == 0) {
        float value = *(float *)ivarPointer;
        result = @(value);
    } else if (strcmp(ivarType, @encode(BOOL)) == 0) {
        BOOL value = *(BOOL *)ivarPointer;
        result = @(value);
    } else if (strcmp(ivarType, @encode(double)) == 0) {
        double value = *(double *)ivarPointer;
        result = @(value);
    } else if (ivarType[0] == '@') {
        result = object_getIvar(slf, ivar);
    } else {
        // swift: ivarType is empty
        NSLogger(@"[WARN] Unsupported type: %s", ivarType);
        result = object_getIvar(slf, ivar);
    }
    NSLogger(@"%@.%s :[%s] = %@", slf, ivarName,ivarType ,result);
    return result;
}

+ (void) setInstanceIvar:(id)slf ivarName:(const char *)ivarName value:(id)value {
    Class cls = object_getClass(slf);

    Ivar ivar = class_getInstanceVariable(cls, ivarName);
    if (!ivar) {
        NSLogger(@"%@.%s is null ",slf,ivarName);
        return;
    };
    const char *ivarType = ivar_getTypeEncoding(ivar);
    ptrdiff_t ivarOffset = ivar_getOffset(ivar);
    void *ivarPointer = (__bridge void *)slf + ivarOffset;
    if (strcmp(ivarType, @encode(int)) == 0) {
        *(int *)ivarPointer = [value intValue];
    } else if (strcmp(ivarType, @encode(float)) == 0) {
        *(float *)ivarPointer = [value floatValue];
    } else if (strcmp(ivarType, @encode(BOOL)) == 0) {
        *(BOOL *)ivarPointer = [value boolValue];
    } else if (strcmp(ivarType, @encode(double)) == 0) {
        *(double *)ivarPointer = [value doubleValue];
    } else if (ivarType[0] == '@') {
        object_setIvar(slf, ivar, value);
    } else {
        // swift: ivarType is empty
        NSLogger(@"[WARN] Unsupported type: %s", ivarType);
        object_setIvar(slf, ivar, value);
    }
    NSLogger(@"%@.%s :[%s] set to %@", slf, ivarName, ivarType, value);
}

+ (char *)CFStringToCString:(CFStringRef)cfString {
    if (!cfString) {
        return NULL;
    }
    CFIndex maxLength = CFStringGetMaximumSizeForEncoding(CFStringGetLength(cfString), kCFStringEncodingUTF8) + 1;
    char *cString = (char *)malloc(maxLength);
    if (!cString) {
        NSLogger(@"Memory allocation failed.");
        return NULL;
    }
    Boolean success = CFStringGetCString(cfString, cString, maxLength, kCFStringEncodingUTF8);
    if (!success) {
        NSLogger(@"Failed to convert CFString to C string.");
        free(cString);
        return NULL;
    }
    return cString;
}


+ (id)invokeSelector:(NSString *)selectorName onTarget:(id)target, ... {
    NSLogger(@"selectorName = %@, target = %@", selectorName, target);
    SEL selector = NSSelectorFromString(selectorName);
    if (![target respondsToSelector:selector]) {
        NSLogger(@"Target does not respond to selector %@", selectorName);
        return nil;
    }

    NSMethodSignature *signature = [target methodSignatureForSelector:selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.target = target;
    invocation.selector = selector;
    // [invocation setArgument:&param1 atIndex:2];
    va_list args;
    va_start(args, target);
    NSUInteger numberOfArguments = [signature numberOfArguments];
        
    // 输出所有参数
    NSMutableArray *params = [NSMutableArray array];
    for (NSUInteger i = 2; i < numberOfArguments; i++) {
        id arg = va_arg(args, id);
        [params addObject:arg ? arg : [NSNull null]];
        [invocation setArgument:&arg atIndex:i];
    }
    
    va_end(args);
    NSLogger(@"Parameters: %@", params);
    
    [invocation invoke];
    const char *returnType = [signature methodReturnType];
    id returnValue = nil;
    if (strcmp(returnType, "v") != 0) { // void
        if (strcmp(returnType, "@") == 0) { // obj
         // __unsafe_unretained 避免 ARC 环境下自动增加引用计数，避免对象生命周期管理错误。
            id __unsafe_unretained objValue;
            [invocation getReturnValue:&objValue];
            returnValue = objValue ? objValue : nil;
        } else if (strcmp(returnType, "#") == 0) { // Class
            Class classValue;
            [invocation getReturnValue:&classValue];
            returnValue = classValue;
        } else if (strcmp(returnType, ":") == 0) { // SEL
            SEL selValue;
            [invocation getReturnValue:&selValue];
            returnValue = NSStringFromSelector(selValue);
        } else if (strcmp(returnType, "c") == 0) { // char
            char charValue;
            [invocation getReturnValue:&charValue];
            returnValue = @(charValue);
        } else if (strcmp(returnType, "C") == 0) { // unsigned char
            unsigned char ucharValue;
            [invocation getReturnValue:&ucharValue];
            returnValue = @(ucharValue);
        } else if (strcmp(returnType, "i") == 0) { // int
            int intValue;
            [invocation getReturnValue:&intValue];
            returnValue = @(intValue);
        } else if (strcmp(returnType, "I") == 0) { // unsigned int
            unsigned int uintValue;
            [invocation getReturnValue:&uintValue];
            returnValue = @(uintValue);
        } else if (strcmp(returnType, "s") == 0) { // short
            short shortValue;
            [invocation getReturnValue:&shortValue];
            returnValue = @(shortValue);
        } else if (strcmp(returnType, "S") == 0) { // unsigned short
            unsigned short ushortValue;
            [invocation getReturnValue:&ushortValue];
            returnValue = @(ushortValue);
        } else if (strcmp(returnType, "l") == 0) { // long
            long longValue;
            [invocation getReturnValue:&longValue];
            returnValue = @(longValue);
        } else if (strcmp(returnType, "L") == 0) { // unsigned long
            unsigned long ulongValue;
            [invocation getReturnValue:&ulongValue];
            returnValue = @(ulongValue);
        } else if (strcmp(returnType, "q") == 0) { // long long
            long long longValue;
            [invocation getReturnValue:&longValue];
            returnValue = @(longValue);
        } else if (strcmp(returnType, "Q") == 0) { // unsigned long long
            unsigned long long ulonglongValue;
            [invocation getReturnValue:&ulonglongValue];
            returnValue = @(ulonglongValue);
        } else if (strcmp(returnType, "f") == 0) { // float
            float floatValue;
            [invocation getReturnValue:&floatValue];
            returnValue = @(floatValue);
        } else if (strcmp(returnType, "d") == 0) { // double
            double doubleValue;
            [invocation getReturnValue:&doubleValue];
            returnValue = @(doubleValue);
        } else if (strcmp(returnType, "B") == 0) { // BOOL
            BOOL boolValue;
            [invocation getReturnValue:&boolValue];
            returnValue = @(boolValue);
        } else if (strcmp(returnType, "*") == 0) { // C String
            char *cStringValue;
            [invocation getReturnValue:&cStringValue];
            returnValue = cStringValue ? [NSString stringWithUTF8String:cStringValue] : nil;
        } else {
            NSLogger(@"Unsupported return type: %s", returnType);
            return nil;
        }
    }
    NSLogger(@"Returning type: %s, value: %@", returnType,returnValue);
    return returnValue;
}


+ (uintptr_t)getCacheFileOffset:(NSString *)searchFilePath {
    NSNumber *cachedFileOffset = fileOffsetCache[searchFilePath];
    if (cachedFileOffset) {
        return [cachedFileOffset unsignedIntegerValue];
    } else {
        uintptr_t fileOffset = [MemoryUtils getCurrentArchFileOffset:searchFilePath];
        fileOffsetCache[searchFilePath] = @(fileOffset);
        return fileOffset;
    }
}

+ (void)hookWithMachineCode:(NSString *)searchFilePath
               machineCode:(NSString *)machineCode
                  fake_func:(void *)fake_func
                      count:(int)count {
    [self hookWithMachineCode:searchFilePath machineCode:machineCode fake_func:fake_func count:count out_orig:NULL];
}

+ (void)hookWithMachineCode:(NSString *)searchFilePath
               machineCode:(NSString *)machineCode
                  fake_func:(void *)fake_func
                      count:(int)count
                   out_orig:(void **)out_orig{
    
    NSString *fullFilePath = [[Constant getCurrentAppPath] stringByAppendingString:searchFilePath];
    uintptr_t fileOffset = [self getCacheFileOffset:fullFilePath];
    NSArray<NSNumber *> *codeOffsets = [self searchMachineCodeOffsets:fullFilePath
                                                          machineCode:machineCode
                                                                 count:count];
    
    NSString *imageName = [searchFilePath lastPathComponent];
    int imageIndex = [self indexForImageWithName:imageName];
    int processedCount = 0;
    for (NSNumber *globalFunOffset in codeOffsets) {
        if (processedCount >= count) {
            break;
        }
        intptr_t funAddress = [MemoryUtils getPtrFromGlobalOffset:imageIndex globalFunOffset:(uintptr_t)[globalFunOffset unsignedIntegerValue] fileOffset:(uintptr_t)fileOffset];
        tiny_hook((void *)funAddress, fake_func, out_orig);
        processedCount++;
    }
}
@end
