//
//  MacUpdaterHack.m
//  dylib_dobby_hook
//
//  Created by voidm on 2024/6/29.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "dobby.h"
#import "MemoryUtils.h"
#import "encryp_utils.h"
#import <objc/runtime.h>
#import "HackProtocolDefault.h"
#include <sys/ptrace.h>
#import "common_ret.h"

@interface MacUpdaterHack : HackProtocolDefault



@end


@implementation MacUpdaterHack

static IMP defaultStringIMP;
static IMP defaultIntIMP;
static IMP dataTaskWithRequestIMP;
static IMP URLWithHostIMP;
static IMP directoryContentsIMP;
static IMP URLSessionIMP;
static IMP fileChecksumSHAIMP;
static IMP checksumSparkleFrameworkIMP;
static Class stringClass;
static NSString* licenseCode = @"123456789";

- (NSString *)getAppName {
    // >>>>>> AppName is [com.corecode.MacUpdater],Version is [3.3.1], myAppCFBundleVersion is [16954].
    return @"com.corecode.MacUpdater";
}

- (NSString *)getSupportAppVersion {
    return @"3.3";
}



-(NSString *) hk_defaultString{
    id ret = ((NSString *(*)(id,SEL))defaultStringIMP)(self,_cmd);
    
    if ([self isEqualTo:@"SavedV3PurchaseEmail"]) {
        ret = [[Constant G_EMAIL_ADDRESS_FMT] performSelector:NSSelectorFromString(@"rot13")];
    } else if ([self isEqualTo:@"SavedV3PurchaseLicense"]) {
        ret = [licenseCode performSelector:NSSelectorFromString(@"rot13")];
    }else if ([self isEqualTo:@"SavedPurchaseLicense"]) {
        //        NSString* ret = [@"123456789" performSelector:NSSelectorFromString(@"rot13")];
        //        return ret;
    }else if ([self isEqualTo:@"NSNavLastRootBacktraceDiag"]) {
        //        NSLog(@"");
        //        tmp = [ret dataFromBase64String];
        //       r15 = [[rax stringUTF8] retain];
        //       rax = [r15 rot13];
        //       r12 = [[rax removed:@"hdhkbcddfvlmwz"] retain];
        //        NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:ret options:1];
        //        NSString *stringUTF8 = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
        //        NSString *rax = [stringUTF8 performSelector:NSSelectorFromString(@"rot13")];
        //        rax = [rax stringByReplacingOccurrencesOfString:@"hdhkbcddfvlmwz" withString:@""];
    }
    NSLog(@">>>>>> hk_defaultString %@:%@",self,ret);
    return ret;
    
}


-(int) hk_defaultInt{
    int ret = ((int(*)(id,SEL))defaultIntIMP)(self,_cmd);
    if ([self isEqualTo:@"SavedV3PurchaseActivation"]) {
        ret = 2;
            // if ([LicenseHelper licenseIsPro:rax] != 0x0) {
            //         r15 = r14;
            //         [r14 setPurchaseActivated:0x2];
            //         [r14 setBusinessLicensed:sign_extend_64([LicenseHelper licenseIsBusiness:r13])];
            //         if ([@"SavedV3PurchaseActivation" defaultInt] != 0x2 && [@"ScannedSoftware" defaultInt] == 0x1) {
            //                 [@"ScannedSoftware" setDefaultInt:0x2];
            //                 [r15->_mu forceDirtyRescan];
            //         }
            // }
            // else {
            //         r15 = r14;
            //         [r14 setPurchaseActivated:0x1];
            // }
    }else if ([self isEqualTo:@"Usages3"]) {
        ret = 5;
    }
    //     [@"UpdatecheckMenuindex" setDefaultInt:0x2];
    NSLog(@">>>>>> hk_defaultInt %@:%d",self,ret);
    return ret;
    
}

