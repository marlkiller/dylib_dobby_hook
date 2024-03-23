//
//  AnyGoHack.m
//  dylib_dobby_hook
//
//  Created by 马治武 on 2024/3/17.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "dobby.h"
#import "MemoryUtils.h"
#import <objc/runtime.h>
#include <mach-o/dyld.h>
#import "HackProtocol.h"

@interface AnyGoHack : NSObject <HackProtocol>

@end


@implementation AnyGoHack

- (NSString *)getAppName {
    return @"com.itoolab.AnyGo";
}

- (NSString *)getSupportAppVersion {
    // 7.0.0
    return @"7.";
}

+ (int)hk_isInChina {
    NSLog(@">>>>>> Swizzled hk_isInChina method called");
    NSLog(@">>>>>> self.className : %@", self.className);
    return 0;
}
- (BOOL)hk_isRegistered {
    NSLog(@">>>>>> Swizzled hk_isRegistered method called");
    return YES;
}


- (BOOL)hk_isOverDevicesLimit {
    NSLog(@">>>>>> Swizzled hk_isOverDevicesLimit method called");
    return NO;
}


- (id)hk_device {
    NSLog(@">>>>>> Swizzled hk_device method called");
    NSString *className = @"IOSDevice";
    Class class = objc_getClass([className UTF8String]);
    return [[class alloc] init];
}

- (void)hk_checkRegisterValid:(uint64_t)arg1 {
    NSLog(@">>>>>> Swizzled hk_checkRegisterValid method called");
    NSLog(@">>>>>> self.className : %@", self.className);
    return ;
}

- (NSString *) hk_emailText {
    NSLog(@">>>>>> Swizzled hk_emailText method called");
    return @"marlkiller@voidm.com" ;
}

- (NSString *) hk_codeText {
    NSLog(@">>>>>> Swizzled hk_codeText method called");
    NSUUID *uuid = [NSUUID UUID];
    NSString *uuidString = [uuid UUIDString];
    return uuidString;
}

// void __cdecl -[RegisterWindow updateUIIsRegister:](RegisterWindow *self, SEL a2, char a3)
//- (int)hk_updateUIIsRegister:(int)arg1 withA3:(int)a3 {
//    NSLog(@">>>>>> Swizzled hk_updateUIIsRegister method called");
//    NSLog(@">>>>>> self.className : %@", self.className);
//    return [self hk_updateUIIsRegister:arg1 withA3:a3];
//}

- (BOOL)hack {
#if defined(__arm64__) || defined(__aarch64__)
#elif defined(__x86_64__)
#endif
    
    // if ([GlobalFunction isForTest] == 0x0 && [GlobalFunction isInChina] != 0x0) {
    [MemoryUtils hookClassMethod:
                objc_getClass("GlobalFunction")
                originalSelector:NSSelectorFromString(@"isInChina")
                swizzledClass:[self class]
                swizzledSelector:@selector(hk_isInChina)
    ];
//    rax = [RegisterManager shareManager];
//    r14 = [rax isRegistered];
//    [rax release];
//    rax = [r13 objectForKey:@"pathType"];
//    rax = [rax retain];
//    var_40 = [rax intValue];
//    [rax release];
//    var_48 = r13;
//    if (r14 != 0x0) {
    [MemoryUtils hookInstanceMethod:
                objc_getClass("RegisterManager")
                originalSelector:NSSelectorFromString(@"isRegistered")
                swizzledClass:[self class]
                swizzledSelector:@selector(hk_isRegistered)
    ];
    
    
//    r12 = [[RegisterManager shareManager] retain];
//    var_29 = [r12 isOverDevicesLimit:rax];
//    if (var_29 == 0x0) goto loc_10003a8f1;
    
    [MemoryUtils hookInstanceMethod:
                objc_getClass("RegisterManager")
                originalSelector:NSSelectorFromString(@"isOverDevicesLimit:")
                swizzledClass:[self class]
                swizzledSelector:@selector(hk_isOverDevicesLimit)
    ];
    
    
//    -[RegisterWindow updateUIIsRegister:]:
//0000000100059bb9         push       rbp
//    [MemoryUtils hookInstanceMethod:
//                objc_getClass("RegisterWindow")
//                originalSelector:NSSelectorFromString(@"updateUIIsRegister:")
//                swizzledClass:[self class]
//                swizzledSelector:@selector(hk_updateUIIsRegister:withA3:)
//    ];
    [MemoryUtils hookInstanceMethod:
                objc_getClass("RegisterManager")
                originalSelector:NSSelectorFromString(@"email")
                swizzledClass:[self class]
                swizzledSelector:@selector(hk_emailText)
    ];
    [MemoryUtils hookInstanceMethod:
                objc_getClass("RegisterManager")
                originalSelector:NSSelectorFromString(@"regCode")
                swizzledClass:[self class]
                swizzledSelector:@selector(hk_codeText)
    ];
    
//    [MemoryUtils hookInstanceMethod:
//                objc_getClass("RegisterWindow")
//                originalSelector:NSSelectorFromString(@"checkRegisterValid:result:")
//                swizzledClass:[self class]
//                swizzledSelector:@selector(hk_checkRegisterValid:)
//    ];
//    [MemoryUtils hookInstanceMethod:
//                objc_getClass("MainWindowCtr")
//                originalSelector:NSSelectorFromString(@"checkRegisterValid:result:")
//                swizzledClass:[self class]
//                swizzledSelector:@selector(hk_checkRegisterValid:)
//    ];
    
    
//    objc 反射用法 TEST
//    // 调用 RegisterManager 类的 shareManager 方法
//    Class registerManagerClass = NSClassFromString(@"RegisterManager");
//    SEL shareManagerSelector = NSSelectorFromString(@"shareManager");
//    id registerManager = [registerManagerClass performSelector:shareManagerSelector];
//    NSLog(@">>>>>> RegisterManager object: %@", registerManager);
//    
//    // 获取对象的属性与值
//    unsigned int count;
//    objc_property_t *properties = class_copyPropertyList(registerManagerClass, &count);
//
//    for (unsigned int i = 0; i < count; i++) {
//        objc_property_t property = properties[i];
//        NSString *propertyName = [NSString stringWithUTF8String:property_getName(property)];
//        if ([propertyName isEqualToString:@"isRegister"]) {
//            // 找到对应的属性，设置其值
//            [registerManager setValue:@(1) forKey:propertyName];
//            // break;
//        }
//        id propertyValue = [registerManager valueForKey:propertyName];
//        NSLog(@">>>>>> Property: %@, Value: %@", propertyName, propertyValue);
//    }
//    
//    // 获取对象的方法与返回值类型
//    Method *methods = class_copyMethodList(registerManagerClass, &count);
//    for (unsigned int i = 0; i < count; i++) {
//        Method method = methods[i];
//        const char *methodName = sel_getName(method_getName(method));
//        // method_getReturnType(method, &dst, sizeof(char));// 获取方法返回类型
//        const char *returnType = method_getTypeEncoding(method);// 获取方法参数类型和返回类型
//        NSLog(@">>>>>> Method Name: %s, Return Type: %s", methodName, returnType);
//    }
    
    return YES;
}
@end
