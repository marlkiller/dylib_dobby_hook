//
//  MacUpdaterHack.m
//  dylib_dobby_hook
//
//  Created by voidm on 2024/6/29.
//

#import <Foundation/Foundation.h>
#import "Constant.h"
#import "tinyhook.h"
#import "MemoryUtils.h"
#import "EncryptionUtils.h"
#import <objc/runtime.h>
#import "HackProtocolDefault.h"
#include <sys/ptrace.h>
#import "common_ret.h"

@interface MacUpdaterHack : HackProtocolDefault



@end


@implementation MacUpdaterHack

static IMP defaultStringIMP;
static IMP defaultIntIMP;
//static IMP URLSessionIMP2;
//static IMP dataTaskWithRequest;
static IMP URLWithHostIMP;
static IMP directoryContentsIMP;
//static IMP URLSessionIMP;
//static IMP fileChecksumSHAIMP;
static IMP checksumSparkleFrameworkIMP;
static IMP downloadURLWithSecurePOSTIMP;
//static Class stringClass;
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
        ret = [MemoryUtils invokeSelector:@"rot13" onTarget:[Constant G_EMAIL_ADDRESS_FMT]];
    } else if ([self isEqualTo:@"SavedV3PurchaseLicense"]) {
        ret = [MemoryUtils invokeSelector:@"rot13" onTarget:licenseCode];
    }else if ([self isEqualTo:@"SavedPurchaseLicense"]) {
        //        NSString* ret = [@"123456789" performSelector:NSSelectorFromString(@"rot13")];
        //        return ret;
    }else if ([self isEqualTo:@"NSNavLastRootBacktraceDiag"]) {
        //        NSLogger(@"");
        //        tmp = [ret dataFromBase64String];
        //       r15 = [[rax stringUTF8] retain];
        //       rax = [r15 rot13];
        //       r12 = [[rax removed:@"hdhkbcddfvlmwz"] retain];
        //        NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:ret options:1];
        //        NSString *stringUTF8 = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
        //        NSString *rax = [stringUTF8 performSelector:NSSelectorFromString(@"rot13")];
        //        rax = [rax stringByReplacingOccurrencesOfString:@"hdhkbcddfvlmwz" withString:@""];
    }
    NSLogger(@"hk_defaultString %@:%@",self,ret);
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
    NSLogger(@"hk_defaultInt %@:%d",self,ret);
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
            int param1 = 0xc9;
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
    
    NSLogger(@"hook_URLWithHost %@,%@,%@,%@,%@,%@",arg2,arg3,arg4,arg5,arg6,arg7);
    
    id ret = ((id(*)(id,SEL,id,id,id,id,id,id,id,id))URLWithHostIMP)(self,_cmd,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9);
    return ret;
}


+ (NSString *) hk_checksumSparkleFramework{
    NSLogger(@"hk_checksumSparkleFramework");

    // x86: 46e6b06e5626534a9c61b91cfb041ccf051a2db8
    // arm: a5f76baec8ce44138ceadc97130d622642fe4d2e
    static NSString *cachedChecksum = nil;
    if (!cachedChecksum){
        NSString *Sparkle = [[Constant getCurrentAppPath] stringByAppendingString:@"/Contents/Frameworks/Sparkle.framework/Versions/B/Sparkle_Backup"];
        cachedChecksum = [[EncryptionUtils calculateSHA1OfFile:Sparkle] copy];
        NSLogger(@"hk_checksumSparkleFramework cachedChecksum = %@", cachedChecksum);
    }
    return  cachedChecksum;
}