-(void) hk_refreshAuthentication{
    //    [r14 setStatus:0xc9 email:r15 license:rax];
    //    -[Meddle setStatus:email:license:]:
    //0000000100076bf7         push       rbp
    //        [r14 setStatus:0xc9 email:r15 license:rax];
    
    SEL selector = NSSelectorFromString(@"setStatus:email:license:");
    if ([self respondsToSelector:selector]) {
        NSMethodSignature *methodSignature = [self methodSignatureForSelector:selector];
        if (methodSignature) {
            
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
            //            id (*sharedInstanceMethod)(id, SEL) = (id (*)(id, SEL))objc_msgSend;
            //            id sharedInstance = sharedInstanceMethod(AppDelegateClz, selector);
            [invocation setTarget:self];
            [invocation setSelector:selector];
            NSInteger *param1 = 0xc9;
            NSString *param2 = [Constant G_EMAIL_ADDRESS_FMT];
            NSString *param3 = licenseCode;
            [invocation setArgument:&param1 atIndex:2];
            [invocation setArgument:&param2 atIndex:3];
            [invocation setArgument:&param3 atIndex:4];
            [invocation invoke];
        }
    }
}

- (NSMutableArray *) hk_directoryContents{
    
    NSString* dylib_name = [Constant G_DYLIB_NAME];
    NSMutableArray* ret = ((NSMutableArray*(*)(id,SEL))directoryContentsIMP)(self,_cmd);
    if ([ret containsObject:dylib_name]) {
        [ret removeObject:dylib_name];
    }
    return ret;
}


+(id)hook_URLWithHost:(id)arg2 path:(id)arg3 query:(id)arg4 user:(id)arg5 password:(id)arg6 fragment:(id)arg7 scheme:(id)arg8 port:(id)arg9 {
    // b=16954&c=55e5d3917c18e1629796800b4b28959099d9dba6&s=9cbc3058b207677f9d0516d6ddee975152e0055d&p=603d96f1ca6d566da7277af5995addc7f57dbd9d&u=7ab4cc74f4e68a027e1cfa6eae311853d1b31cd1&a=2&e=marlkiller@voidm.com&l=123456789&x=0
    // https://macupdater-backend.com/configfile.cgi
//  b=16954&c=55e5d3917c18e1629796800b4b28959099d9dba6&s=9cbc3058b207677f9d0516d6ddee975152e0055d&p=603d96f1ca6d566da7277af5995addc7f57dbd9d&u=7ab4cc74f4e68a027e1cfa6eae311853d1b31cd1&a=0&e=(null)&l=(null)&x=0
    
    //        b : var_2C = [*_cc appBuildNumber];
    //        c : var_40 = [[AppDelegate checksumAppBinary] retain]; // 55e5d3917c18e1629796800b4b28959099d9dba6
    //        s : var_38 = [[AppDelegate checksumSparkleFramework] retain]; // a5f76baec8ce44138ceadc97130d622642fe4d2e
    //        p : rax = [AppDelegate checksumCodeResources];
    //        u : ax = [AppDelegate uniqueIdentifierForDB];
    //        a : var_58 = [rbx purchaseActivated] & 0xff;
    //        e : r15 = [[rbx purchaseEmail] retain];
    //        l : rbx = [[rbx purchaseLicense] retain];
    //        x : "Usages3" defaultInt];
    
    
    if ([arg2 isEqualToString:@"macupdater-backend.com"]) {
        if(([arg3 containsString:@".cgi"] && arg4!=nil )){
            arg4 = [arg4 stringByReplacingOccurrencesOfString:@"a=2" withString:@"a=0"];
        }
        if(arg4!=nil){
            arg4 = [arg4 stringByReplacingOccurrencesOfString:[@"=" stringByAppendingString:[Constant G_EMAIL_ADDRESS_FMT]] withString:@"=(null)"];
            arg4 = [arg4 stringByReplacingOccurrencesOfString:[@"=" stringByAppendingString:licenseCode] withString:@"=(null)"];
        }
    }
    
   
    
    
    
    NSLog(@">>>>>> hook_URLWithHost %@,%@,%@,%@,%@,%@",arg2,arg3,arg4,arg5,arg6,arg7);
    
    id ret = ((id(*)(id,SEL,id,id,id,id,id,id,id,id))URLWithHostIMP)(self,_cmd,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9);
    return ret;
}


+ (NSString *) hk_checksumSparkleFramework{
    NSLog(@">>>>>> hk_checksumSparkleFramework %@", self);

    // x86: 46e6b06e5626534a9c61b91cfb041ccf051a2db8
    // arm: a5f76baec8ce44138ceadc97130d622642fe4d2e
    // id ret = ((id (*)(id,SEL))checksumSparkleFrameworkIMP)(self,_cmd);

    NSString *Sparkle = [[Constant getCurrentAppPath] stringByAppendingString:@"/Contents/Frameworks/Sparkle.framework/Versions/B/Sparkle_Backup"];
    NSString *retFake = [EncryptionUtils calculateSHA1OfFile:Sparkle];
    return  retFake;

    // return  @"5cac513cff8b040faff3d4a6b40d13bbfa034334";
}

+ (NSString *) hk_uniqueIdentifierForDB{
    NSLog(@">>>>>> hk_uniqueIdentifierForDB");
    NSString *letters = @"abcdefghijklmnopqrstuvwxyz0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity:40];
    for (int i = 0; i < 40; i++) {
        uint32_t randomIndex = arc4random_uniform((uint32_t)[letters length]);
        [randomString appendFormat:@"%C", [letters characterAtIndex:randomIndex]];
    }
    return  randomString;
}


-(void)hk_URLSession:(NSURLSession *)arg2 didReceiveChallenge:(NSURLAuthenticationChallenge*)arg3 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))arg4 {
    
    if(arg4){
//        arg4(nil,nil);
        arg4(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:arg3.protectionSpace.serverTrust]);
    }
}