+ (NSString *) hk_uniqueIdentifierForDB{
    NSLogger(@"hk_uniqueIdentifierForDB");
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


- (id)hook_downloadURLWithSecurePOST:(NSURL *)url timeout:(NSTimeInterval)timeout{
    
    // https://macupdater-backend.com/configfile.cgi?b=16971&c=d8cef3817314647190c70f16357d0204f80c7dd6&s=5cac513cff8b040faff3d4a6b40d13bbfa034334&p=bd4867852d87df9b6353c6cad95adb5cbdde0a81&u=4bxexx40docih65dv6azovmier5m2xc7fqsgjjzn&a=0&e=(null)&l=(null)&x=5
    
    NSString* path = [url path];
    if ([path isEqualToString:@"/configfile.cgi"]) {
        NSString *cacheDir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
        // /Users/voidm/Library/Caches/com.corecode.MacUpdater/cache_configfile.cgi
        NSString * cacheConfigFile = [cacheDir stringByAppendingPathComponent:@"com.corecode.MacUpdater/cache_configfile.cgi"];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL fileExists = [fileManager fileExistsAtPath:cacheConfigFile];
        
        if (fileExists) {
            // 文件存在，检查文件的修改日期
            NSDictionary *attributes = [fileManager attributesOfItemAtPath:cacheConfigFile error:nil];
            NSDate *modificationDate = [attributes fileModificationDate];
            if (modificationDate) {
                NSDate *currentDate = [NSDate date];
                // 缓存 config 30天
                NSData* fakaData = [NSData dataWithContentsOfFile:cacheConfigFile];
                NSTimeInterval timeInterval = [currentDate timeIntervalSinceDate:modificationDate];
                NSTimeInterval oneMonthInterval = 30 * 24 * 60 * 60;
                if (timeInterval < oneMonthInterval) {
                    // 这句 setInstanceIvar 不知道需不需要...
                    // [MemoryUtils setInstanceIvar:self ivarName:"dataToDownload" value:fakaData];
                    return fakaData;
                }
            }
        }
        NSData* ret = ((NSData*(*)(id,SEL,NSURL*,NSTimeInterval))downloadURLWithSecurePOSTIMP)(self,_cmd,url,timeout);
        if (ret.length > 409600) {
            BOOL success = [ret writeToFile:cacheConfigFile options:NSDataWritingAtomic error:nil];
            NSLogger(@"[cache_configfile.cgi] saved %hhd",success);
        } else {
            // NSData 长度小于或等于 400KB
            NSLogger(@"[configfile.cgi] api returns data exception, possibly banned IP !!");
        }
        return ret;
    }
    
    
    id ret = ((id(*)(id,SEL,NSURL*,NSTimeInterval))downloadURLWithSecurePOSTIMP)(self,_cmd,url,timeout);
    
    return ret;
}

-(void)hk_ensureCachedMinimumOS:arg1 versionToken:arg2{
    NSLogger(@"arg1 = %@,arg2 = %@",arg1,arg2);
}
- (BOOL)hack {
    
    // [AppInfo ensureCachedMinimumOS:versionToken:]
//    [MemoryUtils hookInstanceMethod:NSClassFromString(@"AppInfo")
//                   originalSelector:NSSelectorFromString(@"ensureCachedMinimumOS:versionToken:")
//                   swizzledClass:[self class]
//                   swizzledSelector:@selector(hk_ensureCachedMinimumOS:versionToken:)
//    ];
//  -[AppDelegate purchaseInit]:
    defaultStringIMP = [MemoryUtils hookInstanceMethod:NSClassFromString(@"__NSCFString")
                   originalSelector:NSSelectorFromString(@"defaultString")
                   swizzledClass:[self class]
                swizzledSelector:@selector(hk_defaultString)
    ];

            
    defaultIntIMP = [MemoryUtils hookInstanceMethod:NSClassFromString(@"__NSCFString")
                   originalSelector:NSSelectorFromString(@"defaultInt")
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
    directoryContentsIMP = [MemoryUtils hookInstanceMethod:NSClassFromString(@"NSString")
                   originalSelector:NSSelectorFromString(@"directoryContents")
                      swizzledClass:[self class]
                   swizzledSelector:@selector(hk_directoryContents)
    ];


        
    checksumSparkleFrameworkIMP = [MemoryUtils hookClassMethod:NSClassFromString(@"AppDelegate")
                   originalSelector:NSSelectorFromString(@"checksumSparkleFramework")
                      swizzledClass:[self class]
                   swizzledSelector:@selector(hk_checksumSparkleFramework)
    ];

//  清除 API 中的 license 信息    
    URLWithHostIMP = [MemoryUtils hookClassMethod:
         NSClassFromString(@"NSURL")
                   originalSelector:NSSelectorFromString(@"URLWithHost:path:query:user:password:fragment:scheme:port:")
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
    
    
//    config.cgi 缓存策略
//    -[HTTPSecurePOST downloadURLWithSecurePOST:timeout:]:
    downloadURLWithSecurePOSTIMP = [MemoryUtils hookInstanceMethod:NSClassFromString(@"HTTPSecurePOST")
                   originalSelector:NSSelectorFromString(@"downloadURLWithSecurePOST:timeout:")
                      swizzledClass:[self class]
                   swizzledSelector:NSSelectorFromString(@"hook_downloadURLWithSecurePOST:timeout:")
    ];
    
    return YES;
}

@end