- (BOOL)hack {
//  [BEGIN]
//  下面这块代码是为了防止 clion 编译的 str 与 app 中的 str 不属于同一个 clz...
//  xcode 编译则不需要这么抽象的写法, 不知道为什么
//     stringClass = NSClassFromString(@"NSString");
//     licenseEmail = [[stringClass alloc] initWithString:[Constant G_EMAIL_ADDRESS_FMT]];
//     licenseCode = [[stringClass alloc] initWithString:@"123456789"];
//     appPath = [[stringClass alloc] initWithString:[Constant getCurrentAppPath]];
//  [END]

////    -[AppDelegate purchaseInit]:
    Class __NSCFStringClz = NSClassFromString(@"__NSCFString");
    SEL defaultStringSel = NSSelectorFromString(@"defaultString");
    Method defaultStringMethod = class_getInstanceMethod(__NSCFStringClz, defaultStringSel);
    defaultStringIMP = method_getImplementation(defaultStringMethod);
    [MemoryUtils hookInstanceMethod:__NSCFStringClz
                   originalSelector:defaultStringSel
                   swizzledClass:[self class]
                swizzledSelector:@selector(hk_defaultString)
    ];

    
    SEL defaultIntSel = NSSelectorFromString(@"defaultInt");
    Method defaultIntMethod = class_getInstanceMethod(__NSCFStringClz, defaultIntSel);
    defaultIntIMP = method_getImplementation(defaultIntMethod);
    [MemoryUtils hookInstanceMethod:__NSCFStringClz
                   originalSelector:defaultIntSel
                   swizzledClass:[self class]
                swizzledSelector:@selector(hk_defaultInt)
    ];
    

    
//  -[Meddle refreshAuthentication]:
//    0000000100075b72         push       rbp
    [MemoryUtils hookInstanceMethod:NSClassFromString(@"Meddle")
                   originalSelector:NSSelectorFromString(@"refreshAuthentication")
                   swizzledClass:[self class]
                swizzledSelector:@selector(hk_refreshAuthentication)
    ];
    
    
//    LicenseHelper licenseIsPro
    [MemoryUtils replaceClassMethod:NSClassFromString(@"LicenseHelper")
                   originalSelector:NSSelectorFromString(@"licenseIsPro:")
                   swizzledClass:[self class]
                swizzledSelector:@selector(ret1)
    ];
    
//    +[Meddle _isValidEmailAddress:]
    [MemoryUtils replaceClassMethod:objc_getClass("Meddle")
                originalSelector:NSSelectorFromString(@"_isValidEmailAddress:")
                   swizzledClass:[self class]
                swizzledSelector:@selector(ret1)
    ];
    
    //  nop 掉定时教研
    [MemoryUtils replaceClassMethod:objc_getClass("CGIInfoHelper")
                originalSelector:NSSelectorFromString(@"checkExpiry:eventType:")
                   swizzledClass:[self class]
                swizzledSelector:@selector(ret)
    ];
    
    
    
//  过滤 Framework 下的 dylib
//  -[NSString directoryContents]:
    Class NSStringClz = NSClassFromString(@"NSString");
    SEL directoryContentsSel = NSSelectorFromString(@"directoryContents");
    Method directoryContentsMethod = class_getInstanceMethod(NSStringClz, directoryContentsSel);
    directoryContentsIMP = method_getImplementation(directoryContentsMethod);
    [MemoryUtils hookInstanceMethod:NSStringClz
                   originalSelector:directoryContentsSel
                      swizzledClass:[self class]
                   swizzledSelector:@selector(hk_directoryContents)
    ];


    

    Class AppDelegateClz = NSClassFromString(@"AppDelegate");
    SEL checksumSparkleFrameworkSel = NSSelectorFromString(@"checksumSparkleFramework");
    Method checksumSparkleFrameworkMethod = class_getClassMethod(AppDelegateClz, checksumSparkleFrameworkSel);
    checksumSparkleFrameworkIMP = method_getImplementation(checksumSparkleFrameworkMethod);
    [MemoryUtils hookClassMethod:AppDelegateClz
                   originalSelector:checksumSparkleFrameworkSel
                      swizzledClass:[self class]
                   swizzledSelector:@selector(hk_checksumSparkleFramework)
    ];

//  清除 API 中的 license 信息
    Class NSURLClz = NSClassFromString(@"NSURL");
    SEL URLWithHostSel = NSSelectorFromString(@"URLWithHost:path:query:user:password:fragment:scheme:port:");
    Method URLWithHostMethod = class_getClassMethod(NSURLClz, URLWithHostSel);
    URLWithHostIMP = method_getImplementation(URLWithHostMethod);
    [MemoryUtils hookClassMethod:
                    NSURLClz
                   originalSelector:URLWithHostSel
                      swizzledClass:[self class]
                   swizzledSelector:NSSelectorFromString(@"hook_URLWithHost:path:query:user:password:fragment:scheme:port:")
    ];
    
//    +[AppDelegate uniqueIdentifierForDB]:
    [MemoryUtils hookClassMethod:
         NSClassFromString(@"AppDelegate")
                   originalSelector:NSSelectorFromString(@"uniqueIdentifierForDB")
                      swizzledClass:[self class]
                   swizzledSelector:NSSelectorFromString(@"hk_uniqueIdentifierForDB")
    ];
    
//  清除 SSL 证书绑定
    [MemoryUtils hookInstanceMethod:
         NSClassFromString(@"HTTPSecurePOST")
                   originalSelector:NSSelectorFromString(@"URLSession:didReceiveChallenge:completionHandler:")
                      swizzledClass:[self class]
                   swizzledSelector:NSSelectorFromString(@"hk_URLSession:didReceiveChallenge:completionHandler:")
    ];
    
    return YES;
}

@end
